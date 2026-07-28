# BSC Quant Strategic Reports

Static report renderer for BSC Quant/Strategic Research. The repo is organized around four simple ideas: data, report format, build engine, and command scripts.

## Folder Logic

```text
bsc-quant-research/
  app/                         Python build engine
    build.py                   Main build entrypoint
    providers/                 Load and merge data sources
    report/                    Validate data, render charts, render HTML
  report/                      Report source format
    images/                    Logo and report images
    partials/                  Reusable HTML sections
    templates/                 Page shells for web/print/share
    styles/                    CSS for web, print, share, editor
    js/                        Browser-side editor JavaScript
  scripts/                     Terminal commands and automation
    build.ps1                  Windows build command
    build.sh                   Unix build command
    export.ps1                 Export PDF/PNG using Edge headless
    preview.ps1                Open generated web report
  config/                      Global setup
    data-sources.json          Data provider registry
    theme.json                 Colors, type scale, spacing, radius
  data/                        Report content and resolved data
    report-data.json           Main editable report data
    chart-reference.json       Chart/reference data
    generated/                 Build output data snapshots
    raw/                       Raw source drops
    overrides/                 Manual overlays
  schemas/                     Data contracts
  docs/                        Developer and AI documentation
  references/                  Visual references and notes
  tests/                       Pytest checks
  dist/                        Generated deliverables only: web.html, print.html, share.html, print.pdf, share.png
```

Why `scripts/` and `report/js/` are separate:

- `scripts/` runs on your computer from terminal: build, export, preview.
- `report/js/` runs inside the browser after the HTML is opened.

## Quick Start

```powershell
cd "D:\Documents\Dev\Strategic Market report\bsc-quant-research"
git checkout LL
git pull
python app/build.py
powershell -ExecutionPolicy Bypass -File scripts/export.ps1
```

Convenience commands:

```powershell
npm run build
npm run export
npm run preview
```

## Build Flow

```text
config/data-sources.json
  -> data/report-data.json
  -> app/providers/
  -> data/generated/report-data.json
  -> app/report/
  -> report/templates + report/partials + report/styles + report/js
  -> dist/web.html + dist/print.html + dist/share.html
  -> scripts/export.ps1
  -> dist/print.pdf + dist/share.png
```

## Where To Edit

- Report text/content: `data/report-data.json`
- Global font, spacing, color setup: `config/theme.json`
- Table/card/section HTML: `report/partials/`
- Page layout shells: `report/templates/`
- Web/print/share CSS: `report/styles/`
- Browser editor behavior: `report/js/editor.js`
- Build/render logic: `app/`
- Export/preview commands: `scripts/`

Do not edit `dist/*.html` as the long-term fix. `dist/` is generated for sharing and review, and should only contain `web.html`, `print.html`, `share.html`, `print.pdf`, and `share.png`.

## Checks

```powershell
python -m pytest
python app/build.py
powershell -ExecutionPolicy Bypass -File scripts/export.ps1
```

Useful scans:

```powershell
rg "^(<<<<<<<|=======|>>>>>>>)"
rg "##[A-Z_]+##|\{\{[^}]+\}\}" dist
```
