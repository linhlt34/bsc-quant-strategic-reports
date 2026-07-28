# AI Context Guide

Read this before modifying the repository.

## Project Identity

This is a BSC Quant/Strategic Research static report generator. The output is an institutional financial report with strict visual expectations. It is not a marketing site and not a generic web app.

## Active Branch State

The active development branch is `LL`. It has merged `gianganh-intheflow-patch-1`, so the main architecture is now the Python modular renderer.

Branch meanings:

- `main`: clean baseline branch.
- `LL`: active development branch.
- `gianganh-intheflow-patch-1`: merged source branch that introduced the Python pipeline.

## Architecture

Primary build:

```text
app/build.py
```

Windows wrapper:

```text
build.ps1
```

Export:

```text
export.ps1
```

Key source directories:

```text
app/providers/
app/report/
config/
data/
src/partials/
src/templates/
src/styles/
src/scripts/
```

Generated directories/files:

```text
data/generated/
dist/
```

Do not treat `dist/` as source.

## Critical Requirements

Preserve:

- BSC institutional report style.
- Vietnamese text correctness.
- table/chart/heatmap/card readability.
- PDF page fit.
- share image output at `1200x1500`.
- separation between data providers and renderer.

Renderer must not call databases/MCP directly. External data should enter through providers/overlays.

## Build Flow

```text
config/data-sources.json
  -> app.providers.resolve_report_data
  -> data/generated/report-data.json
  -> app.report.validate.validate_report
  -> app.report.render.render_project
  -> dist/*.html
  -> export.ps1 for PDF/PNG
```

Default data source is `data/report-data.json`.

## Commands

Build:

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
```

or:

```powershell
python app/build.py
```

Export:

```powershell
powershell -ExecutionPolicy Bypass -File export.ps1
```

Verification:

```powershell
rg "##[A-Z_]+##|\{\{[^}]+\}\}" dist
rg "Ã|Ä|Æ|á»|áº|�" data src dist
```

## Editing Rules

Prefer source edits in:

- `data/report-data.json`
- `theme.config.json`
- `app/`
- `src/`
- `config/`

Avoid:

- editing generated `dist` files as the only fix.
- committing `__pycache__`, `.pyc`, temp files, or local browser state.
- deleting user changes.
- using destructive Git commands unless explicitly requested.
- silently switching back to the old PowerShell-only pipeline.

## Visual Context

The project previously used a PowerShell string-replacement pipeline and had an approved visual reference file. After merge, styling is now mainly in `src/styles/report.css`, `src/styles/print.css`, and `src/styles/share.css`.

When asked to keep format, inspect current CSS/templates and preserve the institutional visual character. Prefer token/global changes for spacing and type changes.

## Git Notes

If a merge is in progress, inspect conflicts before resolving. For the merge from `gianganh-intheflow-patch-1` into `LL`, prefer the Python/source architecture and do not keep Python cache artifacts.