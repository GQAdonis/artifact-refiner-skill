//! `template-forge` CLI binary.
//!
//! Subcommands:
//! - `version`        — print version
//! - `list-engines`   — list compiled-in template engines
//! - `list-brands`    — list brands in `<library>/brands/`
//! - `render`         — render a template for a brand

use std::fs;
use std::io::{self, Write};
use std::path::PathBuf;

use anyhow::{anyhow, Context, Result};
use clap::{Parser, Subcommand};
use template_core::{build_engine, list_brands, load_brand, EngineSelection};

#[cfg(not(target_env = "msvc"))]
#[global_allocator]
static GLOBAL: tikv_jemallocator::Jemalloc = tikv_jemallocator::Jemalloc;

#[derive(Parser, Debug)]
#[command(
    name = "template-forge",
    version,
    about = "Branded-artifact renderer for the artifact-refiner skill pack"
)]
struct Cli {
    #[command(subcommand)]
    cmd: Cmd,
}

#[derive(Subcommand, Debug)]
enum Cmd {
    /// Print the version string and exit.
    Version,

    /// List all template engines compiled into this binary.
    ListEngines,

    /// List brands available in `<library>/brands/`.
    ListBrands {
        #[arg(long, env = "TEMPLATE_FORGE_LIBRARY")]
        library: PathBuf,
    },

    /// Render a template for a brand.
    Render {
        /// Brand name (stem of `<library>/brands/<brand>.toml`).
        #[arg(long)]
        brand: String,

        /// Template name (without `.html`).
        #[arg(long)]
        template: String,

        /// Engine to use.
        #[arg(long, default_value = "minijinja")]
        engine: String,

        /// Brand library root.
        #[arg(long, env = "TEMPLATE_FORGE_LIBRARY")]
        library: PathBuf,

        /// Templates base directory.
        #[arg(long, env = "TEMPLATE_FORGE_TEMPLATES")]
        templates_base: PathBuf,

        /// Output destination. `-` writes to stdout (default).
        #[arg(long, default_value = "-")]
        output: String,
    },
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
    match cli.cmd {
        Cmd::Version => {
            println!("{} {}", env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"));
            Ok(())
        }
        Cmd::ListEngines => {
            for e in EngineSelection::all() {
                println!("{}", e.id());
            }
            Ok(())
        }
        Cmd::ListBrands { library } => {
            let names = list_brands(&library)
                .with_context(|| format!("listing brands under {}", library.display()))?;
            for n in names {
                println!("{n}");
            }
            Ok(())
        }
        Cmd::Render {
            brand,
            template,
            engine,
            library,
            templates_base,
            output,
        } => {
            let sel = EngineSelection::from_str_ci(&engine)
                .ok_or_else(|| anyhow!("unknown engine '{engine}'; available: minijinja"))?;
            let brand_data = load_brand(&library, &brand)
                .with_context(|| format!("loading brand '{brand}'"))?;
            let engine = build_engine(sel, &templates_base)?;
            let rendered = engine
                .render(&template, &brand_data)
                .with_context(|| format!("rendering template '{template}'"))?;

            if output == "-" {
                io::stdout().write_all(rendered.as_bytes())?;
            } else {
                fs::write(&output, rendered)
                    .with_context(|| format!("writing output to {output}"))?;
            }
            Ok(())
        }
    }
}
