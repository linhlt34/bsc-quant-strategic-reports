# Raw data bridge

Mặc định project không đọc thư mục này. Khi kết nối nguồn dữ liệu:

- `fiin-overlay.json`: dữ liệu thị trường/actual do adapter FiinPro tạo ra.
- `bsc-overlay.json`: dữ liệu forecast/proprietary do adapter database BSC tạo ra.

Hai file overlay dùng cùng cấu trúc với phần tương ứng trong `data/report-data.json`. Danh sách có trường `ticker` được merge theo ticker, không thay toàn bộ danh sách.
