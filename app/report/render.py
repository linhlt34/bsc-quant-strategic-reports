from __future__ import annotations

import json
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

from .charts import render_line_chart
from .utils import assert_no_tokens, css_vars, data_uri, escape, read_text, replace_tokens, write_text


def _qr_svg(url: str) -> str:
    if not url:
        return '<div class="qr-fallback">BSC</div>'
    endpoint = "https://api.qrserver.com/v1/create-qr-code/?size=150x150&format=svg&data=" + urllib.parse.quote(url, safe="")
    try:
        with urllib.request.urlopen(endpoint, timeout=5) as response:
            value = response.read().decode("utf-8")
        return value.replace('<?xml version="1.0" encoding="UTF-8"?>', "")
    except Exception:
        return '<div class="qr-fallback">QR offline</div>'


def _render_fact_chips(items: list[dict[str, Any]]) -> str:
    return "\n".join(
        f'<span class="fact-chip"><b>{escape(item.get("label"))}</b><span>{escape(item.get("value"))}</span></span>'
        for item in items
    )


def _render_hero_stats(items: list[dict[str, Any]]) -> str:
    blocks = []
    for item in items:
        style = escape(item.get("style", "plain"))
        unit = f'<span class="hs-unit"> {escape(item.get("unit"))}</span>' if item.get("unit") else ""
        blocks.append(f"""<div class="hero-stat {style}">
  <div class="hs-label">{escape(item.get('label'))}</div>
  <div class="hs-value {style}" data-edit>{escape(item.get('value'))}{unit}</div>
  <div class="hs-sub" data-edit>{escape(item.get('sub'))}</div>
</div>""")
    return "\n".join(blocks)


def _render_table_rows(rows: list[dict[str, Any]], template: str) -> str:
    output = []
    for row in rows:
        values = {
            "{{ ticker }}": escape(row.get("ticker")),
            "{{ sector }}": escape(row.get("sector")),
            "{{ buyPrice }}": escape(row.get("buyPrice")),
            "{{ peTtm }}": escape(row.get("peTtm")),
            "{{ pbTtm }}": escape(row.get("pbTtm")),
            "{{ profitGrowth }}": escape(row.get("profitGrowth")),
            "{{ weight }}": escape(row.get("weight")),
        }
        output.append(replace_tokens(template, values))
    return "\n".join(output)


def _render_heatmap(data: dict[str, Any]) -> tuple[str, str]:
    headers = "".join(f"<th>{escape(month)}</th>" for month in data["months"])
    rows = []
    for row in data["rows"]:
        cells = [f'<td class="year-cell">{escape(row["year"])}</td>']
        for index, value in enumerate(row["data"]):
            is_total = index == len(row["data"]) - 1
            if value is None:
                cells.append('<td class="empty-cell">&mdash;</td>')
                continue
            number = float(value)
            label = f"{number:+g}%" if number != 0 else "0%"
            if is_total:
                cells.append(f'<td class="total-cell" data-edit>{label}</td>')
                continue
            intensity = min(0.10 + abs(number) / 35.0, 0.58)
            if number > 0:
                style = f"background:rgba(110,170,136,{intensity:.3f});color:#315F49"
            elif number < 0:
                style = f"background:rgba(210,138,142,{intensity:.3f});color:#7B3B42"
            else:
                style = "background:#FAFAF9;color:#64748B"
            cells.append(f'<td style="{style}">{label}</td>')
        rows.append("<tr>" + "".join(cells) + "</tr>")
    return headers, "\n".join(rows)


def _render_stock_cards(cards: list[dict[str, Any]], template: str) -> str:
    output = []
    for card in cards:
        metrics = "".join(
            f'<div class="metric-item"><div class="m-label">{escape(metric.get("label"))}</div><div class="m-value" data-edit>{escape(metric.get("value"))}</div></div>'
            for metric in card.get("metrics", [])
        )
        values = {
            "##TICKER##": escape(card.get("ticker")),
            "##COMPANY##": escape(card.get("company") or card.get("sector")),
            "##WEIGHT##": escape(card.get("weight")),
            "##METRICS##": metrics,
        }
        output.append(replace_tokens(template, values))
    return "\n".join(output)


