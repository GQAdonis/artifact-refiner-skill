//! template-core — branded-artifact rendering library.
//!
//! Modules:
//! - [`brand`]   — `BrandData` and TOML deserialization.
//! - [`engine`]  — `TemplateEngine` trait + `MinijinjaEngine` implementor.
//! - [`library`] — Brand registry helpers (list / load).
//!
//! Single-engine v0.1.0: only Minijinja ships in this phase. The trait shape
//! is in place so additional engines (Askama, Tera, Handlebars, Mustache)
//! can be added as follow-on phases without API churn.

pub mod brand;
pub mod engine;
pub mod library;

pub use brand::{
    BrandColors, BrandContact, BrandData, BrandLogo, BrandMeta, BrandTypography, ColorPalette,
    Motif,
};
pub use engine::{build_engine, EngineSelection, TemplateEngine};
pub use library::{list_brands, load_brand};
