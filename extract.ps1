$html = Get-Content 'references/BSC_Quant_Research_editable_saved.html' -Raw -Encoding UTF8
$matches = [regex]::Matches($html, '(?s)<style>(.*?)</style>')
$allCss = ""
foreach ($m in $matches) {
    $allCss += $m.Groups[1].Value + "`n"
}
Set-Content -Path 'src/templates/share-css.css' -Value $allCss -Encoding UTF8
