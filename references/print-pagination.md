# Print Pagination Reference

> Companion to `skills/convert-htmx-pdf`. Everything here is about the gap between a page
> that looks right in a browser and a document that reads right on paper.

A branded HTML artifact is authored as one continuous surface. A PDF is a sequence of
fixed rectangles. Pagination is the translation, and it is where the conversion either
holds or falls apart.

Three rules govern all of it:

1. **The renderer owns margins.** `@page` declares `size`, nothing else.
2. **Components stay whole.** A callout split across a page boundary reads as a defect.
3. **Forced breaks are structural, not decorative.** One per genuine division, no more.

---

## 1. The `@page` rule — size only

```css
@media print {
  @page { size: Letter portrait; }   /* ✓ */
}
```

```css
@media print {
  @page { size: Letter portrait; margin: 0.55in 0.6in; }   /* ✗ */
}
```

The second form silently overrides the margins passed to Chromium's `page.pdf()`. When a
running header is enabled it draws in the margin box — so with `margin: 0` the body text
starts at y=0 and the header prints *through* the first line of every page.

The symptom looks like a header bug. It is a CSS precedence bug, and it is the single most
expensive mistake in this pipeline because it is invisible until you rasterize a page and
look at it.

`convert-htmx-pdf.mjs` strips `margin` from `@page` during preflight and warns. If you are
building the PDF by hand, do it yourself.

---

## 2. The baseline stylesheet

Injected automatically unless `--no-inject-print-css`. Reproduced here so it can be
adapted for artifacts that need to diverge.

```css
@media print {
  html, body {
    background: #fff !important;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;      /* without this Chromium strips brand backgrounds */
  }

  /* Fixed chrome either repeats on every page or collides with the header. */
  nav, .nav, .sidebar, .toc, [class*="sticky"] { display: none !important; }

  /* Collapse the page shell to one column. */
  .page-body { display: block !important; grid-template-columns: 1fr !important; }
  .main      { padding: 0 !important; max-width: 100% !important; }

  /* Keep components whole. */
  .callout, .quote, .card, .phase, figure, .diagram,
  .tbl-wrap, table, pre, blockquote, li { break-inside: avoid; }
  tr, thead  { break-inside: avoid; }
  thead      { display: table-header-group; }   /* repeat header on long tables */

  /* A heading must never be the last thing on a page. */
  h1, h2, h3, h4, .section-header { break-after: avoid; break-inside: avoid; }

  p, li { orphans: 3; widows: 3; }

  a { color: inherit; text-decoration: none; }
  img, svg { max-width: 100% !important; height: auto !important; }
}
```

`break-inside: avoid` is the highest-leverage line in the file. Apply it to every container
that reads as a unit. The failure it prevents — a bordered callout whose top half sits on
page 4 and bottom half on page 5 — is the one readers notice first.

---

## 3. Break placement

The baseline inserts no breaks. Add them per artifact, in `--print-css` or the artifact's
own print block, and add as few as possible.

### The mistake

```css
/* ✗ every section on a fresh page */
#s1, #s2, #s3, #s4, #s5, #s6, #s7, #s8, #s9, #s10, #s11 { break-before: page; }
```

This looks tidy and produces a document full of near-empty pages. Wherever a section ends
in the top third of a page, the next forced break leaves the rest blank. On an
18-page document this reliably yields three or four pages carrying under a hundred words.

### The correction

```css
/* ✓ structural boundaries only */
#s1, #s7, #manifest { break-before: page; }

/* everything else flows, with generous separation */
.section  { margin-top: 1.6rem; }
```

Reserve forced breaks for: the cover, the first content section, a section whose content
must occupy a full page (a large diagram), and back matter. Everything else flows and the
`break-inside`/`break-after` rules keep it readable.

**Verification catches this.** Word count per page, excluding first and last; anything
under ~40 words is an orphan. The renderer reports it.

### Giving a diagram its own page

```css
#architecture .diagram {
  break-inside: avoid;
  max-height: 7.4in;     /* Letter minus margins and the caption */
}
#architecture { break-before: page; }
```

Note what is *not* here: `break-after: page` on the diagram. Adding it produces a page
containing the section heading and nothing else, because the section already broke.

---

## 4. The cover page

A short hero followed by `break-after: page` leaves most of page 1 blank, which reads as
an accident rather than a decision. Make it deliberate — fill the page and anchor the
metadata to the bottom.

```css
@media print {
  .hero-wrap { break-after: page; border: none; background: #fff; }

  .hero {
    min-height: 9.05in;             /* Letter minus the renderer's margins */
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
    padding: 0;
  }
  .hero > div:first-child { padding-top: 2.1in; }   /* optical centering, not true centering */

  .hero h1  { font-size: 34pt; line-height: 1.06; }
  .hero-sub { font-size: 12.4pt; max-width: 100%; }

  .hero-meta {
    margin-top: auto;               /* pushes the block to the bottom */
    padding-top: 1.1rem;
    border-top: 2px solid var(--brand);
    flex-direction: row;
    gap: 2.1rem;
  }
}
```

`margin-top: auto` inside a flex column is what does the work. The title sits high, the
metadata rule sits on the baseline, and the white space between them is obviously
intentional.

