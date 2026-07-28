# AI Context

## Project Summary

This repo builds static BSC Quant/Strategic Research reports. The user cares strongly that Web, Share, and PDF preserve the approved report format: tables, charts, fonts, and text colors should stay consistent unless explicitly changed.

## Folder Model

- `data/`: editable report content.
- `config/`: global setup, including theme tokens.
- `app/`: Python build/render engine.
- `report/`: source assets for the report format.
- `scripts/`: terminal commands for build/export/preview.
- `dist/`: generated deliverables.

## Build Flow

```text
config/data-sources.json
  -> data/report-data.json
  -> app/providers/
  -> data/generated/report-data.json
  -> app/report/
  -> report/
  -> dist/
```

## Important Files

- `app/build.py`: build orchestration.
- `app/providers/merge.py`: deep merge behavior, including ticker-based list merge.
- `app/report/validate.py`: required data checks.
- `app/report/render.py`: HTML assembly.
- `config/theme.json`: global color/type/spacing/radius tokens.
- `report/styles/`: CSS for report, print, share, editor.
- `report/templates/`: output shells.
- `report/partials/`: reusable HTML sections.

## Verify Changes

```powershell
python -m pytest
python app/build.py
powershell -ExecutionPolicy Bypass -File scripts/export.ps1
```

Scans:

```powershell
rg "^(<<<<<<<|=======|>>>>>>>)"
rg "##[A-Z_]+##|\{\{[^}]+\}\}" dist
```

## Guardrails

- Do not treat `dist/` as source.
- Keep durable fixes in `data/`, `config/`, `app/`, or `report/`.
- Prefer global token/style changes before component-specific overrides.
- Keep Vietnamese text UTF-8 clean.
