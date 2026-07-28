# AI Context

## Project Summary

This repository builds static BSC Quant/Strategic Research reports. Preserve the institutional report format unless the user explicitly asks for a redesign. Web, Print/PDF, and Share-card outputs must stay visually consistent.

## Source Of Truth

- Report content: `data/report-data.json`
- Theme/global tokens: `config/theme.json`
- Data-source registry: `config/data-sources.json`
- Python package: `src/bsc_quant_research/`
- Report assets: `src/report_assets/`
- Generated output: `dist/`

Do not treat `dist/` as source. Update source files and rebuild.

## Architecture

```text
config/data-sources.json
  -> src/bsc_quant_research/providers/
  -> data/generated/report-data.json
  -> src/bsc_quant_research/report/
  -> src/report_assets/
  -> dist/
```

Important modules:

- `src/bsc_quant_research/build.py`: build orchestration.
- `src/bsc_quant_research/providers/merge.py`: deep merge behavior, including ticker-based list merge.
- `src/bsc_quant_research/report/validate.py`: required data checks.
- `src/bsc_quant_research/report/render.py`: HTML assembly and output writes.
- `src/report_assets/styles/`: report, print, share, editor styling.

## Commands To Verify Work

```powershell
python -m pytest
python src/bsc_quant_research/build.py
powershell -ExecutionPolicy Bypass -File scripts/export.ps1
```

Scans:

```powershell
rg "<<<<<<<|=======|>>>>>>>"
rg "##[A-Z_]+##|\{\{[^}]+\}\}" dist
rg "Ã|Ä|Æ|á»|áº|�" data src dist
```

## Style Constraints

- Preserve tables, charts, typography, and text colors from the approved report style unless explicitly requested.
- Prefer global setup changes in `config/theme.json` and shared CSS before component-specific overrides.
- Keep generated output reproducible.
- Avoid broad refactors while making content/style fixes.
- Keep Vietnamese text UTF-8 clean.

## Current Branch Context

Use branch `LL` for continuing development. It already merged the cleaned `main` state and the flattened `gianganh-intheflow-patch-1` pipeline.