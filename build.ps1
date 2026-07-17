# ===================================================================
# BSC QUANT RESEARCH - PowerShell Build Script (v2.6)
# Pure ASCII characters only - No emojis or Unicode box drawings
# ===================================================================

$ErrorActionPreference = "Stop"
Write-Host "[BUILD] BSC Quant Research - Starting PowerShell Build Pipeline" -ForegroundColor Cyan

# 1. LOAD CONFIGS
$themeFile = "theme.config.json"
$dataFile = "data/report-data.json"

if (!(Test-Path $themeFile) -or !(Test-Path $dataFile)) {
    Write-Error "Missing configuration files ($themeFile or $dataFile)."
}

$theme = [System.IO.File]::ReadAllText((Join-Path $PWD $themeFile), [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$data = [System.IO.File]::ReadAllText((Join-Path $PWD $dataFile), [System.Text.Encoding]::UTF8) | ConvertFrom-Json

# 2. DATA VALIDATION (Fail-Fast)
Write-Host "[VALIDATE] Validating configuration and data..." -ForegroundColor Yellow

# A. DocCode validation
$docCode = $data.meta.docCode
if ($docCode -notmatch "^BSC-QUANT-\d{4}-\d{2}$") {
    Write-Error "Validation Failed: meta.docCode '$docCode' does not match pattern '^BSC-QUANT-\d{4}-\d{2}$'"
}

# B. Type scale floor check (>= 12px)
foreach ($prop in $theme.typeScale.psobject.Properties) {
    if ($prop.Name -notlike "_*") {
        $sizeStr = $prop.Value.size
        $sizePx = [int]($sizeStr -replace "px", "")
        if ($sizePx -lt 12) {
            Write-Error "Validation Failed: theme.typeScale.$($prop.Name) size '$sizeStr' is less than the 12px floor!"
        }
    }
}

# C. Integrity Check: topPicks must be subset of recommendations
$tickers = $data.recTable.rows | ForEach-Object { $_.ticker }
foreach ($pick in $data.shareCard.topPicks) {
    if ($pick -notin $tickers) {
        Write-Error "Validation Failed: shareCard.topPicks contains '$pick' which is not in the recommendations list!"
    }
}

# D. Weight validation (sum of weights must be 100)
$totalWeight = 0
foreach ($row in $data.recTable.rows) {
    if ($row.weight.GetType().Name -ne "Int32" -and $row.weight.GetType().Name -ne "Double") {
        Write-Error "Validation Failed: Ticker '$($row.ticker)' weight '$($row.weight)' is not a number!"
    }
    $totalWeight += $row.weight
}
if ($totalWeight -ne 100) {
    Write-Error "Validation Failed: Total weight is $totalWeight%, but it must be exactly 100%!"
}

Write-Host "[VALIDATE] Data validation passed!" -ForegroundColor Green

# 3. ASSETS PREPARATION (Inlining Fonts & Logo)
Write-Host "[ASSETS] Encoding assets to base64..." -ForegroundColor Yellow

# Encode Fonts
$fontCss = "/* Self-hosted inlined Nunito Fonts */`n"
$fontNames = @("Regular", "Medium", "SemiBold", "Bold", "ExtraBold")
$fontWeights = @{
    "Regular" = "400"
    "Medium" = "500"
    "SemiBold" = "600"
    "Bold" = "700"
    "ExtraBold" = "800"
}
foreach ($name in $fontNames) {
    $fontPath = "assets/fonts/Nunito-$name.woff2"
    if (Test-Path $fontPath) {
        $bytes = [IO.File]::ReadAllBytes($fontPath)
        $b64 = [Convert]::ToBase64String($bytes)
        $weight = $fontWeights[$name]
        
        $template = '@font-face {{
  font-family: ''Nunito'';
  font-style: normal;
  font-weight: {0};
  font-display: swap;
  src: url(''data:font/woff2;base64,{1}'') format(''woff2'');
}}' + "`n"
        $fontCss += $template -f $weight, $b64
    } else {
        Write-Error "Font file missing: $fontPath. Please run scripts/download-fonts.ps1 first."
    }
}

