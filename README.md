# BSC Quant Research — Report System

Hệ thống báo cáo chiến lược đầu tư config-driven cho **BSC Securities (Quant Research)**.  
Thiết kế cho đối tượng nhà đầu tư cá nhân cao tuổi / high-NAV — tối ưu khả năng đọc và PDF export.

---

## Cấu trúc dự án

```
bsc-quant-research/
├── theme.config.json        ← Design tokens: màu sắc + type scale
├── data/
│   └── report-data.json     ← Nội dung báo cáo: tickers, số liệu, metadata
├── build/
│   └── generate.js          ← Build script: inject tokens → dist/index.html
├── scripts/
│   └── export-pdf.js        ← Puppeteer: xuất PDF A4
├── dist/
│   └── index.html           ← 📄 File báo cáo cuối — standalone, không cần server
├── assets/
│   └── img/
│       └── logo.png         ← Logo BSC (đặt file vào đây)
└── package.json
```

---

## Bắt đầu nhanh

### 1. Cài đặt Node.js dependencies (lần đầu)

```bash
npm install
```

### 2. Xem báo cáo

Mở trực tiếp file `dist/index.html` trên trình duyệt — không cần server.

```bash
npm run preview
```

### 3. Build (sau khi thay đổi theme.config.json hoặc data/)

```bash
npm run build
```

### 4. Xuất PDF

**Cách A — Nhanh (browser):** Mở `dist/index.html` → nhấn nút **🖨️ Xuất PDF** hoặc `Ctrl+P` → Save as PDF → A4 Portrait

**Cách B — Puppeteer (batch/CI):**
```bash
npm run export
# → dist/BSC_Quant_Research_YYYYMMDD.pdf

# Tên custom:
npm run export -- --output=Q3_2026_Nang_Hang.pdf
```

---

## Cập nhật báo cáo mới

### Thay đổi số liệu / nội dung

Chỉ cần sửa `data/report-data.json`, sau đó chạy `npm run build`:

```json
// data/report-data.json
{
  "meta": {
    "reportTitle": "Danh mục ...",
    "period": "Q4 2026",
    "issueDate": "01/10/2026"
  },
  "hero": {
    "heroStats": [
      { "label": "VN-Index Target", "value": "1,550", ... }
    ]
  }
}
```

### Thay đổi màu sắc / font size

Sửa `theme.config.json`:

```json
{
  "colors": {
    "bscBlue": "#295CA9",    ← Màu chủ đạo BSC
    "bscTeal": "#009B87",    ← Accent teal
    ...
  },
  "typeScale": {
    "body": { "size": "14px", "weight": 400, ... }
  }
}
```

> ⚠️ **Hard rule**: Không được đặt `size` < `12px` trong bất kỳ cấp nào.  
> Build script sẽ báo lỗi và dừng lại nếu vi phạm.

### Thay logo

Đặt file logo vào `assets/img/logo.png`.  
File PNG nền trong suốt, chiều cao khuyến nghị 80–100px (retina 2x).

---

## Inline Editor (trình sửa trực tiếp)

`dist/index.html` có toolbar chỉnh sửa tích hợp:

| Nút | Chức năng |
|-----|-----------|
| ✏️ Chỉnh sửa | Bật/tắt chế độ edit — click vào text để sửa |
| 💾 Lưu | Lưu vào localStorage trình duyệt |
| ↩ Reset | Xóa state đã lưu, tải lại bản gốc |
| 🖨️ Xuất PDF | Gọi `window.print()` |

> **Lưu ý quan trọng**: Chỉnh sửa inline là tạm thời (lưu localStorage trên máy đó). Để thay đổi vĩnh viễn và đồng bộ lên GitHub → cập nhật `data/report-data.json` và chạy `npm run build`.

---

## Design System

### Color Roles

| Token | Hex | Vai trò |
|-------|-----|---------|
| `--bsc-blue` | `#295CA9` | Brand primary, heading, CTA |
| `--bsc-teal` | `#009B87` | Accent positive, biểu đồ |
| `--bsc-gold` | `#FFC132` | Highlight badge (dùng <5% diện tích) |
| `--positive`  | `#16A34A` | Tăng/lãi |
| `--negative`  | `#DC2626` | Giảm/lỗ/rủi ro |
| `--text-1`    | `#0F172A` | Heading, số liệu — contrast 19:1 |
| `--text-2`    | `#475569` | Body text — contrast 7.5:1 |
| `--text-3`    | `#64748B` | Caption, meta — contrast 4.6:1 ≥ AA |

### Type Scale (Major Second ~1.125)

| Cấp | Size | Dùng cho |
|-----|------|----------|
| Display | 38px | Hero numbers |
| H1 | 28px | Report title |
| H2 | 22px | Section headings |
| H3 | 18px | Sub-sections |
| H4 | 16px | Card headings, tickers |
| Body-lg | 15px | Lede, key text |
| Body | 14px | Table data, content |
| Label | 12px | Uppercase labels (= floor) |
| Caption | 12px | Notes, disclaimer (= floor) |

**WCAG AA compliance**: Tất cả cặp text/background đạt ≥ 4.5:1.

---

## Deploy GitHub

```bash
git init
git add .
git commit -m "feat: BSC Quant Research report system v1.0"
git remote add origin https://github.com/<your-org>/bsc-quant-research.git
git push -u origin main
```

**GitHub Pages** (nếu cần host online):
```
Settings → Pages → Source: main branch / dist folder
```

---

## Workflow khuyến nghị

```
1. Cập nhật số liệu   →  data/report-data.json
2. Build              →  npm run build
3. Review trên browser →  npm run preview
4. Chỉnh sửa nhỏ     →  Dùng Inline Editor (✏️)
5. Xuất PDF           →  🖨️ Xuất PDF (browser) hoặc npm run export
6. Commit & push      →  git add . && git commit && git push
```

---

*BSC Securities — Quant Research Division*  
*© 2026 BSC. Bảo lưu mọi quyền.*
