from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .base import BaseProvider, ReportData


class ManualProvider(BaseProvider):
    def load(self) -> ReportData:
        relative_path = self.config.get("path", "data/report-data.json")
        path = self.project_root / relative_path
        if not path.exists():
            raise FileNotFoundError(f"Manual data file not found: {path}")
        with path.open("r", encoding="utf-8-sig") as handle:
            data: dict[str, Any] = json.load(handle)
        return data