# Encode Logo SVG/PNG
$logoPath = "assets/img/logo.png"
if (!(Test-Path $logoPath)) {
    $logoPath = "assets/img/logo.svg"
}
if (Test-Path $logoPath) {
    $logoBytes = [IO.File]::ReadAllBytes($logoPath)
    $logoB64 = [Convert]::ToBase64String($logoBytes)
    $ext = [System.IO.Path]::GetExtension($logoPath).Replace(".", "")
    $mime = "image/png"
    if ($ext -eq "svg") { $mime = "image/svg+xml" }
    $logoDataUri = 'data:{0};base64,{1}' -f $mime, $logoB64
    Write-Host "[ASSETS] Inlined logo: $logoPath"
} else {
    $logoDataUri = ""
    Write-Host "[ASSETS] Warning: No logo file found at assets/img/logo.png or logo.svg" -ForegroundColor Yellow
}

# Fetch QR Code SVG
$ctaUrl = $data.shareCard.ctaUrl
Write-Host "[ASSETS] Fetching QR Code SVG for ctaUrl: $ctaUrl..." -ForegroundColor Yellow
try {
    $encodedCta = [uri]::EscapeDataString($ctaUrl)
    $qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&format=svg&data=' + $encodedCta
    $qrSvg = Invoke-RestMethod -Uri $qrUrl
    $qrSvg = $qrSvg -replace '<\?xml[^>]*\?>', ''
    Write-Host "[ASSETS] QR Code successfully generated."
} catch {
    Write-Host "[ASSETS] Warning: Failed to fetch QR Code from API. Using fallback placeholder." -ForegroundColor Yellow
    $qrSvg = '<svg width="150" height="150" viewBox="0 0 150 150"><rect width="150" height="150" fill="#E2E8F0"/><text x="75" y="75" font-family="sans-serif" font-size="12" fill="#64748B" text-anchor="middle" dominant-baseline="middle">QR Offline</text></svg>'
}

# 4. RENDER TEMPLATE BLOCKS
Write-Host "[RENDER] Rendering templates components..." -ForegroundColor Yellow

# A. Render CSS Vars
$c = $theme.colors
$ts = $theme.typeScale
$cssVarsTemplate = @'
:root {{
  --bsc-blue:   {0};
  --bsc-teal:   {1};
  --bsc-gold:   {2};
  --positive:   {3};
  --negative:   {4};
  --neutral:    {5};
  --text-1:     {6};
  --text-2:     {7};
  --text-3:     {8};
  --bg-canvas:  {9};
  --surface:    {10};
  --card:       {11};
  --tint-blue:  {12};
  --tint-teal:  {13};
  --line:       {14};
  --fs-display: {15};
  --fs-h1:      {16};
  --fs-h2:      {17};
  --fs-h3:      {18};
  --fs-h4:      {19};
  --fs-body-lg: {20};
  --fs-body:    {21};
  --fs-label:   {22};
  --fs-caption: {23};
  --page-pad:   {24};
  --gap-section: {25};
  --gap-card:   12px;
  --card-pad:   {26};
}}
'@

$cssVars = $cssVarsTemplate -f $c.bscBlue, $c.bscTeal, $c.bscGold, $c.positive, $c.negative, $c.neutral,
    $c.textPrimary, $c.textSecondary, $c.textTertiary, $c.bgCanvas, $c.surface, $c.card, $c.tintBlue, $c.tintTeal, $c.line,
    $ts.display.size, $ts.h1.size, $ts.h2.size, $ts.h3.size, $ts.h4.size, $ts.bodyLg.size, $ts.body.size, $ts.label.size, $ts.caption.size,
    $theme.spacing.pagePadding, $theme.spacing.sectionGap, $theme.spacing.cardPad

# B. Render Fact Chips
$factChipsHtml = ""
foreach ($chip in $data.hero.factChips) {
    $factChipsHtml += '<span class="fact-chip"><strong>' + $chip.label + ':</strong> ' + $chip.value + '</span>' + "`n"
}

