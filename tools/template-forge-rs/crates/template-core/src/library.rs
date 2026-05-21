//! Brand registry helpers.
//!
//! A "library" is a directory layout:
//!
//! ```text
//! <library>/
//!   brands/
//!     <name>.toml
//!     <other-name>.toml
//! ```

use std::fs;
use std::path::Path;

use anyhow::{Context, Result};
use walkdir::WalkDir;

use crate::brand::BrandData;

/// List all brand names in `<library>/brands/`. Returns sorted, deduplicated stems.
pub fn list_brands(library_dir: &Path) -> Result<Vec<String>> {
    let brands_dir = library_dir.join("brands");
    if !brands_dir.exists() {
        return Ok(Vec::new());
    }

    let mut names: Vec<String> = WalkDir::new(&brands_dir)
        .max_depth(1)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_type().is_file())
        .filter_map(|e| {
            let p = e.path();
            if p.extension().and_then(|s| s.to_str()) == Some("toml") {
                p.file_stem().and_then(|s| s.to_str()).map(|s| s.to_string())
            } else {
                None
            }
        })
        .collect();

    names.sort();
    names.dedup();
    Ok(names)
}

/// Load one brand by name from `<library>/brands/<name>.toml`.
pub fn load_brand(library_dir: &Path, name: &str) -> Result<BrandData> {
    let path = library_dir.join("brands").join(format!("{name}.toml"));
    let raw = fs::read_to_string(&path)
        .with_context(|| format!("reading brand TOML at {}", path.display()))?;
    let brand: BrandData = toml::from_str(&raw)
        .with_context(|| format!("parsing brand TOML at {}", path.display()))?;
    Ok(brand)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::io::Write;

    fn write_min_brand(dir: &Path, name: &str) {
        let p = dir.join("brands").join(format!("{name}.toml"));
        fs::create_dir_all(p.parent().unwrap()).unwrap();
        let mut f = fs::File::create(&p).unwrap();
        let body = format!(
            "[meta]\nname = \"{name}\"\n\n\
             [colors.light]\nbg = \"#ffffff\"\nsurface = \"#f5f5f5\"\nink = \"#111111\"\nember = \"#ff0000\"\n\n\
             [colors.dark]\nbg = \"#000000\"\nsurface = \"#101010\"\nink = \"#ffffff\"\nember = \"#ff5544\"\n\n\
             [typography]\ndisplay = \"Inter\"\nui = \"Inter\"\nbody = \"Inter\"\n"
        );
        f.write_all(body.as_bytes()).unwrap();
    }

    #[test]
    fn list_brands_empty_when_no_dir() {
        let tmp = tempfile_path();
        let names = list_brands(&tmp).unwrap();
        assert!(names.is_empty());
    }

    #[test]
    fn list_and_load_roundtrip() {
        let tmp = tempfile_path();
        fs::create_dir_all(&tmp).unwrap();
        write_min_brand(&tmp, "test-brand");

        let names = list_brands(&tmp).unwrap();
        assert_eq!(names, vec!["test-brand".to_string()]);

        let brand = load_brand(&tmp, "test-brand").unwrap();
        assert_eq!(brand.meta.name, "test-brand");
        assert_eq!(brand.colors.dark.ember, "#ff5544");
    }

    fn tempfile_path() -> std::path::PathBuf {
        let mut p = std::env::temp_dir();
        p.push(format!(
            "template-core-test-{}",
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        p
    }
}