def _render_contacts(contacts: list[dict[str, Any]]) -> str:
    return "\n".join(
        f"""<div class="contact-block"><b>{escape(item.get('name'))}</b><br>{escape(item.get('phone'))}<br>{escape(item.get('email'))}</div>"""
        for item in contacts
    )


def _render_share_cards(cards: list[dict[str, Any]], template: str) -> str:
    output = []
    for card in cards:
        metrics = card.get("metrics", [])
        values_by_label = {str(item.get("label", "")).upper(): str(item.get("value", "")) for item in metrics}
        def metric(prefix: str) -> str:
            for label, value in values_by_label.items():
                if label.startswith(prefix):
                    return value
            return "#na"
        values = {
            "{{ ticker }}": escape(card.get("ticker")),
            "{{ sector }}": escape(card.get("company") or card.get("sector")),
            "{{ weight }}": escape(card.get("weight")),
            "{{ mcap }}": escape(metric("V\u1ed0N H\u00d3A")),
            "{{ liq }}": escape(metric("THANH KHO\u1ea2N")),
            "{{ float }}": escape(metric("FREE FLOAT").replace("%", "")),
            "{{ growth }}": escape(metric("T\u0102NG TR\u01af\u1edeNG").replace("%", "")),
            "{{ pe }}": escape(metric("P/E").replace("x", "")),
            "{{ pb }}": escape(metric("P/B").replace("x", "")),
        }
        output.append(replace_tokens(template, values))
    return "\n".join(output)


