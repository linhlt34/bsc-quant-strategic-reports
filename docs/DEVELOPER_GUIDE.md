# Developer Guide

## Mental Model

The project has four working areas:

- `data/`: what the report says.
- `report/`: how the report looks.
- `app/`: how data becomes HTML.
- `scripts/`: commands that run the workflow.

This keeps source code, visual format, and terminal automation separate.

## Main Commands

```powershell
python app/build.py
python -m pytest
powershell -ExecutionPolicy Bypass -File scripts/build.ps1
powershell -ExecutionPolicy Bypass -File scripts/export.ps1
```

## Build Internals

1. `app/build.py` loads `config/theme.json`.
2. `app/providers/registry.py` reads `config/data-sources.json`.
3. Manual content comes from `data/report-data.json`.
4. Optional overlays are merged by `app/providers/merge.py`.
5. Resolved data is written to `data/generated/report-data.json`.
6. `app/report/validate.py` checks required sections.
7. `app/report/render.py` combines data with `report/` assets and writes `dist/web.html`, `dist/print.html`, and `dist/share.html`.
8. `scripts/export.ps1` exports `dist/print.pdf` and `dist/share.png` using Microsoft Edge headless.

## Folder Responsibilities

- `app/providers/`: data adapters and merge rules.
- `app/report/`: validation, chart rendering, HTML assembly.
- `report/partials/`: reusable section fragments.
- `report/templates/`: web/print/share shells.
- `report/styles/`: CSS by output mode.
- `report/js/`: browser-only JavaScript.
- `scripts/`: shell/PowerShell workflow commands.
- `schemas/`: data contracts.

## Editing Rules

- Keep global spacing/type/color changes in `config/theme.json` or shared CSS.
- Preserve table, chart, font, and text-color behavior unless the requested change is specifically visual.
- Fix Vietnamese text in `data/`, `report/`, or `app/`, then rebuild.
- Do not patch generated files in `dist/` manually. The folder should only contain `web.html`, `print.html`, `share.html`, `print.pdf`, and `share.png`.

## Pre-Merge Checklist

```powershell
python -m pytest
python app/build.py
powershell -ExecutionPolicy Bypass -File scripts/export.ps1
rg "^(<<<<<<<|=======|>>>>>>>)"
rg "##[A-Z_]+##|\{\{[^}]+\}\}" dist
```
