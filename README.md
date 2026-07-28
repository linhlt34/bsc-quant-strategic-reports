# BSC Quant Strategic Reports

Config-driven report system for BSC Quant/Strategic Research. The project builds a self-contained investment strategy report in three targets:

- `web.html` for browser review and inline editing.
- `print.html` for A4 PDF export.
- `share.html` plus `share.png` for social/share cards.

The current working branch is intended to continue development on `LL` before merging back to `main`.

## Current Context

This repository has recently been cleaned after an accidental nested upload:

- `main` is the clean production-style branch.
- `gianganh-intheflow-patch-1` contains a flattened experimental/project-structure branch that introduced `app/`, `config/`, `tests/`, `src/styles/`, and `src/scripts/`.
- `LL` is the active development branch created from `main` for continuing work safely before merging back.

Important: the current `LL` branch follows the PowerShell build pipeline, not the Python `app/` pipeline from `gianganh-intheflow-patch-1` unless that work is intentionally merged later.

## What This Project Produces

Build output is written to:

```text
dist/
  index-web.html
  web.html
  print.html
  print.pdf
  share.html
  share.png
  BSC-QUANT-YYYY-MM/
    web.html
    print.html
    print.pdf
    share.html
    share.png
```

The source of truth is not `dist/`. Treat `dist/` as generated output. Edit `data/`, `theme.config.json`, `src/partials/`, `src/templates/`, and the build/export scripts instead.

## Quick Start

From the repository root:

```powershell
cd "D:\Documents\Dev\Strategic Market report\bsc-quant-research"
npm run build
npm run export
```

Equivalent direct commands:

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
powershell -ExecutionPolicy Bypass -File export.ps1
```

Preview the latest web report:

```powershell
npm run preview
```

`export.ps1` uses Microsoft Edge headless to generate the PDF and share PNG.

## Repository Structure

```text
assets/
  fonts/                  Self-hosted Nunito font files used by build.ps1
  img/logo.svg            BSC logo, embedded as base64 at build time

data/
  report-data.json        Main report content and numbers
  schema.json             Intended data shape reference
  report-data.json.bak    Backup data file, not the primary source

dist/
  Generated HTML/PDF/PNG outputs

references/
  BSC_Quant_Research_editable_saved.html
                           Visual reference/source-of-truth for approved format

scripts/
  download-fonts.ps1      Helper to fetch/update font assets

src/partials/
  topbar.html
  hero.html
  rec-table.html
  rec-table-row.html
  chart.html
  heatmap.html
  stock-cards.html
  stock-card-item.html
  share-stock-card-item.html
  footer.html

src/templates/
  web.html                Browser/editable target template
  print.html              A4/PDF target template
  share.html              Share-card target template
  share-css.css           Share-card CSS based on the approved visual format

theme.config.json         Global design tokens
build.ps1                 Build pipeline: data + tokens + partials -> HTML
export.ps1                Export pipeline: print.html -> PDF, share.html -> PNG
package.json              Convenience scripts
```

## Build Pipeline

`build.ps1` is the main renderer.

High-level flow:

1. Read `theme.config.json` and `data/report-data.json`.
2. Validate key data rules:
   - `meta.docCode` must match `BSC-QUANT-YYYY-MM`.
   - type scale sizes must be `>= 12px`.
   - `shareCard.topPicks` must exist in recommendations.
   - recommendation weights must total `100`.
3. Inline assets:
   - Nunito fonts from `assets/fonts/*.woff2`.
   - BSC logo from `assets/img/logo.png` or `assets/img/logo.svg`.
   - QR SVG from `shareCard.ctaUrl`, with offline fallback.
4. Render dynamic fragments:
   - fact chips
   - hero stats
   - recommendation table rows
   - chart SVG fragments
   - heatmap rows
   - stock cards
   - share stock cards
   - contact/footer blocks
5. Compile target templates:
   - `src/templates/web.html`
   - `src/templates/print.html`
   - `src/templates/share.html`
6. Write generated files into `dist/<docCode>/` and root `dist/` shortcuts.

## Export Pipeline

`export.ps1` expects build output to already exist.

It does the following:

1. Finds Microsoft Edge.
2. Copies generated HTML files to a temp directory without spaces.
3. Exports `print.html` to `print.pdf` with A4 settings.
4. Checks PDF page count against `data.meta.pageCount`.
5. Captures `share.html` as `share.png` at `1200x1500`.
6. Copies final artifacts to both `dist/<docCode>/` and shortcut files in `dist/`.

If Edge fails inside a sandbox, run the export in a normal local terminal.

## Data Editing

Most report updates should start in `data/report-data.json`.

Common fields:

- `meta`: report title, period, doc code, issue date, page count.
- `topbar`: brand and meta labels.
- `hero`: title, lede, chips, hero stats.
- `recTable.rows`: recommendation rows and weights.
- `chart`: daily performance labels and series.
- `heatmap`: monthly performance table.
- `stockCards`: card-level metrics by ticker.
- `contacts`: footer contact details.
- `legalText`: long disclaimer HTML.
- `shareCard`: share-card metadata, CTA URL, top picks.

After changing data:

```powershell
npm run build
npm run export
```

## Design And Format Rules

The approved visual reference is:

```text
references/BSC_Quant_Research_editable_saved.html
```

The goal is to keep table, chart, font, color, and text treatment consistent with that file. Only global spacing and font sizing should be changed through `theme.config.json` unless the design intentionally changes.

Design token rules:

- Use `theme.config.json` for global colors, type scale, spacing, and radius.
- Do not set font sizes below `12px`; the build fails this validation.
- Keep Nunito as the report font unless the brand decision changes.
- Keep BSC blue as the primary action/heading/ticker color.
- Keep report outputs readable for PDF and browser review.

## Branch Workflow

Recommended daily flow on `LL`:

```powershell
git status
git checkout LL
git pull --rebase origin LL
npm run build
```

If `LL` does not exist on a fresh machine:

```powershell
git fetch origin
git checkout -b LL origin/LL
```

Before merging `LL` into `main`:

```powershell
git status
npm run build
npm run export
git diff --stat main..LL
```

Expected merge direction:

```text
LL -> main
```

Use `gianganh-intheflow-patch-1` as a reference/prototype branch for the alternative Python/module pipeline. Do not mix it into `LL` casually; inspect and cherry-pick intentionally.

## Developer Docs

Detailed developer guide:

```text
docs/DEVELOPER_GUIDE.md
```

AI context guide:

```text
docs/AI_CONTEXT.md
```

Read both before making structural changes.