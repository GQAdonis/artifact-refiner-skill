# Artifact Refiner Skill Pack — Session Notes
**Date:** 2026-05-20
**Context:** Claude Desktop (claude.ai) — travisjames.ai project
**Handoff target:** Claude Code at `/Users/gqadonis/Projects/travisjames/skills/artifact-refiner`

---

## What This Document Is

A complete record of a single Claude Desktop session in which we designed,
specified, and wrote the initial implementation of six new skills for the
`artifact-refiner` skill pack, plus the `template-forge-rs` Rust workspace
that backs the `build-artifact-library` skill. This document is intended to
give Claude Code full context to continue the work without re-explaining
anything.

---

## Background

Travis James (@GQAdonis) maintains a personal brand and AI ecosystem under
`travisjames.ai`, `prometheusags.ai`, and `know-me.tools`. He runs a skill
pack at `prometheus-skill-pack` that follows a pattern of packaging Rust CLI
tools and MCP servers alongside PMPO-driven SKILL.md specifications. The
`artifact-refiner` skill pack lives at:

```
/Users/gqadonis/Projects/travisjames/skills/artifact-refiner/
```

It already contained the following skills when this session began:

| Skill | Purpose |
|---|---|
| `artifact-refiner` | Root PMPO orchestration skill |
| `refine-logo` | Logo and brand system refinement |
| `refine-ui` | React/HTML UI component refinement |
| `refine-content` | Content/Markdown refinement |
| `refine-image` | Image artifact refinement |
| `refine-a2ui` | A2UI specification refinement |
| `refine-validate` | Validation checks on current state |
| `refine-status` | Check current refinement progress |

The skill pack also imports `sycophancy-correction` from
`prometheus-skill-pack/skills/imported/sycophancy-correction`.

---

## Conversation Summary

### Part 1 — Antigravity 2.0 Research

Travis asked about improvements in Antigravity 2.0 (Google's coding AI IDE,
announced at Google I/O 2026 on May 19). Key findings:

- Antigravity 2.0 unifies Gemini CLI under a single brand and adds a
  **multi-agent manager view** for parallel agent orchestration
- **No BYOK support** — confirmed pain point in the community. Users cannot
  bring their own API keys. Rate limiting is a known complaint.
- Supported models include Claude Sonnet 4.6, Claude Opus 4.6, GPT-OSS-120B
  alongside Gemini.
- A community project **OpenGravity** (github.com/ab-613/OpenGravity) was
  found — a BYOK Gemini-only open-source Antigravity clone, alpha quality,
  built in vanilla HTML/JS, maintained by a student on Sunday evenings.
- Travis filed a GitHub issue on OpenGravity suggesting a **Tauri port** for
  native file access, better performance, multi-model support via liter-llm,
  and UAR-backed agentic functionality.

### Part 2 — BossGravity UI Prototype (v1)

Travis asked for a React artifact showing what his own version of Antigravity —
called **BossGravity** — would look like, using:

- UAR for ephemeral agentic behavior
- BossFang for long-running / scheduled agent activities

The v1 artifact was built using **Prometheus AGS brand tokens** (Cinzel, Syne,
DM Sans, ember `#E96A12`, warm charcoal surfaces). It included:

- Two views: **Manager View** (parallel agent cards) and **Editor View** (chat)
- Left sidebar with conversations and scheduled tasks
- Right inspector panel showing agent detail (progress, activity log, controls)
- Runtime toggle (UAR vs BossFang) in the input bar
- Model selector (Claude Sonnet 4.6, Opus 4.6, Gemini, Llama local, DeepSeek)
- Five seeded agents drawn from real projects (SSR frontend, doc generation,
  MCP config, mineral sync, HotSeaters refactor)

### Part 3 — BossGravity UI Prototype (v2 — KnowMe brand + Responsive)

Travis invoked the **artifact-refiner skill** to apply two changes:

1. Switch branding from Prometheus AGS to **KnowMe LLC** design system
2. Full-viewport layout + mobile PWA / Tauri responsive behavior

The refiner PMPO loop ran:

**Specify:** KnowMe dark brand, `100dvh` full-viewport desktop, mobile-first
with bottom nav, Tauri safe-area insets.

**Key changes made:**

