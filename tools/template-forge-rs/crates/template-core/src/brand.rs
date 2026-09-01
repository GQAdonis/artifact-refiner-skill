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
    /// Visual idioms for the brand direction. Consumed by `moodboard.html`,
    /// which falls back to a built-in set when this is absent.
    #[serde(default)]
    pub motifs: Option<Vec<Motif>>,
    /// Voice descriptors for copywriting alignment. Same fallback contract as
    /// [`BrandData::motifs`].
    #[serde(default)]
    pub tone: Option<Vec<String>>,
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

/// One visual motif — a named idiom with a short rationale.
///
/// Deserialized from a TOML `[[motifs]]` array-of-tables. Both fields are
/// required: a motif without a title or description has nothing to render.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Motif {
    pub title: String,
    pub description: String,
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

#[cfg(test)]
mod tests {
    use super::*;

    /// Minimal valid brand TOML body — the `[table]` sections only.
    ///
    /// In TOML, a bare `key = value` after a table header belongs to that
    /// table, so top-level scalars such as `tone` must be emitted *before* any
    /// header. Helpers therefore compose as `<top-level keys> + tables()`,
    /// never `tables() + <top-level keys>`.
    fn tables() -> &'static str {
        "[meta]\nname = \"probe\"\n\n\
         [colors.light]\nbg = \"#ffffff\"\nsurface = \"#f5f5f5\"\nink = \"#111111\"\nember = \"#ff0000\"\n\n\
         [colors.dark]\nbg = \"#000000\"\nsurface = \"#101010\"\nink = \"#ffffff\"\nember = \"#ff5544\"\n\n\
         [typography]\ndisplay = \"Inter\"\nui = \"Inter\"\nbody = \"Inter\"\n"
    }

    #[test]
    fn deserializes_motifs_from_array_of_tables() {
        let toml_src = format!(
            "{}\n[[motifs]]\ntitle = \"Layered surfaces\"\ndescription = \"Soft elevation.\"\n\n\
             [[motifs]]\ntitle = \"Mono accent\"\ndescription = \"Numerics in monospace.\"\n",
            tables()
        );
        let brand: BrandData = toml::from_str(&toml_src).expect("brand TOML should parse");

        let motifs = brand.motifs.expect("motifs must survive deserialization");
        assert_eq!(motifs.len(), 2);
        assert_eq!(motifs[0].title, "Layered surfaces");
        assert_eq!(motifs[0].description, "Soft elevation.");
        assert_eq!(motifs[1].title, "Mono accent");
    }

    #[test]
    fn deserializes_tone_as_string_array() {
        let toml_src = format!("tone = [\"Direct\", \"Confident\"]\n\n{}", tables());
        let brand: BrandData = toml::from_str(&toml_src).expect("brand TOML should parse");

        assert_eq!(
            brand.tone.expect("tone must survive deserialization"),
            vec!["Direct".to_string(), "Confident".to_string()]
        );
    }

    /// Brands predating this field pair must keep loading — the template's
    /// built-in fallback blocks depend on `None`, not on an empty vec.
    #[test]
    fn absent_motifs_and_tone_deserialize_as_none() {
        let brand: BrandData = toml::from_str(tables()).expect("brand TOML should parse");
        assert!(brand.motifs.is_none());
        assert!(brand.tone.is_none());
    }

    /// Guards the specific defect this phase closes: `BrandData` is what the
    /// template engine receives as its root context, so a field that fails to
    /// serialize back out is invisible to `{% if brand.motifs %}` even after it
    /// deserializes correctly.
    #[test]
    fn motifs_and_tone_survive_serialization_into_template_context() {
        let toml_src = format!(
            "tone = [\"Pragmatic\"]\n\n{}\n[[motifs]]\ntitle = \"Ember warmth\"\ndescription = \"Accent reserved for CTAs.\"\n",
            tables()
        );
        let brand: BrandData = toml::from_str(&toml_src).expect("brand TOML should parse");
        let ctx = serde_json::to_value(&brand).expect("brand must serialize for the engine");

        assert_eq!(ctx["motifs"][0]["title"], "Ember warmth");
        assert_eq!(ctx["motifs"][0]["description"], "Accent reserved for CTAs.");
        assert_eq!(ctx["tone"][0], "Pragmatic");
    }
}
