//! Minijinja-backed template engine implementation.

use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{anyhow, Context, Result};
use minijinja::{Environment, Value};
use serde_json::json;

use crate::brand::BrandData;

use super::TemplateEngine;

/// Owns its templates directory and a per-instance `minijinja::Environment`.
///
/// Templates are loaded lazily via `path_loader` rooted at `template_dir`,
/// which means changes to template files on disk are picked up on the next
/// render call without re-instantiating the engine.
pub struct MinijinjaEngine {
    template_dir: PathBuf,
}

impl MinijinjaEngine {
    pub fn new(template_dir: &Path) -> Result<Self> {
        if !template_dir.exists() {
            return Err(anyhow!(
                "Minijinja template_dir does not exist: {}",
                template_dir.display()
            ));
        }
        Ok(Self {
            template_dir: template_dir.to_path_buf(),
        })
    }

    fn build_env(&self) -> Result<Environment<'static>> {
        let mut env = Environment::new();
        // `path_loader` requires a 'static-feeling path; we clone the buf
        // (Minijinja keeps it for the loader closure).
        let dir = self.template_dir.clone();
        env.set_loader(move |name| {
            let candidate = dir.join(format!("{name}.html"));
            match fs::read_to_string(&candidate) {
                Ok(s) => Ok(Some(s)),
                Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(None),
                Err(e) => Err(minijinja::Error::new(
                    minijinja::ErrorKind::InvalidOperation,
                    format!("read template {}: {e}", candidate.display()),
                )),
            }
        });
        Ok(env)
    }
}

impl TemplateEngine for MinijinjaEngine {
    fn render(&self, template_name: &str, brand: &BrandData) -> Result<String> {
        let env = self.build_env()?;
        let tmpl = env
            .get_template(template_name)
            .with_context(|| format!("locating template '{template_name}'"))?;
        let ctx = json!({ "brand": brand });
        let rendered = tmpl
            .render(Value::from_serialize(&ctx))
            .with_context(|| format!("rendering template '{template_name}'"))?;
        Ok(rendered)
    }

    fn has_template(&self, template_name: &str) -> bool {
        self.template_dir
            .join(format!("{template_name}.html"))
            .is_file()
    }

    fn engine_id(&self) -> &'static str {
        "minijinja"
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::brand::{
        BrandColors, BrandData, BrandMeta, BrandTypography, ColorPalette,
    };
    use std::fs;
    use std::io::Write;

    fn sample_brand() -> BrandData {
        let palette = ColorPalette {
            bg: "#0B0F14".into(),
            surface: "#0F1620".into(),
            ink: "#E5EEF8".into(),
            muted: Some("#9BB0C8".into()),
            ember: "#E04E28".into(),
            ember_alt: Some("#FF6A3D".into()),
            info: Some("#60A5FA".into()),
            border: Some("#1E2A3A".into()),
        };
        BrandData {
            meta: BrandMeta {
                name: "knowme".into(),
                tagline: Some("Identity layer for human-AI collaboration".into()),
                description: None,
            },
            colors: BrandColors {
                light: palette.clone(),
                dark: palette,
            },
            typography: BrandTypography {
                display: "Space Grotesk".into(),
                ui: "Inter".into(),
                body: "Roboto".into(),
                mono: Some("JetBrains Mono".into()),
            },
            logo: None,
            contact: None,
        }
    }

    fn temp_dir() -> PathBuf {
        let mut p = std::env::temp_dir();
        p.push(format!(
            "template-mj-test-{}",
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        fs::create_dir_all(&p).unwrap();
        p
    }

    #[test]
    fn render_basic_template() {
        let dir = temp_dir();
        let mut f = fs::File::create(dir.join("hello.html")).unwrap();
        writeln!(f, "name={{{{ brand.meta.name }}}} ember={{{{ brand.colors.dark.ember }}}}").unwrap();
        let engine = MinijinjaEngine::new(&dir).unwrap();
        let out = engine.render("hello", &sample_brand()).unwrap();
        assert!(out.contains("name=knowme"), "got: {out}");
        assert!(out.contains("ember=#E04E28"), "got: {out}");
    }

    #[test]
    fn has_template_reflects_disk() {
        let dir = temp_dir();
        let engine = MinijinjaEngine::new(&dir).unwrap();
        assert!(!engine.has_template("missing"));
        fs::write(dir.join("there.html"), "x").unwrap();
        assert!(engine.has_template("there"));
    }

    #[test]
    fn missing_template_errors() {
        let dir = temp_dir();
        let engine = MinijinjaEngine::new(&dir).unwrap();
        let err = engine.render("nope", &sample_brand()).unwrap_err();
        assert!(err.to_string().contains("nope"));
    }
}
