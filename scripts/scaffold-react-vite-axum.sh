#!/usr/bin/env bash
#
# scaffold-react-vite-axum.sh
#
# Generate a Rust + Axum binary that:
#   1. At build time:    runs Vite to produce <target>/dist/
#   2. At compile time:  embeds <target>/dist/ via rust-embed
#   3. At runtime:       serves the SPA on configurable port with /index.html fallback
#
# Produces:
#   <target>/server/Cargo.toml
#   <target>/server/build.rs
#   <target>/server/src/main.rs
#   <target>/server/README.md
#
# Usage:
#   bash scripts/scaffold-react-vite-axum.sh --target <path-to-react-project>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '\033[1;36m[axum-wrapper]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[axum-wrapper]\033[0m %s\n' "$*" >&2; }
ok()   { printf '\033[1;32m[axum-wrapper]\033[0m %s\n' "$*"; }

TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2;;
    --help|-h)
      sed -n '5,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0;;
    *) err "unknown argument: $1"; exit 2;;
  esac
done

if [[ -z "${TARGET}" ]]; then err "missing --target"; exit 2; fi
if [[ ! -f "${TARGET}/package.json" ]]; then
  err "expected React project at ${TARGET}; missing package.json"
  exit 1
fi
if ! command -v cargo >/dev/null 2>&1; then
  err "cargo not on PATH"
  exit 1
fi

# Crate name = kebab-case of target basename
CRATE_NAME="$(basename "${TARGET}")-server"

log "Generating Rust + Axum wrapper at ${TARGET}/server/…"
mkdir -p "${TARGET}/server/src"

# -----------------------------------------------------------------------------
# Cargo.toml
# -----------------------------------------------------------------------------
cat > "${TARGET}/server/Cargo.toml" <<EOF
[package]
name        = "${CRATE_NAME}"
version     = "0.1.0"
edition     = "2021"
rust-version = "1.80"
description = "Single-binary axum SPA server embedding the Vite dist via rust-embed"
license     = "MIT"

[[bin]]
name = "${CRATE_NAME}"
path = "src/main.rs"

[dependencies]
# Latest axum (0.8.x line). Note: axum 0.8 changed path parameter syntax
# from /:id (old) to /{id} (curly braces, new). Any API routes added here
# that capture path segments must use the new syntax -- see src/main.rs.
axum             = { version = "0.8.9", features = ["macros"] }
tokio            = { version = "1", features = ["full"] }
tower            = "0.5"
tower-http       = { version = "0.6.11", features = ["trace", "cors"] }
rust-embed       = { version = "8.11", features = ["interpolate-folder-path"] }
mime_guess       = "2"
anyhow           = "1"
thiserror        = "2"
tracing          = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
clap             = { version = "4", features = ["derive", "env"] }

[target.'cfg(not(target_env = "msvc"))'.dependencies]
tikv-jemallocator = "0.6"

[profile.release]
strip         = true
lto           = true
codegen-units = 1
EOF

# -----------------------------------------------------------------------------
# build.rs — run Vite when dist is missing or stale
# -----------------------------------------------------------------------------
cat > "${TARGET}/server/build.rs" <<'EOF'
// build.rs — ensures ../dist exists before rust-embed reads it at compile time.
//
// Strategy:
//   1. If ../dist does not exist, run `pnpm install` (if node_modules absent) + `pnpm build`.
//   2. If ../dist exists but is older than any file in ../src, rebuild.
//   3. Emit cargo:rerun-if-changed hints so cargo re-runs build.rs when the
//      frontend source changes.
//
// No retry; if Vite fails, the build fails.

use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::SystemTime;

fn manifest_dir() -> PathBuf {
    PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap())
}

fn frontend_root() -> PathBuf {
    // <target>/server/Cargo.toml lives at MANIFEST_DIR;
    // frontend lives at MANIFEST_DIR/.. (which is <target>/).
    manifest_dir().parent().unwrap().to_path_buf()
}

fn newest_mtime(dir: &Path) -> SystemTime {
    let mut newest = SystemTime::UNIX_EPOCH;
    if !dir.exists() {
        return newest;
    }
    for entry in walkdir(dir) {
        if let Ok(meta) = fs::metadata(&entry) {
            if let Ok(mtime) = meta.modified() {
                if mtime > newest {
                    newest = mtime;
                }
            }
        }
    }
    newest
}

fn walkdir(dir: &Path) -> Vec<PathBuf> {
    let mut out = Vec::new();
    if let Ok(rd) = fs::read_dir(dir) {
        for entry in rd.flatten() {
            let p = entry.path();
            if p.is_dir() {
                out.extend(walkdir(&p));
            } else {
                out.push(p);
            }
        }
    }
    out
}

