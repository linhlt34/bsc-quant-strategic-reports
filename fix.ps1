$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding $False

# 1. Copy exact Chart HTML from reference
$ref = Get-Content 'references\BSC_Quant_Research_editable_saved.html' -Raw -Encoding UTF8
$chartMatch = [regex]::Match($ref, '(?s)<div class="sec-label">Hiệu quả hoạt động · theo ngày</div>.*?</svg></div>\s*</div>\s*</div>')
if ($chartMatch.Success) {
    [System.IO.File]::WriteAllText("$pwd\src\partials\chart.html", $chartMatch.Value, $utf8NoBom)
    Write-Host "[OK] chart.html restored from reference"
}

# 2. Fix UTF-8 issue and layout in share.html
$web = Get-Content 'src\templates\web.html' -Raw -Encoding UTF8
$cssMatches = [regex]::Matches($web, '(?s)<style>([\s\S]*?)</style>')
$css1 = $cssMatches[0].Groups[1].Value
$css2 = $cssMatches[1].Groups[1].Value

$shareHtml = @"
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{ meta.reportTitle }} | {{ meta.period }}</title>
<style>
$css1
</style>
<style>
$css2
/* Override for share */
body { padding: 32px 48px; width: 1200px; margin: 0 auto; }
.doc { max-width: 1104px; }
</style>
</head>
<body>
<div class="doc">
<div class="sheet">
##PARTIAL_TOPBAR##
##PARTIAL_HERO##
##PARTIAL_CHART##
<div class="sec-label" style="padding: 0 var(--page-pad) 12px;">CHI TIẾT MÃ CỔ PHIẾU</div>
<div class="stock-grid" style="grid-template-columns: repeat(2, minmax(0, 1fr));">
##SHARE_STOCK_CARDS##
</div>
  <div class="footer-cta" style="margin: 24px 32px 32px; display: flex; justify-content: space-between; align-items: center; border-top: 1px solid var(--line); padding-top: 24px;">
    <div class="disclaimer-block">
      <div class="cta-title" style="font-size: 14px; font-weight: 800; color: var(--bsc-blue); margin-bottom: 6px; text-transform: uppercase;">KHUYẾN CÁO SỬ DỤNG</div>
      <p class="disclaimer-text" style="font-size: 13px; color: var(--text-3); max-width: 600px;">{{ shareCard.disclaimerShort }}</p>
    </div>
    <div class="qr-block" style="display: flex; align-items: center; gap: 16px;">
      <div class="qr-svg-wrap" style="width: 72px; height: 72px;">
        ##SHARE_QR_CODE##
      </div>
      <div class="qr-text" style="font-size: 14px; font-weight: 700; color: var(--text-2);">
        Quét mã để xem<br><span style="color: var(--bsc-blue);">Báo cáo chi tiết</span>
      </div>
    </div>
  </div>
</div>
</div>
</body>
</html>
"@

[System.IO.File]::WriteAllText("$pwd\src\templates\share.html", $shareHtml, $utf8NoBom)
Write-Host "[OK] share.html recreated with UTF-8 encoding"