---

## 5. Header and footer templates

Chromium draws these in the page margin on every page, via `headerTemplate` and
`footerTemplate`. They are not part of the document flow, so they never displace content
and never need `position: fixed`.

```js
const bar = (left, right) => `
<div style="font-family:-apple-system,'Segoe UI',Helvetica,Arial,sans-serif;
            width:100%;padding:0 0.62in;font-size:6.6pt;color:#9A9A9A;
            display:flex;justify-content:space-between;align-items:baseline;">
  <span>${left}</span><span>${right}</span>
</div>`;

await page.pdf({
  displayHeaderFooter: true,
  headerTemplate: bar('<b style="color:#0B5563">Acme</b> · Q3 Report', 'DOC-001'),
  footerTemplate: bar('Prepared by A. Author · 28 July 2026',
                      '<span class="pageNumber"></span> / <span class="totalPages"></span>'),
  margin: { top: '0.72in', bottom: '0.62in', left: '0.62in', right: '0.62in' },
});
```

Four constraints, each learned the hard way:

| Constraint | Why |
|---|---|
| **System fonts only** | Templates render in a separate document that does not inherit the page's `@font-face` rules. A branded font silently falls back, and the mismatch shows. |
| **Inline styles only** | No stylesheet is applied to the template. |
| **Top margin ≥ 0.7in** | The header needs room. Below that it clips or overlaps. |
| **`pageNumber` / `totalPages` are the only tokens** | Chromium substitutes these two classes and nothing else. |

`prefer_css_page_size: false` keeps `@page` from reclaiming control of the geometry.

---

## 6. Font embedding

An external font is a render-time dependency. If it fails to load — offline machine,
blocked domain, rate limit — Chromium substitutes, glyph widths change, line breaks move,
and pagination shifts. The PDF stops matching the artifact and nothing in the output says so.

Embed. The pipeline does this automatically; the manual version:

```js
// 1. fetch the Google Fonts CSS with a browser UA (it serves woff2 only to real browsers)
const css = await (await fetch(href, { headers: { 'User-Agent': UA } })).text();

// 2. keep only Latin / Latin-Ext subsets — the rest is dead weight
const blocks = css.match(/@font-face\s*\{[^}]*\}/g).filter(b => {
  const r = /unicode-range:\s*([^;]+);/.exec(b);
  return !r || r[1].includes('U+0000-00FF') || /U\+0100-02/.test(r[1]);
});

// 3. inline each woff2 as a data: URI, replace the <link> with a <style>
```

Filtering matters. Inter + Roboto Slab + JetBrains Mono unfiltered is 74 `@font-face`
blocks and roughly 4 MB; filtered to Latin it is 22 blocks and ~1.4 MB, with identical
rendering for Latin text.

Verify with `pdffonts output.pdf` — every row should read `emb: yes`.

> Chromium's Skia writer often emits **Type 3** fonts for variable-font instances. That is
> normal and the text stays selectable and searchable. Confirm with `pdftotext`.

---

## 7. The verification loop

Never declare a PDF finished without looking at it. Four checks, all cheap.

```bash
# structure
pdfinfo out.pdf | grep -E 'Pages|Page size'

# content preservation — catches clipping
pdftotext out.pdf - | wc -w

# page density — catches orphan pages from forced breaks
N=$(pdfinfo out.pdf | awk '/^Pages/{print $2}')
for i in $(seq 1 "$N"); do
  printf '%s:%s ' "$i" "$(pdftotext -f "$i" -l "$i" out.pdf - | wc -w)"
done; echo

# fonts — catches silent substitution
pdffonts out.pdf
```

Then rasterize and **look at it**:

```bash
pdftoppm -png -r 90 -f 1 -l 1 out.pdf page
```

Density numbers catch structural faults. They do not catch a diagram rendering at the
wrong scale, a color that went muddy, or a table that overflowed its column. Only your
eyes catch those.

---

## 8. Failure catalogue

| Symptom | Cause | Fix |
|---|---|---|
| Header overlaps the first line on every page | `@page { margin: … }` overriding the renderer | `@page` declares `size` only |
| A page holds a heading and nothing else | `break-before: page` on a section whose predecessor ended early | Restrict forced breaks to structural boundaries |
| A callout or table splits across pages | Missing `break-inside: avoid` | Add it to every container that reads as a unit |
| Long table loses its header after page 1 | Missing `thead { display: table-header-group }` | Add it |
| Brand backgrounds print white | `printBackground` off, or `print-color-adjust` unset | Set both |
| Type looks subtly wrong; line breaks differ from the browser | Font substituted | Embed fonts; verify with `pdffonts` |
| PDF has no selectable text | Content rendered as images | Check that fonts loaded and the page is not a canvas |
| Diagram clipped at the page edge | SVG with a fixed width larger than the content box | `max-width: 100%; height: auto; max-height: <page height minus margins>` |
| Sidebar or nav appears on every page | Fixed/sticky element not hidden in print | Hide it in the print block |
| Page 1 is mostly blank | Short hero plus `break-after: page` | Use the cover recipe in §4 |
