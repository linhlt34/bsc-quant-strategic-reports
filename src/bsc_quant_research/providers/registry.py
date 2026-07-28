from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .manual import ManualProvider
from .merge import deep_merge
from .overlay import OverlayFileProvider


def _load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def resolve_report_data(project_root: Path) -> tuple[dict[str, Any], dict[str, Any]]:
    config_path = project_root / "config/data-sources.json"
    config = _load_json(config_path)
    providers = config.get("providers", {})

    base_name = config.get("baseProvider", "manual")
    if base_name != "manual":
        raise ValueError("Current baseProvider must be 'manual'. Enrichment providers are optional overlays.")

    manual_cfg = providers.get("manual", {})
    if not manual_cfg.get("enabled", True):
        raise ValueError("The manual base provider cannot be disabled until another base provider is implemented.")

    report = ManualProvider(project_root, manual_cfg).load()
    lineage: dict[str, Any] = {
        "mode": config.get("mode", "manual"),
        "baseProvider": "manual",
        "providersApplied": ["manual"],
    }

    for name in ("fiin", "bsc"):
        provider_cfg = providers.get(name, {})
        if provider_cfg.get("enabled", False):
            overlay = OverlayFileProvider(project_root, provider_cfg).load()
            report = deep_merge(report, overlay)
            lineage["providersApplied"].append(name)

    override_cfg = config.get("overrides", {})
    if override_cfg.get("enabled", False):
        override_path = project_root / override_cfg["path"]
        report = deep_merge(report, _load_json(override_path))
        lineage["providersApplied"].append("manual-overrides")

    return report, lineage
