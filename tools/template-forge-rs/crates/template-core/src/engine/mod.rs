//! Template engine trait + the one runtime implementor (Minijinja).
//!
//! The trait shape is in place so additional engines can be added later
//! without API churn. v0.1.0 ships only `MinijinjaEngine`.

use std::path::Path;

use anyhow::Result;
use serde::{Deserialize, Serialize};

use crate::brand::BrandData;

pub mod minijinja_engine;

pub use minijinja_engine::MinijinjaEngine;

/// Runtime template engine. Implementations must be `Send + Sync` so they
/// can be wrapped in `Arc<dyn TemplateEngine>` and stored in async server
/// state.
pub trait TemplateEngine: Send + Sync {
    /// Render a named template against `brand` data.
    fn render(&self, template_name: &str, brand: &BrandData) -> Result<String>;

    /// Whether the engine can resolve `template_name` from its loader.
    fn has_template(&self, template_name: &str) -> bool;

    /// Stable identifier for this engine (e.g., `"minijinja"`).
    fn engine_id(&self) -> &'static str;
}

/// User-facing engine selection.
///
/// Single variant in v0.1.0. New engines (`Askama`, `Tera`, `Handlebars`,
/// `Mustache`) will be added as follow-on phases.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum EngineSelection {
    Minijinja,
}

impl EngineSelection {
    /// Parse from a CLI-friendly string. Case-insensitive.
    pub fn from_str_ci(s: &str) -> Option<Self> {
        match s.to_ascii_lowercase().as_str() {
            "minijinja" => Some(Self::Minijinja),
            _ => None,
        }
    }

    /// All compiled-in engines, in stable order.
    pub fn all() -> &'static [EngineSelection] {
        &[EngineSelection::Minijinja]
    }

    /// Stable identifier matching `TemplateEngine::engine_id`.
    pub fn id(&self) -> &'static str {
        match self {
            Self::Minijinja => "minijinja",
        }
    }
}

/// Build a boxed engine for the given selection + templates directory.
///
/// For Minijinja, `template_dir` is the root used by `path_loader`.
pub fn build_engine(
    sel: EngineSelection,
    template_dir: &Path,
) -> Result<Box<dyn TemplateEngine>> {
    match sel {
        EngineSelection::Minijinja => {
            let engine = MinijinjaEngine::new(template_dir)?;
            Ok(Box::new(engine))
        }
    }
}