# C. Render Hero Stats
$heroStatsHtml = ""
foreach ($stat in $data.hero.heroStats) {
    $styleClass = $stat.style
    $unitHtml = ""
    if ($stat.unit) { 
        $unitHtml = ' <span class="hs-unit">' + $stat.unit + '</span>' 
    }
    $heroStatsHtml += '
    <div class="hero-stat ' + $styleClass + '">
      <div class="hs-label">' + $stat.label + '</div>
      <div class="hs-value ' + $styleClass + '" data-edit>' + $stat.value + $unitHtml + '</div>
      <div class="hs-sub" data-edit>' + $stat.sub + '</div>
    </div>'
}

# D. Render Table Rows
$rowTemplate = [System.IO.File]::ReadAllText((Join-Path $PWD "src/partials/rec-table-row.html"), [System.Text.Encoding]::UTF8)
$tableRowsHtml = ""
foreach ($row in $data.recTable.rows) {
    $pct = $row.weight
    $rowHtml = $rowTemplate
    $rowHtml = $rowHtml.Replace("{{ ticker }}", $row.ticker)
    $rowHtml = $rowHtml.Replace("{{ sector }}", $row.sector)
    $rowHtml = $rowHtml.Replace("{{ buyPrice }}", $row.buyPrice)
    $rowHtml = $rowHtml.Replace("{{ peTtm }}", $row.peTtm)
    $rowHtml = $rowHtml.Replace("{{ pbTtm }}", $row.pbTtm)
    $rowHtml = $rowHtml.Replace("{{ profitGrowth }}", $row.profitGrowth)
    $rowHtml = $rowHtml.Replace("{{ weight }}", $pct.ToString())
    $tableRowsHtml += $rowHtml
}

# E. Render Legend
$legendHtml = ""
foreach ($item in $data.chart.legend) {
    $style = "background:" + $item.color
    if ($item.label -like "*MSCI*") {
        $style = "height:2px;border-top:2px dashed " + $item.color + ";background:transparent"
    }
    $legendHtml += '<div class="legend-item"><div class="legend-line" style="' + $style + '"></div><span>' + $item.label + '</span></div>'
}

# F. Render Chart SVG parts
$xLabels = $data.chart.data.labels
$xHtml = ""
$xWidth = 768
$xStep = $xWidth / ($xLabels.Count - 1)
for ($i = 0; $i -lt $xLabels.Count; $i++) {
    $xPos = 120 + ($i * $xStep)
    $xHtml += '<text x="' + $xPos + '" y="190" font-size="12" fill="#64748B" text-anchor="middle" font-family="Nunito,sans-serif">' + $xLabels[$i] + '</text>' + "`n"
}

# Render Paths
$pData = $data.chart.data.portfolio
$vData = $data.chart.data.vnindex
$pointsP = ""
$pointsV = ""

for ($i = 0; $i -lt $xLabels.Count; $i++) {
    $xPos = 120 + ($i * $xStep)
    $yP = 160 - (($pData[$i] - 100) * 4)
    $yV = 160 - (($vData[$i] - 100) * 4)
    
    $pointsP += "$xPos,$yP "
    $pointsV += "$xPos,$yV "
}

$chartPathsHtml = '
<polygon points="120,160 ' + $pointsP + ' 888,160 120,160" fill="url(#grad-portfolio)"/>
<polyline points="' + $pointsP + '" fill="none" stroke="' + $c.bscBlue + '" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
<polygon points="120,160 ' + $pointsV + ' 888,160 120,160" fill="url(#grad-vni)"/>
<polyline points="' + $pointsV + '" fill="none" stroke="' + $c.bscTeal + '" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>
'

# Dots
$lastIdx = $xLabels.Count - 1
$lastXP = 120 + ($lastIdx * $xStep)
$lastYP = 160 - (($pData[$lastIdx] - 100) * 4)
$lastYV = 160 - (($vData[$lastIdx] - 100) * 4)
$chartDotsHtml = '
<circle cx="' + $lastXP + '" cy="' + $lastYP + '" r="4" fill="' + $c.bscBlue + '"/>
<circle cx="' + $lastXP + '" cy="' + $lastYV + '" r="4" fill="' + $c.bscTeal + '"/>
'

# End labels
$chartEndLabelsHtml = '
<text x="895" y="' + ($lastYP + 4) + '" font-size="12" fill="' + $c.bscBlue + '" font-weight="700" font-family="Nunito,sans-serif">' + $data.chart.annotations.portfolioReturn + '</text>
<text x="895" y="' + ($lastYV + 4) + '" font-size="12" fill="' + $c.bscTeal + '" font-weight="700" font-family="Nunito,sans-serif">' + $data.chart.annotations.vnindexReturn + '</text>
'

