# BSC Quant Strategic Reports

Static report renderer for BSC Quant/Strategic Research. The project builds Web, Print/PDF, and Share-card outputs from structured JSON data, reusable HTML partials, controlled CSS, and a small Python renderer.

## Current Branch

Active development branch: `LL`.

`LL` already includes the flattened pipeline from `gianganh-intheflow-patch-1` and uses the organized `src/` layout below.

## Repository Layout

```text
bsc-quant-research/
  config/
    data-sources.json          Data provider registry
    theme.json                 Global colors, typography, spacing tokens
  data/
    report-data.json           Manual source data for the current report
    chart-reference.json       Chart/reference data
    generated/                 Resolved data written by build
    raw/                       Raw source drops, if any
    overrides/                 Manual overlays, if any
  dist/                        Generated HTML/PDF/PNG outputs
  docs/
    DEVELOPER_GUIDE.md         Developer workflow and architecture
    AI_CONTEXT.md              Context for AI coding agents
  references/                  Visual/reference notes
  schemas/
    report-data.schema.json    Report data contract
  scripts/
    build.ps1                  Windows build entrypoint
    build.sh                   Unix build entrypoint
    export.ps1                 Edge headless PDF/PNG export
    preview.ps1                Open generated Web HTML
  src/
    bsc_quant_research/        Python package: providers, validation, rendering
    report_assets/             HTML partials/templates, CSS, JS, images
  tests/                       Pytest-compatible smoke and unit tests
  package.json                 Convenience npm scripts
  pyproject.toml               Python project/test metadata
```

## Quick Start

```powershell
cd "D:\Documents\Dev\Strategic Market report\bsc-quant-research"
git checkout LL
git pull
npm run build
npm run export
npm run preview
```

Direct Windows commands:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build.ps1
powershell -ExecutionPolicy Bypass -File scripts/export.ps1
```

Direct Python command:

```powershell
python src/bsc_quant_research/build.py
```

## Build Flow

```text
config/data-sources.json
  -> data/report-data.json + optional overlays/raw sources
  -> src/bsc_quant_research/providers/
  -> data/generated/report-data.json
  -> src/bsc_quant_research/report/
  -> src/report_assets/
  -> dist/*.html
  -> scripts/export.ps1
  -> dist/*.pdf + dist/*.png
```

Treat `dist/` as generated output. Do not edit `dist/*.html` manually as the durable fix. Update `data/`, `config/theme.json`, `src/report_assets/`, or `src/bsc_quant_research/`, then rebuild.

## Where To Change What

- Content and Vietnamese text: `data/report-data.json`
- Data-source behavior: `config/data-sources.json`, `src/bsc_quant_research/providers/`
- Validation/render logic: `src/bsc_quant_research/report/`
- Tables/cards/sections: `src/report_assets/partials/`
- Page shells: `src/report_assets/templates/`
- Fonts, spacing, colors, responsive rules: `config/theme.json`, `src/report_assets/styles/`
- Inline editor behavior: `src/report_assets/scripts/editor.js`
- Export workflow: `scripts/export.ps1`

## Quality Checks

```powershell
python -m pytest
python src/bsc_quant_research/build.py
powershell -ExecutionPolicy Bypass -File scripts/export.ps1
```

Useful scans before merge:

```powershell
rg "<<<<<<<|=======|>>>>>>>"
rg "##[A-Z_]+##|\{\{[^}]+\}\}" dist
rg "Ã|Ä|Æ|á»|áº|�" data src dist
```

## Development Rule

Keep format changes source-driven. Web, Print/PDF, and Share outputs should preserve the same report identity: table/chart structure, typography, and text colors stay controlled by global theme/style files unless the requested change explicitly targets a component.