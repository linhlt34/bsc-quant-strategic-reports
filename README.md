# BSC Quant Strategic Reports

Static report renderer for BSC Quant/Strategic Research. The project produces institutional HTML/PDF/share-card reports from structured JSON data and brand-controlled templates.

The active development branch is `LL`. It has merged the flattened `gianganh-intheflow-patch-1` architecture, so the project now uses the Python modular pipeline as the main renderer. PowerShell scripts remain as Windows-friendly entry points.

## Branch Context

- `main`: clean baseline branch after removing the accidental nested upload folder.
- `gianganh-intheflow-patch-1`: source branch that flattened the uploaded project into root and introduced the modular Python pipeline.
- `LL`: active development branch. Continue work here before merging back to `main`.

Expected merge direction:

```text
LL -> main
```

## Outputs

Build output is written to:

```text
dist/
  index.html
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

Treat `dist/` as generated output. Durable changes belong in `data/`, `config/`, `app/`, `src/`, `theme.config.json`, `build.ps1`, or `export.ps1`.

## Quick Start

From repo root:

```powershell
cd "D:\Documents\Dev\Strategic Market report\bsc-quant-research"
powershell -ExecutionPolicy Bypass -File build.ps1
powershell -ExecutionPolicy Bypass -File export.ps1
```

Alternative if Python is on PATH:

```powershell
python app/build.py
```

NPM shortcuts:

```powershell
npm run build
npm run export
npm run preview
```

Note: `npm run build` calls `python app/build.py`. If Windows cannot find `python`, use `build.ps1`; it also tries the `py -3` launcher.

## Repository Structure

```text
app/
  build.py                 Build orchestration
  providers/               Data providers and merge logic
  report/                  Validation, chart rendering, HTML renderer, utilities

config/
  data-sources.json        Manual/Fiin/BSC provider switches

data/
  report-data.json         Manual base data; current main input
  chart-reference.json     Chart reference data
  raw/                     Future raw/bridge source files
  overrides/               Manual override files
  generated/               Resolved report data and lineage after build

src/
  partials/                Reusable HTML report components
  templates/report.html    Shared Web/Print report template
  templates/share.html     Share-card template
  styles/report.css        Main report styling
  styles/print.css         Print-specific styling
  styles/share.css         Share-card styling
  styles/editor.css        Inline editor styling
  scripts/editor.js        Inline editor behavior

dist/                      Generated HTML/PDF/PNG output
assets/img/logo.svg        BSC logo, embedded by renderer
theme.config.json          Brand tokens, type scale, spacing
build.ps1                  Windows build wrapper around Python renderer
export.ps1                 Edge headless PDF/PNG export
```

## Architecture

The build is data-first and provider-aware:

```text
config/data-sources.json
        |
        v
app.providers.resolve_report_data()
        |
        v
data/generated/report-data.json + data/generated/data-lineage.json
        |
        v
app.report.validate.validate_report()
        |
        v
app.report.render.render_project()
        |
        v
dist/*.html
        |
        v
export.ps1 -> PDF + PNG
```

Current provider order:

```text
Manual base -> Fiin overlay -> BSC overlay -> Manual overrides
```

By default only the manual provider is enabled.

## Data Workflow

For normal report updates, edit:

```text
data/report-data.json
```

Then run:

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
powershell -ExecutionPolicy Bypass -File export.ps1
```

`app/build.py` also writes the resolved data to:

```text
data/generated/report-data.json
data/generated/data-lineage.json
```

These generated files are useful for audit/debugging which providers were applied.

## Validation Rules

`app/report/validate.py` currently checks:

- `meta.docCode` matches `BSC-QUANT-YYYY-MM`.
- recommendation tickers are unique.
- recommendation weights sum to `100`.
- each recommendation ticker has a matching stock card.
- chart labels, portfolio values, and VN-Index values have equal length.
- share top picks are known tickers.
- theme type sizes are valid and not below the safety floor.

## Visual Rules

This is a financial report, not a generic landing page. Preserve institutional layout and readability.

Key design anchors:

- Nunito font family.
- BSC blue as primary heading/ticker/action color.
- table, chart, heatmap, and card treatments in `src/styles/report.css`.
- Web and Print use the same `src/templates/report.html`.
- Share card is separate through `src/templates/share.html` and `src/styles/share.css`.

Do not edit generated `dist/*.html` as the durable fix. Update source templates, styles, data, or renderer code instead.

## Inline Editor

`dist/index.html` includes inline editing:

- toggle edit mode
- edit `[data-edit]` elements
- save to localStorage
- reset local browser state

Inline edits are browser-local only. To make changes permanent, update `data/report-data.json` and rebuild.

## Developer Docs

- `docs/DEVELOPER_GUIDE.md`: practical development workflow.
- `docs/AI_CONTEXT.md`: project context and guardrails for AI coding agents.

Read these before making structural changes.