# G. Render Heatmap Rows & Headers
$heatmapHeadersHtml = ""
foreach ($m in $data.heatmap.months) {
    $heatmapHeadersHtml += "<th>$m</th>"
}

$heatmapRowsHtml = ""
foreach ($row in $data.heatmap.rows) {
    $heatmapRowsHtml += '<tr><td class="year-cell">' + $row.year + '</td>'
    for ($i = 0; $i -lt $data.heatmap.months.Count - 1; $i++) {
        $val = $row.data[$i]
        if ($null -eq $val) {
            $heatmapRowsHtml += '<td class="empty-cell">&amp;mdash;</td>'
        } else {
            $formatted = ""
            if ($val -gt 0) { $formatted = "+$val" } else { $formatted = "$val" }
            $styleAttr = ""
            if ($val -gt 0) {
                $alpha = [math]::Min(0.1 + ($val / 20.0), 0.7)
                $alphaStr = $alpha.ToString([System.Globalization.CultureInfo]::InvariantCulture)
                $styleAttr = 'style="background:rgba(22,163,74,' + $alphaStr + ');color:#14532D"'
            } elseif ($val -lt 0) {
                $alpha = [math]::Min(0.1 + ([math]::Abs($val) / 20.0), 0.7)
                $alphaStr = $alpha.ToString([System.Globalization.CultureInfo]::InvariantCulture)
                $styleAttr = 'style="background:rgba(220,38,38,' + $alphaStr + ');color:#7F1D1D"'
            }
            $heatmapRowsHtml += '<td ' + $styleAttr + '>' + $formatted + '</td>'
        }
    }
    $totalVal = $row.data[$row.data.Count - 1]
    $formattedTotal = ""
    if ($totalVal -gt 0) { $formattedTotal = "+$totalVal%" } else { $formattedTotal = "$totalVal%" }
    $heatmapRowsHtml += '<td class="total-cell" data-edit>' + $formattedTotal + '</td></tr>' + "`n"
}

# H. Render Stock Cards
$cardTemplate = [System.IO.File]::ReadAllText((Join-Path $PWD "src/partials/stock-card-item.html"), [System.Text.Encoding]::UTF8)
$stockCardsHtml = ""
foreach ($sc in ($data.stockCards | Select-Object -First 2)) {
    $matchRow = $data.recTable.rows | Where-Object { $_.ticker -eq $sc.ticker }
    $upside = $matchRow.upside
    $target = $matchRow.targetPrice
    $current = $matchRow.currentPrice
    
    $metricsHtml = ""
    foreach ($m in $sc.metrics) {
        $metricsHtml += '<div><div class="m-label">' + $m.label + '</div><div class="m-value" data-edit>' + $m.value + '</div></div>'
    }
    
    $scHtml = $cardTemplate
    $scHtml = $scHtml.Replace("##TICKER##", $sc.ticker)
    $scHtml = $scHtml.Replace("##COMPANY##", $sc.company)
    $scHtml = $scHtml.Replace("##WEIGHT##", $sc.weight)
    $scHtml = $scHtml.Replace("##METRICS##", $metricsHtml)
    
    $stockCardsHtml += $scHtml
}

# I. Render Contact Block
$contactHtml = ""
foreach ($con in $data.contacts) {
    $contactHtml += '
    <div class="contact-item">
      <strong>' + $con.name + '</strong>
      Tel: ' + $con.phone + ' - Email: ' + $con.email + '
    </div>'
}

