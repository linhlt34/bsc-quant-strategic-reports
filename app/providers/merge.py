from __future__ import annotations

from copy import deepcopy
from typing import Any


def _is_ticker_list(value: Any) -> bool:
    return (
        isinstance(value, list)
        and all(isinstance(item, dict) and "ticker" in item for item in value)
    )


def deep_merge(base: Any, overlay: Any) -> Any:
    """Merge report data without silently losing ticker records.

    Dictionaries merge recursively. Lists containing ticker objects merge by ticker.
    Other lists are replaced because order is meaningful for charts and heatmaps.
    """
    if isinstance(base, dict) and isinstance(overlay, dict):
        result = deepcopy(base)
        for key, value in overlay.items():
            result[key] = deep_merge(result[key], value) if key in result else deepcopy(value)
        return result

    if _is_ticker_list(base) and _is_ticker_list(overlay):
        overlay_map = {item["ticker"]: item for item in overlay}
        result = []
        seen: set[str] = set()
        for item in base:
            ticker = item["ticker"]
            seen.add(ticker)
            result.append(deep_merge(item, overlay_map[ticker]) if ticker in overlay_map else deepcopy(item))
        result.extend(deepcopy(item) for ticker, item in overlay_map.items() if ticker not in seen)
        return result

    return deepcopy(overlay)
