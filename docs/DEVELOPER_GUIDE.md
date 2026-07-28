# Developer Guide

This guide explains how to develop the current PowerShell-based report system on branch `LL`.

## Mental Model

The project is a static report generator. It does not run a backend service. The build script takes structured JSON plus HTML partials and CSS, then produces standalone HTML files and export-ready assets.

Main development loop:

```text
Edit source -> build HTML -> review browser/PDF/share -> commit source + generated outputs if needed
```

## Source Of Truth

Use these as source files:

- `data/report-data.json` for content and numbers.
- `theme.config.json` for global visual tokens.
- `src/partials/*.html` for reusable report sections.
- `src/templates/*.html` for target-level HTML shells.
- `src/templates/share-css.css` for share output styling.
- `build.ps1` for render logic.
- `export.ps1` for PDF/PNG generation.

Generated files live in `dist/`. Do not edit generated HTML manually unless the task is specifically to inspect or patch a one-off output. Durable fixes belong in source files.

## Build Targets

### Web target

Source: `src/templates/web.html`

Output:

```text
dist/<docCode>/web.html
dist/web.html
dist/index-web.html
```

Purpose:

- browser review
- inline editing workflow
- easy local preview

### Print target

Source: `src/templates/print.html`

Output:

```text
dist/<docCode>/print.html
dist/print.html
dist/<docCode>/print.pdf
dist/print.pdf
```

Purpose:

- A4 print layout
- PDF generation through Edge headless

### Share target

Source: `src/templates/share.html` and `src/templates/share-css.css`

Output:

```text
dist/<docCode>/share.html
dist/share.html
dist/<docCode>/share.png
dist/share.png
```

Purpose:

- social/share card
- fixed screenshot size `1200x1500`

## How Rendering Works

`build.ps1` performs mostly string replacement. That means token names matter.

Common token styles:

```text
{{ meta.reportTitle }}
{{ hero.title }}
##PARTIAL_HERO##
##THEME_FONTS##
##THEME_CSS_VARIABLES##
##TABLE_ROWS##
```

When adding a new field:

1. Add the field to `data/report-data.json`.
2. Add validation in `build.ps1` if the field is required or risky.
3. Add replacement logic in the partial compilation section.
4. Add the token to the relevant partial/template.
5. Run `npm run build`.
6. Search for unresolved tokens:

```powershell
rg "##|{{" dist src
```

## Data Rules

Current build validation checks:

- `meta.docCode` format: `BSC-QUANT-YYYY-MM`.
- every type scale size in `theme.config.json` must be at least `12px`.
- `shareCard.topPicks` must be a subset of recommendation tickers.
- recommendation weights must sum to `100`.

Recommended extra checks before merge:

- no mojibake in Vietnamese text: search for `Ã`, `Ä`, `Æ`, `á»`, `áº`, `�`.
- no unresolved tokens in `dist`.
- PDF page count matches `data.meta.pageCount`.
- share image is `1200x1500`.

Useful commands:

```powershell
rg "Ã|Ä|Æ|á»|áº|�" data src dist
rg "##[A-Z_]+##|\{\{[^}]+\}\}" dist
```

## Visual Change Policy

The approved format is anchored by:

```text
references/BSC_Quant_Research_editable_saved.html
```

When asked to preserve format:

- preserve table widths, chart treatment, font family, brand colors, text colors, badges, card structure.
- use `theme.config.json` for global spacing and type size changes.
- avoid local one-off CSS overrides unless they are fixing a target-specific export issue.
- keep web/share/print visually aligned.

## Export Notes

`export.ps1` uses Edge headless. It may require normal local execution outside restricted sandboxes.

Expected checks after export:

```powershell
# PDF page count quick check
$bytes=[IO.File]::ReadAllBytes((Join-Path $PWD 'dist/BSC-QUANT-2026-07/print.pdf'))
$txt=[Text.Encoding]::ASCII.GetString($bytes)
([regex]::Matches($txt,'/Type\s*/Page\b')).Count

# Share image size
Add-Type -AssemblyName System.Drawing
$img=[Drawing.Image]::FromFile((Join-Path $PWD 'dist/BSC-QUANT-2026-07/share.png'))
'{0}x{1}' -f $img.Width,$img.Height
$img.Dispose()
```

## Git Workflow

Work on `LL` for development.

Before starting:

```powershell
git status
git checkout LL
git pull --rebase origin LL
```

Before pushing:

```powershell
npm run build
npm run export
git status
git diff --stat
git add README.md docs data src theme.config.json build.ps1 export.ps1 dist
git commit -m "Describe the change"
git push origin LL
```

Only merge into `main` after reviewing generated outputs.

## Known Branch Context

`gianganh-intheflow-patch-1` is not just a small feature branch. It contains a larger architecture experiment with Python modules:

```text
app/
config/
tests/
src/styles/
src/scripts/
```

That branch can be useful as a blueprint for a future refactor. Until the team decides to migrate, keep `LL` development aligned with the current PowerShell pipeline.