# J. Render Share Stock Cards
$shareStockCardsHtml = ""
$shareCardTmpl = [System.IO.File]::ReadAllText((Join-Path $PWD "src/partials/share-stock-card-item.html"), [System.Text.Encoding]::UTF8)
foreach ($sc in ($data.stockCards | Select-Object -First 2)) {
    $scHtml = $shareCardTmpl
    $scHtml = $scHtml.Replace("{{ ticker }}", $sc.ticker)
    $scHtml = $scHtml.Replace("{{ sector }}", $sc.company)
    $scHtml = $scHtml.Replace("{{ weight }}", $sc.weight)
    $scHtml = $scHtml.Replace("{{ mcap }}", $sc.metrics[0].value)
    $scHtml = $scHtml.Replace("{{ liq }}", $sc.metrics[1].value)
    $scHtml = $scHtml.Replace("{{ float }}", $sc.metrics[2].value.Replace("%",""))
    $scHtml = $scHtml.Replace("{{ growth }}", $sc.metrics[3].value.Replace("%",""))
    $scHtml = $scHtml.Replace("{{ pe }}", $sc.metrics[4].value.Replace("x",""))
    $scHtml = $scHtml.Replace("{{ pb }}", $sc.metrics[5].value.Replace("x",""))
    $scHtml = $scHtml.Replace("{{ link }}", "#")
    $shareStockCardsHtml += $scHtml
}

# 5. COMPILE PARTIALS
Write-Host "[RENDER] Compiling partials..." -ForegroundColor Yellow

$partials = @{
    "topbar"      = "src/partials/topbar.html"
    "hero"        = "src/partials/hero.html"
    "rec-table"   = "src/partials/rec-table.html"
    "chart"       = "src/partials/chart.html"
    "heatmap"     = "src/partials/heatmap.html"
    "stock-cards" = "src/partials/stock-cards.html"
    "footer"      = "src/partials/footer.html"
}

$renderedPartials = @{}
foreach ($key in $partials.Keys) {
    $content = [System.IO.File]::ReadAllText((Join-Path $PWD $partials[$key]), [System.Text.Encoding]::UTF8)
    
    $content = $content.Replace("{{ topbar.brandLabel }}", $data.topbar.brandLabel)
    $content = $content.Replace("{{ topbar.divisionLabel }}", $data.topbar.divisionLabel)
    $content = $content.Replace("{{ topbar.metaLine1 }}", $data.topbar.metaLine1)
    $content = $content.Replace("{{ topbar.metaLine2 }}", $data.topbar.metaLine2)
    $content = $content.Replace("{{ meta.issueDate }}", $data.meta.issueDate)
    $content = $content.Replace("{{ hero.tag }}", $data.hero.tag)
    $content = $content.Replace("{{ hero.title }}", $data.hero.title)
    $content = $content.Replace("{{ hero.lede }}", $data.hero.lede)
    $content = $content.Replace("{{ recTable.sectionLabel }}", $data.recTable.sectionLabel)
    $content = $content.Replace("{{ recTable.sectionSub }}", $data.recTable.sectionSub)
    $content = $content.Replace("{{ recTable.footerRow.label }}", $data.recTable.footerRow.label)
    $content = $content.Replace("{{ recTable.footerRow.targetReturn }}", $data.recTable.footerRow.targetReturn)
    $content = $content.Replace("{{ recTable.footerRow.totalWeight }}", $data.recTable.footerRow.totalWeight)
    $content = $content.Replace("{{ chart.sectionLabel }}", $data.chart.sectionLabel)
    $content = $content.Replace("{{ chart.title }}", $data.chart.title)
    $content = $content.Replace("{{ chart.annotations.portfolioReturn }}", $data.chart.annotations.portfolioReturn)
    $content = $content.Replace("{{ chart.annotations.vnindexReturn }}", $data.chart.annotations.vnindexReturn)
    $content = $content.Replace("{{ chart.annotations.alpha }}", $data.chart.annotations.alpha)
    $content = $content.Replace("{{ heatmap.sectionLabel }}", $data.heatmap.sectionLabel)
    $content = $content.Replace("{{ heatmap.sectionSub }}", $data.heatmap.sectionSub)
    $content = $content.Replace("{{ legalText }}", $data.legalText)
    $content = $content.Replace("{{ copyrightYear }}", $data.copyrightYear)
    
    $content = $content.Replace("##LOGO_BASE64##", $logoDataUri)
    $content = $content.Replace("##FACT_CHIPS##", $factChipsHtml)
    $content = $content.Replace("##HERO_STATS##", $heroStatsHtml)
    $content = $content.Replace("##TABLE_ROWS##", $tableRowsHtml)
    $content = $content.Replace("##CHART_LEGEND##", $legendHtml)
    $content = $content.Replace("##CHART_X_AXIS##", $xHtml)
    $content = $content.Replace("##CHART_PATHS##", $chartPathsHtml)
    $content = $content.Replace("##CHART_DOTS##", $chartDotsHtml)
    $content = $content.Replace("##CHART_END_LABELS##", $chartEndLabelsHtml)
    $content = $content.Replace("##HEATMAP_HEADERS##", $heatmapHeadersHtml)
    $content = $content.Replace("##HEATMAP_ROWS##", $heatmapRowsHtml)
    $content = $content.Replace("##STOCK_CARDS##", $stockCardsHtml)
    $content = $content.Replace("##CONTACT_BLOCK##", $contactHtml)
    
    $renderedPartials[$key] = $content
}

