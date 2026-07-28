# BSC Quant Strategic Reports

Project tạo báo cáo HTML/PDF theo giao diện BSC GA_v9, nhưng **không dùng GA_v9 làm template nguồn**. Giao diện được viết trực tiếp trong component và CSS của project.

## Nguyên tắc kiến trúc

- Giữ `data/report-data.json` làm đầu vào thủ công mặc định.
- Renderer chỉ đọc dữ liệu đã được resolve, không gọi trực tiếp MCP/database.
- FiinPro và BSC database được chừa sẵn dưới dạng provider overlay, mặc định tắt.
- Web và Print dùng cùng một template `src/templates/report.html`.
- Giao diện v9 nằm trực tiếp tại `src/styles/report.css`, không có lớp `v9-report-ui.css` ghi đè.
- Chart được tạo từ `chart.data`, footer được tạo từ `contacts`, link card lấy từ `reportUrl`.

## Cấu trúc

```text
app/
  build.py                 Build orchestration
  providers/               Manual + cổng Fiin/BSC
  report/                  Validate, chart, renderer
config/
  data-sources.json        Bật/tắt nguồn dữ liệu
data/
  report-data.json         Dữ liệu nhập tay hiện tại
  raw/                     Dữ liệu bridge tương lai
  overrides/               Ghi đè có kiểm soát
  generated/               Dữ liệu đã resolve + lineage
src/
  partials/                Cấu phần báo cáo cũ đã chỉnh lại
  templates/report.html    Một template cho Web và Print
  styles/                  CSS gốc, print, editor, share
  scripts/editor.js        Inline editor
dist/                      Output
```

## Chạy project

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
powershell -ExecutionPolicy Bypass -File export.ps1
```

### macOS/Linux

```bash
python3 app/build.py
```

Output chính:

```text
dist/index.html
dist/BSC-QUANT-YYYY-MM/web.html
dist/BSC-QUANT-YYYY-MM/print.html
dist/BSC-QUANT-YYYY-MM/share.html
```

## Cập nhật dữ liệu hiện tại

Chỉ sửa `data/report-data.json`, sau đó chạy build. Cấu trúc dữ liệu cũ vẫn được giữ để không phá workflow hiện tại.

## Cổng dữ liệu tương lai

`config/data-sources.json` mặc định:

```json
{
  "mode": "manual",
  "providers": {
    "manual": { "enabled": true },
    "fiin": { "enabled": false },
    "bsc": { "enabled": false }
  }
}
```

Khi chưa có kết nối thật, provider Fiin/BSC có thể đọc overlay JSON trong `data/raw/`. Khi đã rõ cách kết nối, chỉ thay logic trong `app/providers/overlay.py` hoặc tách adapter riêng; không cần sửa template, CSS hay build output.

Thứ tự resolve hiện tại:

```text
Manual base → Fiin overlay → BSC overlay → Manual overrides
```

Danh sách object có trường `ticker` được merge theo ticker. Các danh sách thời gian như chart/heatmap được thay toàn bộ để giữ đúng thứ tự.

## Inline editor

`dist/index.html` vẫn có:

- Chỉnh sửa trực tiếp.
- Lưu localStorage.
- Đặt lại dữ liệu gốc.
- In/Xuất PDF từ trình duyệt.

Inline editor chỉ sửa bản hiển thị trên trình duyệt. Muốn cập nhật chính thức, sửa `data/report-data.json` và build lại.

## Lưu ý font

CSS dùng Nunito từ Google Fonts và có fallback hệ thống. Trong môi trường nội bộ không có Internet, có thể bổ sung font cục bộ vào hệ thống build của BSC; không cần thay component hoặc dữ liệu.
