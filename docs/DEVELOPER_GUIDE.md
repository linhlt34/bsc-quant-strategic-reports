# Developer Guide

## Purpose

This repo renders a static BSC Quant/Strategic Research report from JSON data. It is not a web app server. The durable source of truth is data + theme + templates + renderer code; `dist/` is generated output.

## Standard Layout

- `src/bsc_quant_research/`: Python package.
- `src/bsc_quant_research/providers/`: load and merge data sources.
- `src/bsc_quant_research/report/`: validate data, render charts, render HTML.
- `src/report_assets/`: static report source assets: partials, templates, styles, scripts, images.
- `config/`: runtime configuration and global design tokens.
- `data/`: report content, raw inputs, overlays, generated resolved data.
- `schemas/`: data contracts.
- `scripts/`: build/export/preview entrypoints.
- `tests/`: pytest-compatible tests.
- `dist/`: generated deliverables.

## Main Commands

```powershell
npm run build
npm run export
npm run preview
python -m pytest
```

Equivalent direct commands:

```powershell
python src/bsc_quant_research/build.py
powershell -ExecutionPolicy Bypass -File scripts/build.ps1
powershell -ExecutionPolicy Bypass -File scripts/export.ps1
```

## Build Internals

1. `src/bsc_quant_research/build.py` loads `config/theme.json`.
2. `providers/registry.py` reads `config/data-sources.json`.
3. Manual data comes from `data/report-data.json` by default.
4. Optional overlays are merged by `providers/merge.py`.
5. Resolved data is written to `data/generated/report-data.json`.
6. `report/validate.py` checks required report sections.
7. `report/render.py` combines data with `src/report_assets/` and writes HTML to `dist/`.
8. `scripts/export.ps1` uses Microsoft Edge headless to create PDF/PNG.

## Editing Guide

- Add or fix report text in `data/report-data.json`.
- Add a new data provider under `src/bsc_quant_research/providers/` and register it in `registry.py`.
- Add a new visual section by updating data, validation, renderer logic, and a partial under `src/report_assets/partials/`.
- Keep global spacing/type/color tokens in `config/theme.json` and shared CSS in `src/report_assets/styles/`.
- Do not patch generated HTML in `dist/`; rebuild from source.

## Output Policy

`dist/` is generated but intentionally kept in the repository for easy sharing and review. Any committed output must be reproducible from current source by running build/export.

## Pre-Merge Checklist

```powershell
python -m pytest
npm run build
npm run export
rg "<<<<<<<|=======|>>>>>>>"
rg "##[A-Z_]+##|\{\{[^}]+\}\}" dist
```

If Vietnamese text looks broken, scan with:

```powershell
rg "Ã|Ä|Æ|á»|áº|�" data src dist
```