def render_project(project_root: Path, data: dict[str, Any], theme: dict[str, Any]) -> list[Path]:
    asset_root = project_root / "report"
    partial_dir = asset_root / "partials"
    template_dir = asset_root / "templates"
    style_dir = asset_root / "styles"

    logo_uri = data_uri(asset_root / "images/logo.svg")
    row_template = read_text(partial_dir / "rec-table-row.html")
    stock_template = read_text(partial_dir / "stock-card-item.html")
    share_card_template = read_text(partial_dir / "share-stock-card-item.html")

    heat_headers, heat_rows = _render_heatmap(data["heatmap"])
    components: dict[str, str] = {}
    common = {
        "##LOGO_BASE64##": logo_uri,
        "##FACT_CHIPS##": _render_fact_chips(data["hero"].get("factChips", [])),
        "##HERO_STATS##": _render_hero_stats(data["hero"].get("heroStats", [])),
        "##TABLE_ROWS##": _render_table_rows(data["recTable"]["rows"], row_template),
        "##CHART_SVG##": render_line_chart(data["chart"], theme["colors"]["bscBlue"], project_root),
        "##HEATMAP_HEADERS##": heat_headers,
        "##HEATMAP_ROWS##": heat_rows,
        "##STOCK_CARDS##": _render_stock_cards(data["stockCards"], stock_template),
        "##CONTACT_BLOCK##": _render_contacts(data.get("contacts", [])),
    }

    text_values = {
        "{{ topbar.brandLabel }}": escape(data["topbar"].get("brandLabel")),
        "{{ topbar.divisionLabel }}": escape(data["topbar"].get("divisionLabel")),
        "{{ topbar.metaLine1 }}": escape(data["topbar"].get("metaLine1")),
        "{{ topbar.metaLine2 }}": escape(data["topbar"].get("metaLine2")),
        "{{ hero.tag }}": escape(data["hero"].get("tag")),
        "{{ hero.title }}": escape(data["hero"].get("title")),
        "{{ hero.lede }}": escape(data["hero"].get("lede")),
        "{{ recTable.sectionLabel }}": escape(data["recTable"].get("sectionLabel")),
        "{{ recTable.sectionSub }}": escape(data["recTable"].get("sectionSub")),
        "{{ chart.sectionLabel }}": escape(data["chart"].get("sectionLabel")),
        "{{ heatmap.sectionLabel }}": escape(data["heatmap"].get("sectionLabel")),
        "{{ heatmap.sectionSub }}": escape(data["heatmap"].get("sectionSub")),
        "{{ legalText }}": data.get("legalText", ""),
        "{{ copyrightYear }}": escape(data.get("copyrightYear")),
    }

    partial_names = ["topbar", "hero", "rec-table", "chart", "heatmap", "stock-cards", "footer"]
    for name in partial_names:
        content = read_text(partial_dir / f"{name}.html")
        content = replace_tokens(content, text_values)
        content = replace_tokens(content, common)
        components[name] = content

    base_css = "\n".join([
        '@import url("https://fonts.googleapis.com/css2?family=Nunito:wght@400;500;600;700;800;900&display=swap");',
        css_vars(theme),
        read_text(style_dir / "report.css"),
    ])
    print_css = read_text(style_dir / "print.css")
    editor_css = read_text(style_dir / "editor.css")
    editor_js = read_text(asset_root / "js/editor.js").replace("##DOC_CODE##", json.dumps(str(data["meta"]["docCode"])))
    toolbar = read_text(partial_dir / "editor-toolbar.html")

    report_template = read_text(template_dir / "report.html")
    meta_values = {
        "{{ meta.reportTitle }}": escape(data["meta"].get("reportTitle")),
        "{{ meta.period }}": escape(data["meta"].get("period")),
        "{{ meta.division }}": escape(data["meta"].get("division")),
        "{{ meta.disclaimer }}": escape(data["meta"].get("disclaimer")),
    }
    report_template = replace_tokens(report_template, meta_values)
    for key, value in components.items():
        report_template = report_template.replace(f"##PARTIAL_{key.upper().replace('-', '_')}##", value)

    output_dir = project_root / "dist"
    output_dir.mkdir(parents=True, exist_ok=True)

    web_html = replace_tokens(report_template, {
        "##REPORT_CSS##": base_css,
        "##PRINT_CSS##": print_css,
        "##EDITOR_CSS##": editor_css,
        "##EDITOR_TOOLBAR##": toolbar,
        "##EDITOR_SCRIPT##": f"<script>{editor_js}</script>",
        "##BODY_CLASS##": "web-mode editor-ready",
    })
    print_html = replace_tokens(report_template, {
        "##REPORT_CSS##": base_css,
        "##PRINT_CSS##": print_css,
        "##EDITOR_CSS##": "",
        "##EDITOR_TOOLBAR##": "",
        "##EDITOR_SCRIPT##": "",
        "##BODY_CLASS##": "print-mode",
    })

    assert_no_tokens(web_html, "web.html")
    assert_no_tokens(print_html, "print.html")
    write_text(output_dir / "web.html", web_html)
    write_text(output_dir / "print.html", print_html)

    share_template = read_text(template_dir / "share.html")
    share_values = {
        "##REPORT_CSS##": css_vars(theme) + "\n" + read_text(style_dir / "share.css"),
        "##LOGO_BASE64##": logo_uri,
        "##SHARE_STOCK_CARDS##": _render_share_cards(data["stockCards"], share_card_template),
        "##SHARE_QR_CODE##": _qr_svg(data.get("shareCard", {}).get("ctaUrl", "")),
        "{{ meta.reportTitle }}": escape(data["meta"].get("reportTitle")),
        "{{ topbar.brandLabel }}": escape(data["topbar"].get("brandLabel")),
        "{{ topbar.divisionLabel }}": escape(data["topbar"].get("divisionLabel")),
        "{{ shareCard.eyebrow }}": escape(data.get("shareCard", {}).get("eyebrow")),
        "{{ shareCard.headlineShort }}": escape(data.get("shareCard", {}).get("headlineShort")),
        "{{ shareCard.disclaimerShort }}": escape(data.get("shareCard", {}).get("disclaimerShort")),
    }
    share_html = replace_tokens(share_template, share_values)
    assert_no_tokens(share_html, "share.html")
    write_text(output_dir / "share.html", share_html)

    return [output_dir / "web.html", output_dir / "print.html", output_dir / "share.html"]
