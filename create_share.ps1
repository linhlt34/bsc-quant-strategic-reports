$refPath = "references/BSC_Quant_Research_editable_saved.html"
$refHtml = Get-Content $refPath -Raw -Encoding UTF8

# 1. Trích xuất CSS
$cssMatch = [regex]::Match($refHtml, "(?s)<style>(.*?)</style>")
$css = $cssMatch.Groups[1].Value

# 2. Bắt đầu từ div.doc
$docStart = $refHtml.IndexOf('<div class="doc">')
$docHtml = $refHtml.Substring($docStart)
$docHtml = $docHtml -replace "(?s)</body>.*", ""

# 3. Gỡ bỏ topbar
$docHtml = $docHtml -replace "(?s)<div class=`"topbar`">.*?</div>\s*</div>", ""

# 4. Gỡ bỏ Bảng hiệu quả hoạt động
$docHtml = $docHtml -replace "(?s)<div class=`"sec-label`">HIỆU QUẢ HOẠT ĐỘNG \· THEO CÁC MỐC THỜI GIAN.*?</div>\s*</div>", ""
$docHtml = $docHtml -replace "(?s)<div class=`"board-wrap`">.*?</table>\s*</div>", ""

# 5. Gỡ bỏ Bảng Tỷ trọng cổ phiếu (heatmap)
$docHtml = $docHtml -replace "(?s)<div class=`"sec-label`">TỶ TRỌNG CỔ PHIẾU.*?</div>\s*</div>", ""
$docHtml = $docHtml -replace "(?s)<div class=`"heatmap-wrap`">.*?</div>\s*</div>", ""

# 6. Thay thế HERO block tĩnh thành template biến
$docHtml = $docHtml -replace 'Danh mục Đón sóng Nâng hạng Thị trường', '##HERO_TITLE##'
$docHtml = $docHtml -replace 'Tập trung vào nhóm doanh nghiệp hưởng lợi trực tiếp khi thị trường chứng khoán Việt Nam được nâng hạng\. Kết hợp góc nhìn cơ bản về câu chuyện nâng hạng với dự phóng của mô hình học máy định lượng dựa trên dữ liệu lịch sử\. Ưu tiên thanh khoản cao và tối đa hóa lợi nhuận dựa trên chênh lệch giá\.', '##HERO_LEDE##'
$docHtml = $docHtml -replace '\+69\.5\%', '##HERO_STAT_0##'
$docHtml = $docHtml -replace '\+44\.4\%', '##HERO_STAT_0_SUB##'
$docHtml = $docHtml -replace '\-7\.2\%', '##HERO_STAT_1##'
$docHtml = $docHtml -replace '\+3\.7\%', '##HERO_STAT_1_SUB##'
$docHtml = $docHtml -replace '1\.15', '##HERO_STAT_2##'
$docHtml = $docHtml -replace '29/03/2024', '##HERO_STAT_3##'
$docHtml = $docHtml -replace '5 cổ phiếu', '##HERO_TAG_0##'
$docHtml = $docHtml -replace '1 quý', '##HERO_TAG_1##'
$docHtml = $docHtml -replace 'Hàng quý', '##HERO_TAG_2##'

# 8. Trích xuất 1 Stock Card làm template, rồi thay toàn bộ khối Stock Grid bằng ##SHARE_STOCK_CARDS##
$stockGridMatch = [regex]::Match($docHtml, "(?s)<div class=`"stock-grid`">(.*?)</div>\s*(?:</div>|\s*<div class=`"sheet`">)")
if ($stockGridMatch.Success) {
    $gridContent = $stockGridMatch.Groups[1].Value
    $docHtml = $docHtml.Replace($gridContent, "`n##SHARE_STOCK_CARDS##`n")
}

# 9. Gỡ bỏ header của sheet 2
$docHtml = $docHtml -replace "(?s)<div class=`"topbar`">.*?</div>\s*</div>", ""
$docHtml = $docHtml -replace "(?s)<div class=`"hero compact`">.*?</div>\s*</div>", ""

# 10. Footer Disclaimer (QR)
$docHtml = $docHtml -replace "(?s)<svg class=`"qr-code`".*?</svg>", "##SHARE_QR_CODE##"
$docHtml = $docHtml -replace 'Tài liệu chỉ mang tính chất tham khảo\. Vui lòng đọc kỹ Báo cáo chi tiết để biết rủi ro\.', '##DISCLAIMER_TEXT##'

# 11. Xóa các phân trang thừa và page-footer
$docHtml = $docHtml -replace "(?s)<footer class=`"page-footer`">.*?</footer>", ""
$docHtml = $docHtml -replace "(?s)<footer class=`"page-footer page-footer-compact`">.*?</footer>", ""
$docHtml = $docHtml -replace '<div class="sheet">', ''
$docHtml = $docHtml -replace '</div>\s*</div>\s*</div>$', '</div></div>'

# 12. Ghép lại thành share.html
$finalHtml = @"
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<style>
$css
/* Bổ sung chỉnh size chữ và spacing cho phù hợp share image */
body {
    zoom: 1.35;
    padding: 0;
    background: white;
}
.doc {
    box-shadow: none;
    border: none;
    gap: 16px;
    padding: 24px;
}
</style>
</head>
<body>
$docHtml
</body>
</html>
"@

Set-Content -Path "src/templates/share.html" -Value $finalHtml -Encoding UTF8
Write-Host "Tạo src/templates/share.html thành công!"

# 13. Tái tạo share-stock-card-item.html
$cardTemplate = @"
<div class="stock-card">
<div class="sc-head">
<div>
<div class="sc-ticker">##TICKER##</div>
<div class="sc-company">##SECTOR##</div>
</div>
<div class="sc-badge">
<div class="sc-badge-label">Tỷ trọng danh mục</div>
<div class="sc-badge-value">##WEIGHT##%</div>
</div>
</div>
<div class="sc-metrics">
<div class="m-item"><div class="m-label">Vốn hóa</div><div class="m-value">##MCAP##</div></div>
<div class="m-item"><div class="m-label">Thanh khoản</div><div class="m-value">##LIQ##</div></div>
<div class="m-item"><div class="m-label">Free float</div><div class="m-value">##FLOAT##%</div></div>
<div class="m-item"><div class="m-label">Tăng trưởng LNST SVCK</div><div class="m-value">##GROWTH##%</div></div>
<div class="m-item"><div class="m-label">P/E TTM</div><div class="m-value">##PE##x</div></div>
<div class="m-item"><div class="m-label">P/B TTM</div><div class="m-value">##PB##x</div></div>
</div>
<div class="sc-action">
<a href="##LINK##" class="btn-report">Xem báo cáo phân tích chi tiết</a>
</div>
</div>
"@
Set-Content -Path "src/partials/share-stock-card-item.html" -Value $cardTemplate -Encoding UTF8
Write-Host "Tạo src/partials/share-stock-card-item.html thành công!"