- All Prometheus tokens purged (Cinzel/Syne/DM Sans, `#E96A12`, `#00C2DC`,
  warm charcoal) — replaced with KnowMe tokens
- **KnowMe dark palette:** `#0B0F14` bg, `#0F1620` card, `#1E2A3A` border,
  `#E04E28` / `#FF6A3D` ember, `#60A5FA` info
- **KnowMe fonts:** Space Grotesk (display), Inter (UI), Roboto (body),
  JetBrains Mono (mono)
- Fixed `640px` container replaced with `height: 100dvh` full shell
- `useIsMobile(768)` hook with resize listener — reactive breakpoint
- **Desktop:** 3-pane layout (220px sidebar | flex main | 280px inspector)
- **Mobile:** fixed bottom tab bar (Chats / Agents / Editor / Tasks) with
  `env(safe-area-inset-bottom)` home bar clearance
- `paddingTop: env(safe-area-inset-top)` on root for notch clearance
- 44px minimum touch targets throughout
- Agent detail sheet on mobile (modal drawer from bottom) instead of right panel
- All interactive elements sized for thumb reach

**Output file:** `/mnt/user-data/outputs/bossgravity-v2.jsx`

---

### Part 4 — Six New Skills for the Artifact Refiner Pack

Travis described five recurring workflows he runs in Claude Desktop and wanted
them packaged as skills alongside the existing ones.

**The five workflows described:**

1. Converting markdown documents to HTMX artifacts using brand templates
2. Converting HTMX artifacts to/from React TSX artifacts (bidirectional)
3. Switching the branding on an existing artifact to a different brand guide
4. Creating mood boards for brands/applications
5. Creating SVG logos for product and branding ideas

**Skills created** (written to `skills/artifact-refiner/skills/`):

| Skill | File | Purpose |
|---|---|---|
| `convert-md-to-htmx` | `skills/convert-md-to-htmx/SKILL.md` | Markdown to branded HTMX document via template |
| `convert-htmx-react` | `skills/convert-htmx-react/SKILL.md` | Bidirectional HTMX and React TSX conversion |
| `rebrand-artifact` | `skills/rebrand-artifact/SKILL.md` | Apply a different brand guide to an existing artifact |
| `refine-moodboard` | `skills/refine-moodboard/SKILL.md` | Create mood boards from use case / scenario briefs |
| `design-svg-logo` | `skills/design-svg-logo/SKILL.md` | Standalone SVG logo creation (lighter than refine-logo) |

> **NOTE:** Only `convert-md-to-htmx/SKILL.md` was partially written before
> the conversation moved on. The other four have directories but empty or
> missing SKILL.md files. All five need completion. See Priority 2 below.

---

### Part 5 — build-artifact-library Skill + template-forge-rs Tool

Travis extended the request: he wanted a skill that **creates the initial HTMX
artifacts from which to work** and keeps them in a library, with:

- Markdown versions of branding guide, branding template, and moodboard
  artifacts as **Askama templates** (Rust compile-time)
- The same templates as HTMX output
- Following the `prometheus-skill-pack` pattern of native Rust CLI programs
  and MCP servers built alongside skills

He also required:

