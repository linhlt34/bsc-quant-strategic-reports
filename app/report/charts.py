from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .utils import escape, nice_axis


def _render_reference_chart(chart: dict[str, Any], project_root: Path) -> str:
    reference_path = project_root / str(chart["referenceFile"])
    with reference_path.open("r", encoding="utf-8-sig") as handle:
        ref = json.load(handle)

    axis_texts: list[str] = []
    end_texts: list[str] = []
    for item in ref.get("texts", []):
        attrs = [
            f'x="{item["x"]:g}"',
            f'y="{item["y"]:g}"',
            f'font-size="{item.get("fontSize", 10):g}"',
        ]
        anchor = item.get("anchor")
        if anchor and anchor != "start":
            attrs.append(f'text-anchor="{escape(anchor)}"')
        fill = item.get("fill")
        if fill:
            attrs.append(f'fill="{escape(fill)}"')
        text = str(item.get("text", ""))
        if text == str(ref.get("portfolioEndLabel", "170")):
            attrs.append('font-weight="700"')
            if not fill:
                attrs.append('fill="#1b4f9c"')
            end_texts.append(f'<text {" ".join(attrs)}>{escape(text)}</text>')
        elif text == str(ref.get("benchmarkEndLabel", "144")):
            end_texts.append(f'<text {" ".join(attrs)}>{escape(text)}</text>')
        else:
            axis_texts.append(f'<text {" ".join(attrs)}>{escape(text)}</text>')

    circles = "".join(
        f'<circle cx="{item["cx"]:g}" cy="{item["cy"]:g}" r="{item["r"]:g}" fill="{escape(item["fill"])}"></circle>'
        for item in ref.get("circles", [])
    )

    return f'''<svg viewBox="{escape(ref.get("viewBox", "0 0 812 300"))}" preserveAspectRatio="xMidYMid meet" role="img" aria-label="Hiệu quả danh mục so với VN-Index">
  <defs>
    <linearGradient id="fillT" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#1b4f9c" stop-opacity="0.10"></stop>
      <stop offset="100%" stop-color="#1b4f9c" stop-opacity="0"></stop>
    </linearGradient>
  </defs>
  {''.join(axis_texts)}
  <path d="{ref['areaPath']}" fill="url(#fillT)"></path>
  <path d="{ref['benchmarkPath']}" fill="none" stroke="#b6c2d0" stroke-width="1.6"></path>
  <path d="{ref['portfolioPath']}" fill="none" stroke="#1b4f9c" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round"></path>
  {circles}
  {''.join(end_texts)}
</svg>'''


def _render_generic_chart(chart: dict[str, Any], primary_color: str = "#295CA9") -> str:
    data = chart["data"]
    labels = data["labels"]
    portfolio = [float(x) for x in data["portfolio"]]
    benchmark = [float(x) for x in data["vnindex"]]
    all_values = portfolio + benchmark
    y_min, y_max, ticks = nice_axis(all_values)

    width, height = 812.0, 300.0
    left, right, top, bottom = 40.0, 46.0, 16.0, 26.0
    plot_w, plot_h = width - left - right, height - top - bottom

    def x_pos(index: int, count: int) -> float:
        return left + (plot_w * index / max(count - 1, 1))

    def y_pos(value: float) -> float:
        return top + (y_max - value) * plot_h / (y_max - y_min)

    def path(values: list[float]) -> str:
        return " ".join(
            ("M" if i == 0 else "L") + f"{x_pos(i, len(values)):.1f} {y_pos(v):.1f}"
            for i, v in enumerate(values)
        )

    y_labels = "".join(
        f'<text x="32" y="{y_pos(tick)+3.5:.1f}" text-anchor="end" font-size="10" fill="#98a6b5">{tick:g}</text>'
        for tick in ticks
    )
    x_labels = "".join(
        f'<text x="{x_pos(i, len(labels)):.1f}" y="292" text-anchor="middle" font-size="10" fill="#98a6b5">{escape(label)}</text>'
        for i, label in enumerate(labels)
    )

    p_path = path(portfolio)
    b_path = path(benchmark)
    base_y = 274.0
    p_area = f'M{left:.1f} {base_y:.1f} ' + p_path + f' L{x_pos(len(portfolio)-1, len(portfolio)):.1f} {base_y:.1f} L {left:.1f} {base_y:.1f} Z'
    end_x = x_pos(len(portfolio) - 1, len(portfolio))
    p_end_y = y_pos(portfolio[-1])
    b_end_y = y_pos(benchmark[-1])

    return f'''<svg viewBox="0 0 812 300" preserveAspectRatio="xMidYMid meet" role="img" aria-label="Hiệu quả danh mục so với VN-Index">
  <defs>
    <linearGradient id="fillT" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="{primary_color}" stop-opacity="0.10"></stop>
      <stop offset="100%" stop-color="{primary_color}" stop-opacity="0"></stop>
    </linearGradient>
  </defs>
  {y_labels}{x_labels}
  <path d="{p_area}" fill="url(#fillT)"></path>
  <path d="{b_path}" fill="none" stroke="#b6c2d0" stroke-width="1.6"></path>
  <path d="{p_path}" fill="none" stroke="{primary_color}" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round"></path>
  <circle cx="{end_x:.1f}" cy="{p_end_y:.1f}" r="3" fill="{primary_color}"></circle>
  <circle cx="{end_x:.1f}" cy="{b_end_y:.1f}" r="3" fill="#b6c2d0"></circle>
  <text x="{end_x+6:.1f}" y="{p_end_y+4:.1f}" font-size="12" font-weight="700" fill="{primary_color}">{portfolio[-1]:g}</text>
  <text x="{end_x+6:.1f}" y="{b_end_y+4:.1f}" font-size="12" fill="#98a6b5">{benchmark[-1]:g}</text>
</svg>'''


def render_line_chart(
    chart: dict[str, Any],
    primary_color: str = "#295CA9",
    project_root: Path | None = None,
) -> str:
    if chart.get("referenceFile") and project_root is not None:
        return _render_reference_chart(chart, project_root)
    return _render_generic_chart(chart, primary_color)
