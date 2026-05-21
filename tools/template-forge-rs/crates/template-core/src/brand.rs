//! `BrandData` and friends — the shape of a brand TOML file.
//!
//! All structs derive `Serialize` so they can be passed to the templating
//! engine as the `brand` root context. Templates reference fields via
//! `{{ brand.meta.name }}`, `{{ brand.colors.dark.ember }}`, etc.

use serde::{Deserialize, Serialize};

/// Full brand definition deserialized from a TOML file.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BrandData {
    pub meta: BrandMeta,
    pub colors: BrandColors,
    pub typography: BrandTypography,
    #[serde(default)]
    pub logo: Option<BrandLogo>,
    #[serde(default)]
    pub contact: Option<BrandContact>,
}

/// Top-level metadata for a brand.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BrandMeta {
    pub name: String,
    #[serde(default)]
    pub tagline: Option<String>,
    #[serde(default)]
    pub description: Option<String>,
}

/// Light and dark palettes. Both are required so templates can reference
/// either without conditional logic.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BrandColors {
    pub light: ColorPalette,
    pub dark: ColorPalette,
}

/// One palette. Token names mirror the KnowMe / Prometheus brand vocabulary.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ColorPalette {
    pub bg: String,
    pub surface: String,
    pub ink: String,
    #[serde(default)]
    pub muted: Option<String>,
    pub ember: String,
    #[serde(default)]
    pub ember_alt: Option<String>,
    #[serde(default)]
    pub info: Option<String>,
    #[serde(default)]
    pub border: Option<String>,
}

/// Typography stack.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BrandTypography {
    pub display: String,
    pub ui: String,
    pub body: String,
    #[serde(default)]
    pub mono: Option<String>,
}

/// Optional logo references.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BrandLogo {
    #[serde(default)]
    pub icon: Option<String>,
    #[serde(default)]
    pub wordmark: Option<String>,
    #[serde(default)]
    pub lockup: Option<String>,
}

/// Optional contact / brand-owner info.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BrandContact {
    #[serde(default)]
    pub email: Option<String>,
    #[serde(default)]
    pub url: Option<String>,
    #[serde(default)]
    pub legal_entity: Option<String>,
}