- Sycophancy correction applied before writing
- Tavily web search to research best practices for toolchain installation
- Cross-platform Rust toolchain support ("guaranteed to compile, run, and be
  optimal")

**Research conducted via Tavily:**

1. **Askama 0.16 state (2025-2026):**
   - No built-in CLI — the binary IS the CLI
   - Compile-time only — new template *structures* require a rebuild
   - Brand *data* injected at runtime via struct fields — no rebuild needed
   - Tera is better for fully dynamic template loading without rebuild
   - Correct architecture: Askama for fixed scaffold + Tera/Minijinja for
     user-extensible templates
   - `askama_axum` deprecated; use `askama_web` or manual rendering

2. **Cross-platform Rust installer best practices:**
   - `rustup` detection with fallback install
   - MSRV enforcement (set to 1.80)
   - `cargo-binstall` for binary installation (Homebrew on macOS, cargo fallback)
   - Target triple detection via `uname -s / uname -m`
   - `cargo-dist` for release artifacts
   - `cross` for cross-compilation
   - Non-interactive flags for CI (`--no-confirm`, `--quiet`)

**Sycophancy correction applied before writing:**

The key honest finding: Askama is appropriate for this use case IF the template
structure is fixed at compile time and only brand data changes at runtime. For a
library where "brand templates" = "fixed HTML scaffold + brand variable injection",
Askama is correct. Adding a NEW template type (a fourth document layout) requires
a binary rebuild. This tradeoff is explicitly documented in the SKILL.md.

**What was built:**

```
skills/artifact-refiner/
  skills/build-artifact-library/
    SKILL.md

  tools/template-forge-rs/
    Cargo.toml
    crates/
      template-core/
        Cargo.toml
        src/
          lib.rs
          brand.rs
          render.rs
          library.rs
      template-cli/
        Cargo.toml
        src/main.rs
      template-mcp/
        Cargo.toml
        src/main.rs
    templates/
      brand-guide.html
      brand-template.html
      moodboard.html
      partials/nav.html
      partials/footer.html

  assets/library/brands/
    knowme.toml
    prometheus-ags.toml

  scripts/
    install-template-forge.sh
```

---

### Part 6 — TemplateEngine Trait Abstraction

Travis asked: "Would it be an advantage to abstract template engine use to a
trait and evolve this to be able to use handlebars, mustache, minijinja, as
well as tera and askama?"

**Honest assessment given:**

- Askama **cannot** cleanly implement a dynamic trait — its compile-time nature
  makes `Box<dyn TemplateEngine>` a leaky abstraction. It stays as a special
  compile-time dispatch path and does NOT implement the trait.
- The four runtime engines (Minijinja, Tera, Handlebars, Ramhorns) share the
  same conceptual model: load by name, inject context, return string. A trait
  across those four is genuinely useful.
- **Correct design:** `EngineSelection::Askama` routes to compile-time dispatch.
  All other selections route to `Box<dyn TemplateEngine>`.
- **Minijinja** recommended over Tera as default runtime engine (stricter
  Jinja2 fidelity, better errors, maintained by Armin Ronacher — also the
  author of the original Jinja2).
- **Handlebars** — logic-less discipline is a feature for brand documents.
  Prevents template authors from encoding conditional styling logic that
  belongs in Rust code.
- **Ramhorns** — fastest Mustache impl in Rust. The `mustache` crate is
  unmaintained; use Ramhorns instead.

Travis said "yes, do it." The full refactor was executed.

---

## Final State — Everything That Was Built

### The `TemplateEngine` Trait

```rust
pub trait TemplateEngine: Send + Sync {
    fn render(&self, template_name: &str, brand: &BrandData) -> Result<String>;
    fn has_template(&self, template_name: &str) -> bool;
    fn engine_id(&self) -> &'static str;
}
```

`Send + Sync` required for `Arc<dyn TemplateEngine>` storage in the async MCP server.

### `EngineSelection` Enum

```rust
pub enum EngineSelection {
    Askama,       // compile-time path, no trait impl
    Minijinja,    // feature = "engine-minijinja" (default on)
    Tera,         // feature = "engine-tera"
    Handlebars,   // feature = "engine-handlebars" (default on)
    Mustache,     // feature = "engine-mustache" (ramhorns)
}
```

Default features: `engine-minijinja` + `engine-handlebars`.

### Engine Implementations

| File | Engine | Crate | Template dir |
|---|---|---|---|
| `engine/askama_engine.rs` | Askama | `askama 0.12` | `templates/` (compiled in) |
| `engine/minijinja_engine.rs` | Minijinja | `minijinja 2` | `templates/jinja/` |
| `engine/tera_engine.rs` | Tera | `tera 1` | `templates/jinja/` (same syntax) |
| `engine/handlebars_engine.rs` | Handlebars | `handlebars 6` | `templates/handlebars/` |
| `engine/mustache_engine.rs` | Ramhorns | `ramhorns 0.12` | `templates/mustache/` |

### Template Directory Structure (final)

```
templates/
  brand-guide.html          <- Askama source (compiled into binary)
  brand-template.html
  moodboard.html
  partials/
    nav.html
    footer.html
  jinja/                    <- Minijinja + Tera (Jinja2 syntax)
    brand-guide.html
    brand-template.html
    moodboard.html
    partials/
      nav.html
      footer.html
  handlebars/               <- Handlebars {{}} syntax
    brand-guide.html
    brand-template.html
    moodboard.html
    partials/
      nav.html
      footer.html
  mustache/                 <- Ramhorns {{}} syntax
    brand-guide.html
    brand-template.html
    moodboard.html
    partials/
      nav.html
      footer.html
```

### Context Convention (consistent across all engines)

All runtime engines receive `{ "brand": <BrandData> }` as root context so
template variable paths are consistent:

```
{{ brand.meta.name }}         <- minijinja / tera / handlebars
{{brand.meta.name}}           <- mustache (ramhorns, no spaces)
{{ brand.colors.dark.ember }}
{{ brand.typography.display }}
```

Askama accesses brand data via a struct field also named `brand`:

```rust
struct BrandGuideTemplate<'a> { brand: &'a BrandData }
// In template: {{ brand.meta.name }}
```

### Conditional Ramhorns Derives

`ramhorns::Content` is derived conditionally on all brand structs to avoid
adding the proc-macro cost to builds that don't need Mustache:

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "engine-mustache", derive(ramhorns::Content))]
pub struct BrandData { ... }
// Same pattern on BrandMeta, ColorPalette, BrandColors,
// BrandTypography, BrandLogo, BrandContact
```

### Factory Function

```rust
pub fn build_engine(
    selection: EngineSelection,
    template_dir: &Path,
) -> Result<Option<Box<dyn TemplateEngine>>>
```

Returns `None` for `Askama` (handled by `askama_engine::render_askama()`
separately). Returns `Some(Box<dyn TemplateEngine>)` for all runtime engines.

### `EngineSelection::default_template_dir()`

Encodes the template directory convention so neither the CLI nor MCP server
needs to know about it:

```rust
pub fn default_template_dir(&self, base_dir: &Path) -> PathBuf {
    match self {
        Askama     => base_dir.to_path_buf(),      // unused at runtime
        Minijinja  => base_dir.join("jinja"),
        Tera       => base_dir.join("jinja"),
        Handlebars => base_dir.join("handlebars"),
        Mustache   => base_dir.join("mustache"),
    }
}
```

### MCP Server Tools Exposed

The `template-forge-mcp` binary (stdio JSON-RPC 2.0) exposes:

| Tool | Description |
|---|---|
| `template_forge_list_brands` | List all registered brands |
| `template_forge_render` | Render one or all templates for a brand |
| `template_forge_library_status` | Return brand + artifact inventory |
| `template_forge_list_engines` | List engines compiled into this build |

Add to `.mcp.json`:
```json
{
  "mcpServers": {
    "template-forge": {
      "command": "template-forge-mcp",
      "args": ["--library", "assets/library"],
      "transport": "stdio"
    }
  }
}
```

---

## Complete File Tree (final state)

```
/Users/gqadonis/Projects/travisjames/skills/artifact-refiner/
├── assets/
│   └── library/
│       └── brands/
│           ├── knowme.toml
│           └── prometheus-ags.toml
├── docs/
│   └── session-2026-05-20-artifact-refiner-buildout.md   <- this file
├── scripts/
│   └── install-template-forge.sh
├── skills/
│   ├── build-artifact-library/
│   │   └── SKILL.md                          <- complete
│   ├── convert-htmx-react/
│   │   └── SKILL.md                          <- INCOMPLETE
│   ├── convert-md-to-htmx/
│   │   └── SKILL.md                          <- partially written
│   ├── design-svg-logo/
│   │   └── SKILL.md                          <- INCOMPLETE
│   ├── rebrand-artifact/
│   │   └── SKILL.md                          <- INCOMPLETE
│   └── refine-moodboard/
│       └── SKILL.md                          <- INCOMPLETE
└── tools/
    └── template-forge-rs/
        ├── Cargo.toml                         <- workspace manifest
        ├── crates/
        │   ├── template-cli/
        │   │   ├── Cargo.toml
        │   │   └── src/main.rs
        │   ├── template-core/
        │   │   ├── Cargo.toml
        │   │   └── src/
        │   │       ├── brand.rs
        │   │       ├── engine/
        │   │       │   ├── askama_engine.rs
        │   │       │   ├── handlebars_engine.rs
        │   │       │   ├── minijinja_engine.rs
        │   │       │   ├── mod.rs
        │   │       │   ├── mustache_engine.rs
        │   │       │   └── tera_engine.rs
        │   │       ├── lib.rs
        │   │       ├── library.rs
        │   │       └── render.rs
        │   └── template-mcp/
        │       ├── Cargo.toml
        │       └── src/main.rs
        └── templates/
            ├── brand-guide.html        <- Askama source
            ├── brand-template.html
            ├── moodboard.html
            ├── partials/
            ├── handlebars/
            │   ├── brand-guide.html
            │   ├── brand-template.html
            │   ├── moodboard.html
            │   └── partials/
            ├── jinja/
            │   ├── brand-guide.html
            │   ├── brand-template.html
            │   ├── moodboard.html
            │   └── partials/
            └── mustache/
                ├── brand-guide.html
                ├── brand-template.html
                ├── moodboard.html
                └── partials/
