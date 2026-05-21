//! `template-forge-mcp` — stdio JSON-RPC 2.0 MCP server.
//!
//! v0.1.0 implements a minimal MCP-style request/response loop sufficient
//! for `tools/list` and `tools/call` against two tools:
//!
//! - `template_forge_list_engines` — returns the list of compiled-in engines
//! - `template_forge_render`       — renders a template for a brand
//!
//! A `--probe <tool> [args]` mode exercises the same code path without
//! going through stdio, for testing without an MCP client.

use std::io::{self, BufRead, Write};
use std::path::PathBuf;

use anyhow::{anyhow, Context, Result};
use clap::Parser;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use template_core::{build_engine, list_brands, load_brand, EngineSelection};

#[cfg(not(target_env = "msvc"))]
#[global_allocator]
static GLOBAL: tikv_jemallocator::Jemalloc = tikv_jemallocator::Jemalloc;

#[derive(Parser, Debug)]
#[command(
    name = "template-forge-mcp",
    version,
    about = "Stdio JSON-RPC 2.0 MCP server for template-forge"
)]
struct Cli {
    /// Default library directory passed when callers don't supply one.
    #[arg(long, env = "TEMPLATE_FORGE_LIBRARY")]
    library: Option<PathBuf>,

    /// Default templates base directory.
    #[arg(long, env = "TEMPLATE_FORGE_TEMPLATES")]
    templates_base: Option<PathBuf>,

    /// Probe mode: exercise a tool directly and print the JSON result.
    ///
    /// Examples:
    ///   template-forge-mcp --probe list-engines
    ///   template-forge-mcp --probe list-brands --library ./assets/library
    #[arg(long)]
    probe: Option<String>,
}

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("warn")),
        )
        .with_writer(io::stderr)
        .init();

    let cli = Cli::parse();
    let defaults = ServerDefaults {
        library: cli.library.clone(),
        templates_base: cli.templates_base.clone(),
    };

    if let Some(probe_tool) = cli.probe.as_deref() {
        let result = dispatch(probe_tool, json!({}), &defaults)?;
        println!("{}", serde_json::to_string_pretty(&result)?);
        return Ok(());
    }

    serve_stdio(defaults)
}

#[derive(Debug, Clone)]
struct ServerDefaults {
    library: Option<PathBuf>,
    templates_base: Option<PathBuf>,
}

#[derive(Debug, Deserialize)]
struct JsonRpcRequest {
    jsonrpc: String,
    id: Option<Value>,
    method: String,
    #[serde(default)]
    params: Value,
}

#[derive(Debug, Serialize)]
struct JsonRpcResponse {
    jsonrpc: &'static str,
    id: Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    result: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<JsonRpcError>,
}

#[derive(Debug, Serialize)]
struct JsonRpcError {
    code: i64,
    message: String,
}

fn serve_stdio(defaults: ServerDefaults) -> Result<()> {
    let stdin = io::stdin();
    let stdout = io::stdout();
    let mut out = stdout.lock();
    let reader = stdin.lock();

    for line in reader.lines() {
        let line = line.context("reading stdin line")?;
        if line.trim().is_empty() {
            continue;
        }

        let req: JsonRpcRequest = match serde_json::from_str(&line) {
            Ok(r) => r,
            Err(e) => {
                let resp = JsonRpcResponse {
                    jsonrpc: "2.0",
                    id: Value::Null,
                    result: None,
                    error: Some(JsonRpcError {
                        code: -32700,
                        message: format!("parse error: {e}"),
                    }),
                };
                writeln!(out, "{}", serde_json::to_string(&resp)?)?;
                out.flush()?;
                continue;
            }
        };

        if req.jsonrpc != "2.0" {
            send_error(&mut out, req.id, -32600, "jsonrpc must be \"2.0\"")?;
            continue;
        }

        let resp = match req.method.as_str() {
            "tools/list" => JsonRpcResponse {
                jsonrpc: "2.0",
                id: req.id.unwrap_or(Value::Null),
                result: Some(tools_list_payload()),
                error: None,
            },
            "tools/call" => match call_tool(&req.params, &defaults) {
                Ok(v) => JsonRpcResponse {
                    jsonrpc: "2.0",
                    id: req.id.unwrap_or(Value::Null),
                    result: Some(v),
                    error: None,
                },
                Err(e) => JsonRpcResponse {
                    jsonrpc: "2.0",
                    id: req.id.unwrap_or(Value::Null),
                    result: None,
                    error: Some(JsonRpcError {
                        code: -32000,
                        message: e.to_string(),
                    }),
                },
            },
            other => JsonRpcResponse {
                jsonrpc: "2.0",
                id: req.id.unwrap_or(Value::Null),
                result: None,
                error: Some(JsonRpcError {
                    code: -32601,
                    message: format!("unknown method '{other}'"),
                }),
            },
        };
        writeln!(out, "{}", serde_json::to_string(&resp)?)?;
        out.flush()?;
    }
    Ok(())
}