fn ensure_dist() {
    let frontend = frontend_root();
    let dist = frontend.join("dist");
    let src = frontend.join("src");

    let src_mtime = newest_mtime(&src);
    let dist_mtime = newest_mtime(&dist);

    let needs_build = !dist.exists() || dist_mtime < src_mtime;
    if !needs_build {
        eprintln!("[build.rs] dist is up to date");
        return;
    }

    eprintln!("[build.rs] building frontend at {}", frontend.display());

    // Install deps if node_modules missing
    if !frontend.join("node_modules").exists() {
        let status = Command::new("pnpm")
            .arg("install")
            .arg("--silent")
            .current_dir(&frontend)
            .status()
            .expect("pnpm not found — install Node 20+ + pnpm");
        if !status.success() {
            panic!("pnpm install failed");
        }
    }

    let status = Command::new("pnpm")
        .arg("build")
        .current_dir(&frontend)
        .status()
        .expect("pnpm not found — install Node 20+ + pnpm");
    if !status.success() {
        panic!("pnpm build failed");
    }

    eprintln!("[build.rs] frontend built successfully");
}

fn main() {
    ensure_dist();

    // Re-run build.rs when frontend source changes
    let frontend = frontend_root();
    println!("cargo:rerun-if-changed={}/src", frontend.display());
    println!("cargo:rerun-if-changed={}/package.json", frontend.display());
    println!("cargo:rerun-if-changed={}/vite.config.ts", frontend.display());
    println!("cargo:rerun-if-changed={}/index.html", frontend.display());
}
EOF

# -----------------------------------------------------------------------------
# src/main.rs — axum + rust-embed SPA server
# -----------------------------------------------------------------------------
cat > "${TARGET}/server/src/main.rs" <<'EOF'
//! Single-binary axum SPA server.
//!
//! Embeds `../dist/` at compile time via rust-embed; serves all paths under it.
//! Non-asset paths fall back to `index.html` for client-side router compatibility.
//!
//! # Adding API routes (axum 0.8+ path-parameter syntax)
//!
//! axum 0.8 switched from `:param` to `{param}` for path captures. Add API
//! routes *before* the SPA fallback so they aren't shadowed:
//!
//! ```ignore
//! use axum::extract::Path;
//!
//! async fn get_item(Path(id): Path<String>) -> String { format!("item {id}") }
//! async fn put_user(Path((tenant, user)): Path<(String, String)>) -> String {
//!     format!("tenant={tenant} user={user}")
//! }
//!
//! let app = Router::new()
//!     // axum 0.8+ syntax — curly braces, not colon prefix.
//!     .route("/api/items/{id}", get(get_item))
//!     .route("/api/tenants/{tenant}/users/{user}", axum::routing::put(put_user))
//!     // SPA fallback MUST be last so /api/* hits the handlers above.
//!     .fallback(get(static_handler))
//!     .layer(TraceLayer::new_for_http());
//! ```
//!
//! Wildcard captures use `{*rest}`:
//!
//! ```ignore
//! .route("/files/{*path}", get(serve_file))
//! ```

use std::net::SocketAddr;

use axum::{
    body::Body,
    extract::Request,
    http::{header, HeaderValue, StatusCode, Uri},
    response::{IntoResponse, Response},
    routing::get,
    Router,
};
use clap::Parser;
use rust_embed::RustEmbed;
use tower_http::trace::TraceLayer;
use tracing::{info, warn};

#[cfg(not(target_env = "msvc"))]
#[global_allocator]
static GLOBAL: tikv_jemallocator::Jemalloc = tikv_jemallocator::Jemalloc;

#[derive(RustEmbed)]
#[folder = "../dist"]
struct Assets;

#[derive(Parser, Debug)]
#[command(name = env!("CARGO_PKG_NAME"), version, about)]
struct Cli {
    /// Port to listen on.
    #[arg(long, env = "PORT", default_value_t = 3000)]
    port: u16,

    /// Interface to bind to.
    #[arg(long, env = "HOST", default_value = "0.0.0.0")]
    host: String,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();

    let cli = Cli::parse();

    let app = Router::new()
        .fallback(get(static_handler))
        .layer(TraceLayer::new_for_http());

    let addr: SocketAddr = format!("{}:{}", cli.host, cli.port)
        .parse()
        .expect("invalid host:port");

