from __future__ import annotations

import base64
import html
import json
import math
import re
from pathlib import Path
from typing import Any


def escape(value: Any) -> str:
    return html.escape("" if value is None else str(value), quote=True)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig")


def write_text(path: Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding="utf-8")


def data_uri(path: Path) -> str:
    mime = "image/svg+xml" if path.suffix.lower() == ".svg" else "image/png"
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:{mime};base64,{encoded}"


def replace_tokens(template: str, values: dict[str, Any]) -> str:
    output = template
    for key, value in values.items():
        output = output.replace(key, str(value))
    return output


def assert_no_tokens(text: str, target: str) -> None:
    unresolved = sorted(set(re.findall(r"##[A-Z0-9_]+##|\{\{[^{}]+\}\}", text)))
    if unresolved:
        raise ValueError(f"Unresolved placeholders in {target}: {', '.join(unresolved[:20])}")


def css_vars(theme: dict[str, Any]) -> str:
    c = theme["colors"]
    ts = theme["typeScale"]
    spacing = theme["spacing"]
    return f""":root {{
  --bsc-blue: {c['bscBlue']};
  --bsc-teal: {c['bscTeal']};
  --bsc-gold: {c['bscGold']};
  --positive: {c['positive']};
  --negative: {c['negative']};
  --neutral: {c['neutral']};
  --text-1: {c['textPrimary']};
  --text-2: {c['textSecondary']};
  --text-3: {c['textTertiary']};
  --bg-canvas: {c['bgCanvas']};
  --surface: {c['surface']};
  --card: {c['card']};
  --tint-blue: {c['tintBlue']};
  --tint-teal: {c['tintTeal']};
  --line: {c['line']};
  --page-pad: {spacing['pagePadding']};
  --gap-section: {spacing['sectionGap']};
  --card-pad: {spacing['cardPad']};
  --fs-display: {ts['display']['size']};
  --fs-h1: {ts['h1']['size']};
  --fs-h2: {ts['h2']['size']};
  --fs-h3: {ts['h3']['size']};
  --fs-h4: {ts['h4']['size']};
  --fs-body-lg: {ts['bodyLg']['size']};
  --fs-body: {ts['body']['size']};
  --fs-label: {ts['label']['size']};
  --fs-caption: {ts['caption']['size']};
}}"""


def dump_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def nice_axis(values: list[float], tick_count: int = 6) -> tuple[float, float, list[float]]:
    low, high = min(values), max(values)
    padding = max((high - low) * 0.12, 5)
    low -= padding
    high += padding
    raw_step = max((high - low) / tick_count, 1)
    magnitude = 10 ** math.floor(math.log10(raw_step))
    normalized = raw_step / magnitude
    step = (1 if normalized <= 1 else 2 if normalized <= 2 else 5 if normalized <= 5 else 10) * magnitude
    axis_low = math.floor(low / step) * step
    axis_high = math.ceil(high / step) * step
    ticks = []
    value = axis_low
    while value <= axis_high + step * 0.1:
        ticks.append(value)
        value += step
    return axis_low, axis_high, ticks