```

---

## What Claude Code Needs to Do Next

### Priority 1 — Get it compiling

The Rust workspace has never been compiled. Start here:

```sh
cd /Users/gqadonis/Projects/travisjames/skills/artifact-refiner/tools/template-forge-rs
cargo check 2>&1
```

**Known issues to resolve:**

**Issue 1 — Askama template directory resolution**

Askama resolves templates relative to the crate root by default. The Askama
template files are at `tools/template-forge-rs/templates/` but the crate
consuming them is at `tools/template-forge-rs/crates/template-core/`. Fix
with a `build.rs` in `template-core`:

```rust
// crates/template-core/build.rs
fn main() {
    let templates = concat!(env!("CARGO_MANIFEST_DIR"), "/../../templates");
    println!("cargo:rustc-env=ASKAMA_TEMPLATE_DIR={templates}");
    println!("cargo:rerun-if-changed=../../templates");
}
```

Or alternatively move Askama template files into
`crates/template-core/templates/` — cleaner for Askama but separates them
from the runtime engine templates.

**Issue 2 — `ramhorns::Content` manual impl on `BrandContext`**

The manual `Content` impl in `brand.rs` is a stub. Test with:

```sh
cargo check --features engine-mustache
```

If mustache rendering produces blank output, the `render_field_escaped` /
`render_field_unescaped` methods need expanding to properly route the `brand`
key to `BrandData`'s derived `Content` impl.

Alternative simpler approach: remove `BrandContext` wrapper entirely for the
mustache engine and pass `BrandData` directly as root context — this means
mustache templates use `{{meta.name}}` instead of `{{brand.meta.name}}`.
The inconsistency is documented and acceptable since mustache templates are in
their own directory.

**Issue 3 — Minijinja includes**

`{% include "partials/nav.html" %}` in jinja templates requires partials to be
resolvable by the path_loader. Verify the loader finds them under
`templates/jinja/partials/`. The path passed to `path_loader()` must be the
`jinja/` subdirectory root, not the top-level `templates/` root.

**Issue 4 — Handlebars partial registration key names**

Partials registered with the WalkDir loop in `handlebars_engine.rs` use
`rel.with_extension("")` which produces `partials/nav` on Unix and
`partials\nav` on Windows. The Windows case is handled by
`.replace('\\', "/")` — verify this actually runs before the `reg.register_template_file`
call and that `{{> partials/nav}}` in templates matches the registered key.

**Issue 5 — `EngineArg` in template-cli with all feature combinations**

The `From<EngineArg> for EngineSelection` impl uses `#[cfg]` attributes to
match the enabled features. Run `cargo check` with each combination to confirm:

