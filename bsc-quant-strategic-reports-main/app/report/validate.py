from __future__ import annotations

import re
from typing import Any


class ValidationError(ValueError):
    pass


def _require(mapping: dict[str, Any], key: str, context: str) -> Any:
    if key not in mapping:
        raise ValidationError(f"Missing required field: {context}.{key}")
    return mapping[key]


def validate_report(data: dict[str, Any], theme: dict[str, Any]) -> None:
    meta = _require(data, "meta", "root")
    doc_code = _require(meta, "docCode", "meta")
    if not re.fullmatch(r"BSC-QUANT-\d{4}-\d{2}", str(doc_code)):
        raise ValidationError(f"Invalid meta.docCode: {doc_code}")

    rows = _require(_require(data, "recTable", "root"), "rows", "recTable")
    if not rows:
        raise ValidationError("recTable.rows must contain at least one recommendation")
    tickers = [str(_require(row, "ticker", "recTable.rows[]")) for row in rows]
    if len(tickers) != len(set(tickers)):
        raise ValidationError("Duplicate ticker found in recTable.rows")

    total_weight = 0.0
    for row in rows:
        weight = _require(row, "weight", f"recTable.rows[{row.get('ticker', '?')}]")
        if not isinstance(weight, (int, float)):
            raise ValidationError(f"Weight for {row.get('ticker')} must be numeric")
        total_weight += float(weight)
    if abs(total_weight - 100.0) > 1e-9:
        raise ValidationError(f"Recommendation weights must total 100%; current total is {total_weight}")

    cards = _require(data, "stockCards", "root")
    card_tickers = [str(card.get("ticker", "")) for card in cards]
    missing_cards = [ticker for ticker in tickers if ticker not in card_tickers]
    if missing_cards:
        raise ValidationError(f"Missing stockCards for: {', '.join(missing_cards)}")

    chart = _require(data, "chart", "root")
    chart_data = _require(chart, "data", "chart")
    labels = _require(chart_data, "labels", "chart.data")
    portfolio = _require(chart_data, "portfolio", "chart.data")
    benchmark = _require(chart_data, "vnindex", "chart.data")
    if not (len(labels) == len(portfolio) == len(benchmark)) or len(labels) < 2:
        raise ValidationError("chart.data labels, portfolio, and vnindex must have the same length >= 2")

    picks = data.get("shareCard", {}).get("topPicks", [])
    invalid_picks = [ticker for ticker in picks if ticker not in tickers]
    if invalid_picks:
        raise ValidationError(f"shareCard.topPicks contains unknown tickers: {', '.join(invalid_picks)}")

    for name, spec in theme.get("typeScale", {}).items():
        if name.startswith("_"):
            continue
        size = str(spec.get("size", "0px"))
        match = re.fullmatch(r"(\d+)px", size)
        if not match:
            raise ValidationError(f"Invalid type scale size: theme.typeScale.{name}.size={size}")
        if int(match.group(1)) < 8:
            raise ValidationError(f"Font size below safety floor: theme.typeScale.{name}.size={size}")