fn send_error<W: Write>(out: &mut W, id: Option<Value>, code: i64, message: &str) -> Result<()> {
    let resp = JsonRpcResponse {
        jsonrpc: "2.0",
        id: id.unwrap_or(Value::Null),
        result: None,
        error: Some(JsonRpcError {
            code,
            message: message.to_string(),
        }),
    };
    writeln!(out, "{}", serde_json::to_string(&resp)?)?;
    out.flush()?;
    Ok(())
}

fn tools_list_payload() -> Value {
    json!({
        "tools": [
            {
                "name": "template_forge_list_engines",
                "description": "List template engines compiled into this build.",
                "inputSchema": { "type": "object", "properties": {}, "additionalProperties": false }
            },
            {
                "name": "template_forge_list_brands",
                "description": "List brands available in <library>/brands/.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "library": { "type": "string", "description": "Library root path" }
                    }
                }
            },
            {
                "name": "template_forge_render",
                "description": "Render a template for a brand.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "brand": { "type": "string" },
                        "template": { "type": "string" },
                        "engine": { "type": "string", "default": "minijinja" },
                        "library": { "type": "string" },
                        "templates_base": { "type": "string" }
                    },
                    "required": ["brand", "template"]
                }
            }
        ]
    })
}

fn call_tool(params: &Value, defaults: &ServerDefaults) -> Result<Value> {
    let name = params
        .get("name")
        .and_then(|v| v.as_str())
        .ok_or_else(|| anyhow!("tools/call missing 'name'"))?;
    let args = params.get("arguments").cloned().unwrap_or_else(|| json!({}));
    dispatch(name, args, defaults)
}

fn dispatch(tool: &str, args: Value, defaults: &ServerDefaults) -> Result<Value> {
    match tool {
        "template_forge_list_engines" | "list-engines" => Ok(json!({
            "engines": EngineSelection::all().iter().map(|e| e.id()).collect::<Vec<_>>()
        })),
        "template_forge_list_brands" | "list-brands" => {
            let library = arg_path(&args, "library", defaults.library.as_ref())?;
            let brands = list_brands(&library)?;
            Ok(json!({ "brands": brands }))
        }
        "template_forge_render" | "render" => {
            let brand = arg_str(&args, "brand")?;
            let template = arg_str(&args, "template")?;
            let engine_id = args
                .get("engine")
                .and_then(|v| v.as_str())
                .unwrap_or("minijinja");
            let sel = EngineSelection::from_str_ci(engine_id)
                .ok_or_else(|| anyhow!("unknown engine '{engine_id}'"))?;
            let library = arg_path(&args, "library", defaults.library.as_ref())?;
            let templates_base =
                arg_path(&args, "templates_base", defaults.templates_base.as_ref())?;
            let brand_data = load_brand(&library, &brand)?;
            let engine = build_engine(sel, &templates_base)?;
            let rendered = engine.render(&template, &brand_data)?;
            Ok(json!({ "rendered": rendered }))
        }
        other => Err(anyhow!("unknown tool '{other}'")),
    }
}

fn arg_str(args: &Value, key: &str) -> Result<String> {
    args.get(key)
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .ok_or_else(|| anyhow!("missing required arg '{key}'"))
}

fn arg_path(args: &Value, key: &str, fallback: Option<&PathBuf>) -> Result<PathBuf> {
    if let Some(s) = args.get(key).and_then(|v| v.as_str()) {
        return Ok(PathBuf::from(s));
    }
    fallback
        .cloned()
        .ok_or_else(|| anyhow!("missing required arg '{key}' (and no default)"))
}