```sh
cargo check -p template-cli
cargo check -p template-cli --features engine-mustache
cargo check -p template-cli --all-features
cargo check -p template-cli --no-default-features
```

**Issue 6 — Tera BrandContext lifetime**

`serde_json::to_value(BrandContext { brand })` where `brand: &'a BrandData`
requires `BrandContext<'a>: Serialize`. The `#[derive(Serialize)]` on
`BrandContext<'a>` should handle this but verify it compiles without lifetime
errors in tera_engine.rs.

---

### Priority 2 — Complete the partial SKILL.md files

Four skills have directories but no completed SKILL.md. Write them following
the canonical format from `refine-logo/SKILL.md` and `refine-ui/SKILL.md`.

**`convert-htmx-react/SKILL.md`**

Bidirectional converter. Should handle:
- HTMX -> React: parse HTML structure, convert to JSX, extract inline styles
  to CSS-in-JS or Tailwind, convert Alpine.js x-data to useState hooks
- React -> HTMX: flatten JSX, convert event handlers to hx-* attributes,
  extract React state to Alpine.js x-data controllers
- content_type: direct:react (HTMX->React direction) or direct:html (React->HTMX)

**`rebrand-artifact/SKILL.md`**

Takes an existing artifact (HTMX or React) and a target brand guide name.
Should:
- Load target brand guide tokens (colors, fonts, contact)
- Identify brand-specific CSS custom properties in the artifact
- Replace all token values with target brand values
- Validate WCAG AA compliance with the new palette
- Output rebranded artifact preserving all structural/content changes
- content_type: direct:html or direct:react depending on input

