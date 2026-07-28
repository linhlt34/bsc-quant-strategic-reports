from __future__ import annotations

import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
SRC_ROOT = PROJECT_ROOT / "src"
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))

from bsc_quant_research.providers import resolve_report_data
from bsc_quant_research.report.render import render_project
from bsc_quant_research.report.utils import dump_json
from bsc_quant_research.report.validate import validate_report


def main() -> int:
    print("[BUILD] BSC Quant Research - optimized pipeline")
    theme_path = PROJECT_ROOT / "config/theme.json"
    with theme_path.open("r", encoding="utf-8-sig") as handle:
        theme = json.load(handle)

    report, lineage = resolve_report_data(PROJECT_ROOT)
    validate_report(report, theme)
    print("[VALIDATE] Report data passed validation")

    dump_json(PROJECT_ROOT / "data/generated/report-data.json", report)
    dump_json(PROJECT_ROOT / "data/generated/data-lineage.json", lineage)

    outputs = render_project(PROJECT_ROOT, report, theme)
    for output in outputs:
        size_kb = output.stat().st_size / 1024
        print(f"[OK] {output.relative_to(PROJECT_ROOT)} ({size_kb:.0f} KB)")
    print("[DONE] Build completed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())