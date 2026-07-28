# Developer Guide

This guide covers the merged `LL` branch after bringing in `gianganh-intheflow-patch-1`. The project now uses a Python rendering pipeline with PowerShell wrappers for Windows.

## Mental Model

The project is a static report generator:

```text
structured data + theme + templates + CSS -> standalone report files
```

There is no server. Build and export are batch commands.

## Main Commands

Windows-friendly build:

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
```

Direct Python build:

```powershell
python app/build.py
```

Export PDF/PNG:

```powershell
powershell -ExecutionPolicy Bypass -File export.ps1
```

Preview:

```powershell
npm run preview
```

## Source Of Truth

Edit these files for durable changes:

- `data/report-data.json`: manual base data.
- `config/data-sources.json`: provider switches.
- `theme.config.json`: brand/design tokens.
- `app/providers/*.py`: data loading and merge behavior.
- `app/report/*.py`: validation, chart rendering, HTML rendering.
- `src/partials/*.html`: report components.
- `src/templates/*.html`: target HTML shells.
- `src/styles/*.css`: visual styling.
- `src/scripts/editor.js`: inline editor behavior.

Generated files:

- `data/generated/*.json`
- `dist/*`

Generated files may be committed when the workflow expects generated artifacts in Git, but they should not be the only place a fix is made.

## Build Flow By File

`build.ps1`

- Windows entry point.
- Locates `python` or `py`.
- Runs `app/build.py`.

`app/build.py`

- loads `theme.config.json`.
- resolves report data through providers.
- validates report data.
- writes `data/generated/report-data.json` and `data/generated/data-lineage.json`.
- calls renderer to write target HTML.

`app/providers/registry.py`

- reads `config/data-sources.json`.
- loads manual base data.
- optionally applies Fiin overlay.
- optionally applies BSC overlay.
- optionally applies manual overrides.

`app/providers/merge.py`

- deep merges dictionaries.
- merges lists with `ticker` by ticker.
- replaces order-sensitive lists such as chart and heatmap where appropriate.

`app/report/validate.py`

- guards data shape and business rules before rendering.

`app/report/render.py`

- renders dynamic HTML fragments.
- reads partials, templates, CSS, editor JS.
- writes `web.html`, `print.html`, and `share.html`.

`export.ps1`

- reads `data/generated/report-data.json`.
- uses Microsoft Edge headless.
- exports `print.pdf` and `share.png`.

## Provider System

Provider config lives at:

```text
config/data-sources.json
```

Default mode:

```json
{
  "mode": "manual",
  "baseProvider": "manual",
  "providers": {
    "manual": { "enabled": true, "path": "data/report-data.json" },
    "fiin": { "enabled": false, "adapter": "overlay_file", "path": "data/raw/fiin-overlay.json" },
    "bsc": { "enabled": false, "adapter": "overlay_file", "path": "data/raw/bsc-overlay.json" }
  },
  "overrides": { "enabled": false, "path": "data/overrides/manual-overrides.json" }
}
```

Use this order for future data automation:

```text
manual base -> external overlays -> manual overrides
```

Keep renderer code independent from databases or MCP connections. Add adapters under `app/providers/` instead.

## Adding A New Data Field

1. Add the field to `data/report-data.json`.
2. Add schema/validation logic if the field is required.
3. Add render logic in `app/report/render.py`.
4. Add token/markup to a partial or template.
5. Run build.
6. Check for unresolved tokens.

Useful check:

```powershell
rg "##[A-Z_]+##|\{\{[^}]+\}\}" dist src
```

## Visual Development

Main CSS lives in:

```text
src/styles/report.css
src/styles/print.css
src/styles/share.css
src/styles/editor.css
```

Guidelines:

- preserve report density and PDF readability.
- keep table and card dimensions stable.
- keep chart labels readable.
- keep Web and Print aligned because they share `src/templates/report.html`.
- use `theme.config.json` for broad token changes.

## Quality Checks

Before pushing `LL`:

```powershell
python app/build.py
powershell -ExecutionPolicy Bypass -File export.ps1
rg "##[A-Z_]+##|\{\{[^}]+\}\}" dist
rg "Ã|Ä|Æ|á»|áº|�" data src dist
```

Check branch:

```powershell
git status
git diff --stat main..LL
```

## Git Workflow

Develop on `LL`:

```powershell
git checkout LL
git status
```

Push `LL` after commits:

```powershell
git push -u origin LL
```

Merge back only after generated outputs are reviewed:

```text
LL -> main
```