**`refine-moodboard/SKILL.md`**

Mood board creation for brands and applications. Should:
- Accept: use case description, target audience, aesthetic direction keywords,
  brand guide reference (optional)
- Produce: self-contained HTMX moodboard document with color swatches,
  typography specimens, UI motif references, scenario descriptions
- Integrate with template-forge render --template moodboard when a brand is
  already registered
- content_type: direct:html

**`design-svg-logo/SKILL.md`**

Standalone SVG logo creation. Lighter weight than refine-logo — no full brand
system required. Should:
- Accept: brand name, brief description, style keywords, primary color
- Produce: SVG source file(s) with icon, wordmark, and combined lockup variants
- Output PNG set at standard sizes (16, 32, 64, 128, 256, 512)
- Note: this is concept/ideation-focused; production SVG work goes through
  refine-logo with full brand guide

**`convert-md-to-htmx/SKILL.md`** (partial — finish it)

The first section was written. Complete from the Execution Steps section
through Default Constraints and Artifact Outputs. The partial content is
already in the file — pick up from where it ends.

---

### Priority 3 — Wire sycophancy correction hook

The `build-artifact-library` SKILL.md specifies that before emitting any
rendered artifact, this runs:

```sh
bash ../sycophancy-correction/scripts/check-reflect.sh <artifact_path>
```

This script does not yet exist. Either:

- Add `check-reflect.sh` to the sycophancy-correction skill at
  `prometheus-skill-pack/skills/imported/sycophancy-correction/scripts/`
- Or call the `sycophancy-mcp` tool via the running MCP server

This is tracked as task `SP-013` in the prometheus-skill-pack change log.

---

### Priority 4 — Install and smoke test

```sh
# Step 1: Build and install the CLI
bash /Users/gqadonis/Projects/travisjames/skills/artifact-refiner/scripts/install-template-forge.sh

# Step 2: Verify installation
template-forge --version
template-forge list-engines

# Step 3: Initialize the library
template-forge init --library assets/library

# Step 4: Render all KnowMe templates with minijinja
template-forge render \
  --brand knowme \
  --template all \
  --engine minijinja \
  --library assets/library \
  --templates-base tools/template-forge-rs/templates

# Step 5: Check output
ls assets/library/artifacts/brand-guides/
ls assets/library/artifacts/brand-templates/
ls assets/library/artifacts/moodboards/

# Step 6: Open one in a browser to verify rendering
open assets/library/artifacts/brand-guides/knowme-brand-guide.html
```

---

### Priority 5 — Add remaining brand TOML files

The following brands are referenced in the skill pack but have no TOML files yet:

```
assets/library/brands/san-saba-royalty.toml
assets/library/brands/hotseaters.toml
assets/library/brands/tribehealth.toml
```

Brand token reference:

**San Saba Royalty:**
- Primary: teal `#0B5563`, dark teal `#33BFD1`, sand `#A8977F`
- Fonts: Inter, JetBrains Mono, Roboto Slab

**HotSeaters:**
- Navy `#101838` / `#1B2B7A`, teal `#5AADA0`, tan `#D4A66B`, red `#C13A25`
- Fonts: Zen Dots, Michroma, Montserrat, Syncopate, JetBrains Mono

**TribeHealth:**
- Not yet designed — brand work needed before TOML can be created

---

### Priority 6 — Register skills in marketplace.json

After completing all SKILL.md files, register the six new skills in:

```
/Users/gqadonis/Projects/travisjames/skills/artifact-refiner/.claude-plugin/marketplace.json
```

Follow the format of existing entries in that file.

---