# 6. COMPILE TARGETS
$destDir = "dist/$docCode"
if (!(Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir | Out-Null
}

$targets = @("web", "print", "share")
foreach ($t in $targets) {
    $tmplPath = "src/templates/$t.html"
    Write-Host "[RENDER] Rendering target $t ($tmplPath)..." -ForegroundColor Yellow
    $html = [System.IO.File]::ReadAllText((Join-Path $PWD $tmplPath), [System.Text.Encoding]::UTF8)
    
    $html = $html.Replace("##THEME_FONTS##", $fontCss)
    $html = $html.Replace("##LOGO_BASE64##", $logoDataUri)
    $html = $html.Replace("{{ meta.disclaimer }}", $data.meta.disclaimer)
    $html = $html.Replace("{{ meta.reportTitle }}", $data.meta.reportTitle)
    $html = $html.Replace("{{ meta.period }}", $data.meta.period)
    $html = $html.Replace("{{ meta.docCode }}", $data.meta.docCode)
    $html = $html.Replace("{{ meta.division }}", $data.meta.division)

    if ($t -eq "share") {
        $shareCss = [System.IO.File]::ReadAllText((Join-Path $PWD "src/templates/share-css.css"), [System.Text.Encoding]::UTF8)
        $html = $html.Replace("##THEME_CSS_VARIABLES##", $cssVars + "`n" + $shareCss)
        $html = $html.Replace("##PARTIAL_HERO##", $renderedPartials["hero"])
        $html = $html.Replace("{{ shareCard.disclaimerShort }}", $data.shareCard.disclaimerShort)
        $html = $html.Replace("##SHARE_STOCK_CARDS##", $shareStockCardsHtml)
        $html = $html.Replace("##SHARE_QR_CODE##", $qrSvg)
        $html = $html.Replace("##PARTIAL_CHART##", $renderedPartials["chart"])
    } else {
        $html = $html.Replace("##THEME_CSS_VARIABLES##", $cssVars)
        $html = $html.Replace("##PARTIAL_TOPBAR##", $renderedPartials["topbar"])
        $html = $html.Replace("##PARTIAL_HERO##", $renderedPartials["hero"])
        $html = $html.Replace("##PARTIAL_REC_TABLE##", $renderedPartials["rec-table"])
        $html = $html.Replace("##PARTIAL_CHART##", $renderedPartials["chart"])
        $html = $html.Replace("##PARTIAL_HEATMAP##", $renderedPartials["heatmap"])
        $html = $html.Replace("##PARTIAL_STOCK_CARDS##", $renderedPartials["stock-cards"])
        $html = $html.Replace("##PARTIAL_FOOTER##", $renderedPartials["footer"])
    }

    
    $destPath = Join-Path $destDir "$t.html"
    [IO.File]::WriteAllText($destPath, $html, [Text.Encoding]::UTF8)
    $sizeKb = [math]::Round((Get-Item $destPath).Length / 1KB)
    Write-Host "[OK] Created: $destPath ($sizeKb KB)" -ForegroundColor Green
}

Copy-Item "$destDir/web.html" "dist/index-web.html" -Force
Copy-Item "$destDir/web.html" "dist/web.html" -Force
Copy-Item "$destDir/print.html" "dist/print.html" -Force
Copy-Item "$destDir/share.html" "dist/share.html" -Force
Write-Host "`n[DONE] Build completed successfully!" -ForegroundColor Green
Write-Host "[HINT] Run export.ps1 to generate PDF and Share PNG."
