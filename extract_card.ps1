$html = Get-Content 'references/BSC_Quant_Research_editable_saved.html' -Raw -Encoding UTF8
$match = [regex]::Match($html, '(?s)<div class="stock-card">(.*?)<div class="stock-card">')
Set-Content -Path 'src/partials/share-stock-card-item-raw.html' -Value ('<div class="stock-card">' + $match.Groups[1].Value) -Encoding UTF8