    info!("listening on http://{}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app.into_make_service()).await.unwrap();
}

/// Looks up the requested path in the embedded asset bundle.
/// Falls back to `index.html` for SPA semantics (any path the asset bundle
/// doesn't know about, that isn't obviously an asset, gets the SPA shell).
async fn static_handler(uri: Uri, _req: Request<Body>) -> Response {
    let path = uri.path().trim_start_matches('/');
    let candidate = if path.is_empty() { "index.html" } else { path };

    if let Some(content) = Assets::get(candidate) {
        return serve_asset(candidate, content.data.into_owned());
    }

    // SPA fallback — if the path looks like a static asset (has a recognized
    // extension), return 404 instead of the index.
    if looks_like_asset(candidate) {
        warn!("asset not found: {}", candidate);
        return (StatusCode::NOT_FOUND, "Not Found").into_response();
    }

    match Assets::get("index.html") {
        Some(content) => serve_asset("index.html", content.data.into_owned()),
        None => (StatusCode::INTERNAL_SERVER_ERROR, "index.html missing from bundle").into_response(),
    }
}

fn serve_asset(path: &str, body: Vec<u8>) -> Response {
    let mime = mime_guess::from_path(path).first_or_octet_stream();
    let mut resp = Response::new(Body::from(body));
    resp.headers_mut().insert(
        header::CONTENT_TYPE,
        HeaderValue::from_str(mime.as_ref()).unwrap_or(HeaderValue::from_static("application/octet-stream")),
    );
    resp
}

fn looks_like_asset(path: &str) -> bool {
    matches!(
        path.rsplit('.').next(),
        Some("js" | "mjs" | "css" | "svg" | "png" | "jpg" | "jpeg" | "gif"
            | "ico" | "woff" | "woff2" | "ttf" | "otf" | "map" | "webp"
            | "avif" | "json" | "txt" | "wasm")
    )
}
EOF

# -----------------------------------------------------------------------------
# README.md
# -----------------------------------------------------------------------------
cat > "${TARGET}/server/README.md" <<EOF
# ${CRATE_NAME}

Single-binary axum SPA server. Embeds the Vite \`dist/\` at compile time via
\`rust-embed\`; serves it on a configurable port with \`/index.html\` SPA
fallback.

## Run

\`\`\`bash
cd server
cargo run --release
# Listens on 0.0.0.0:3000 by default
\`\`\`

## Build a deployable binary

\`\`\`bash
cargo build --release
# Binary at: target/release/${CRATE_NAME}
# Ship this single file — no node_modules needed at runtime.
\`\`\`

## How it works

- \`build.rs\` runs \`pnpm install\` (if needed) + \`pnpm build\` against \`..\` before compiling the Rust binary.
- mtime check skips the rebuild when \`dist/\` is newer than \`src/\`.
- \`rust-embed\` macro embeds \`../dist/\` into the binary at compile time.
- The axum handler serves embedded assets with mime type detection.
- Non-asset paths (no recognized extension) fall back to \`index.html\` for client-side router compatibility.

## Configuration

| Var / flag | Default | Purpose |
|---|---|---|
| \`--port\` / \`PORT\` | 3000 | Listen port |
| \`--host\` / \`HOST\` | 0.0.0.0 | Bind interface |
| \`RUST_LOG\` | info | Tracing filter |

## Adding API routes

This server is built on **axum 0.8.9**. axum 0.8 changed path parameter syntax
from \`:param\` (old) to \`{param}\` (new). When you add API routes alongside
the SPA, use the **curly-brace syntax**:

\`\`\`rust
use axum::{routing::get, extract::Path, Router};

async fn get_item(Path(id): Path<String>) -> String {
    format!("item {id}")
}

let app = Router::new()
    .route("/api/items/{id}", get(get_item))           // ✅ axum 0.8+
    .route("/api/files/{*path}", get(serve_file))      // ✅ wildcard capture
    .fallback(get(static_handler))                     // SPA fallback LAST
    .layer(TraceLayer::new_for_http());
\`\`\`

**Order matters.** Mount API routes *before* the SPA fallback so they're not
shadowed by the catch-all.

See \`src/main.rs\` module-level docs for more examples.
EOF

ok "Axum wrapper generated."
log "Verifying compile…"

# cargo check — fast, no full build
( cd "${TARGET}/server" && cargo check 2>&1 | tail -20 ) || {
  err "cargo check failed; see output above"
  exit 1
}

ok "Cargo check passed."
echo
echo "  Crate: ${CRATE_NAME}"
echo "  Path:  ${TARGET}/server/"
echo "  Run:   cd ${TARGET}/server && cargo run --release"
echo "  Ship:  ${TARGET}/server/target/release/${CRATE_NAME}"
