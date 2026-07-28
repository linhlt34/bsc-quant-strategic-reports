from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
result = subprocess.run([sys.executable, "app/build.py"], cwd=ROOT, check=False)
assert result.returncode == 0
html = (ROOT / "dist/index.html").read_text(encoding="utf-8")
assert "v9-report-ui" not in html
assert html.count('class="stock-card"') == 5
assert "Xem báo cáo phân tích chi tiết" not in html
assert "btn-report" not in html
assert "##" not in html
assert "<svg" in html
print("Smoke test passed")
