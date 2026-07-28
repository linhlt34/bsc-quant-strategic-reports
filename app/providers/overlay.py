from __future__ import annotations

import json
from typing import Any

from .base import BaseProvider, ReportData


class OverlayFileProvider(BaseProvider):
    """Temporary bridge for future MCP/database adapters.

    Today it can read an overlay JSON. Later, replace only this provider's `load`
    implementation with MCP calls or database queries; the renderer remains intact.
    """

    def load(self) -> ReportData:
        relative_path = self.config.get("path")
        if not relative_path:
            return {}
        path = self.project_root / relative_path
        if not path.exists():
            raise FileNotFoundError(
                f"Provider is enabled but overlay file does not exist: {path}"
            )
        with path.open("r", encoding="utf-8-sig") as handle:
            data: dict[str, Any] = json.load(handle)
        return data