## Key Design Decisions and Rationale

### Why Askama stays outside the trait

Askama's templates are Rust structs compiled at build time. There is no runtime
"load template by name" API. Forcing it behind `Box<dyn TemplateEngine>` would
require hiding a `match template_name { "brand-guide" => ... }` dispatch inside
the trait impl — which is exactly what `askama_engine::render_askama()` already
is. The trait adds no value for Askama. Keeping it as a separate compile-time
path preserves the semantic distinction: Askama is infrastructure, the runtime
engines are configuration.

### Why Minijinja is the default over Tera

Minijinja is maintained by Armin Ronacher (also the author of Jinja2 for
Python). It has stricter Jinja2 conformance, better error messages, and more
active development as of 2026. Tera is still valid and the same
`templates/jinja/` files work with both — having both compiled in gives a
fallback if one has a bug with a specific template construct.

### Why feature flags and not always-on engines

`ramhorns::Content` requires a proc-macro derive on every struct in `brand.rs`.
Compiling Ramhorns when you only want Minijinja adds compile time and binary
size for no benefit. Feature flags let the install script produce a minimal
binary. The defaults (`engine-minijinja` + `engine-handlebars`) cover the
most common use cases without unnecessary overhead.

### Why all engines share the same context path convention

`{{ brand.meta.name }}` works across Minijinja, Tera, and Handlebars.
`{{brand.meta.name}}` works in Mustache. This was a deliberate design choice:
templates can be mechanically adapted between engine families with only syntax
adjustments, not logic changes. The alternative — each engine using its own
context shape — would make the template library fragmented and harder to
maintain as brands are added.

### Why `MustacheEngine` stores raw source strings instead of parsed `Template`

Ramhorns `Template<'a>` holds a reference to the source string it was parsed
from. Storing `String` source values in a `HashMap` and parsing at render time
avoids the `'static` lifetime complexity (`Box::leak()` etc.) at the cost of
one re-parse per render call. For brand document generation — low volume,
human-readable HTML output — this is acceptable. If this becomes a hot path,
switch to `Template<'static>` with leaked source strings.

### Why the install script uses cargo install fallback over cargo-dist

`cargo-dist` requires CI pipeline setup and GitHub releases. The skill pack is
not yet producing GitHub releases for `template-forge`. The install script
probes `cargo-binstall` first (which will work once releases exist) and falls
back to `cargo install --path` from source. This is intentionally ordered to
minimize friction during early development while being ready for the binary
distribution path.

---

## BossGravity — Separate Deliverable

The BossGravity UI prototype (`bossgravity-v2.jsx`) was produced as a
standalone React artifact during this session, separate from the skill pack
work. It demonstrates the UX for a potential Tauri application that:

- Uses UAR for ephemeral agent sessions
- Uses BossFang for persistent and scheduled agent tasks
- Follows KnowMe LLC brand system throughout
- Renders as a full-viewport desktop app and a mobile PWA with bottom navigation

If Travis decides to build BossGravity as a real Tauri application, the
starting point is `bossgravity-v2.jsx` combined with the
`hybrid-mobile-architecture` skill at:

```
prometheus-skill-pack/skills/user/hybrid-mobile-architecture/SKILL.md
```

---

## References

- Artifact refiner root SKILL.md: `skills/artifact-refiner/SKILL.md`
- Sycophancy correction skill: `prometheus-skill-pack/skills/imported/sycophancy-correction/SKILL.md`
- forge-rs pattern reference: `prometheus-skill-pack/tools/forge-rs/`
- prometheus-cli pattern reference: `prometheus-skill-pack/tools/prometheus-cli/`
- KnowMe brand tokens source: `knowme-iam-standard.html`, `knowme-wordmark-system.html`,
  `knowme-business-cards.html` (project files)
- Prometheus AGS brand tokens source: `prometheus-brand-guide-v3.html`
- Askama documentation: https://askama.rs
- Minijinja documentation: https://docs.rs/minijinja
- Handlebars-rs documentation: https://docs.rs/handlebars
- Ramhorns documentation: https://docs.rs/ramhorns
- cargo-binstall: https://github.com/cargo-bins/cargo-binstall
- cargo-dist: https://github.com/axodotdev/cargo-dist
- cross-rs (cross compilation): https://github.com/cross-rs/cross
