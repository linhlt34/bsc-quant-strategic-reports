$url = "https://fonts.googleapis.com/css2?family=Nunito:wght@400;500;600;700;800&display=swap"
$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}
Write-Host "Fetching Google Fonts CSS..."
$css = Invoke-RestMethod -Uri $url -Headers $headers

$fontDir = Join-Path (Get-Item .).FullName "assets/fonts"
if (!(Test-Path $fontDir)) {
    New-Item -ItemType Directory -Path $fontDir | Out-Null
}

# Regex to find vietnamese font-face blocks
# We split CSS by '@font-face' and process each block
$blocks = $css -split "@font-face"
$weights = @("400", "500", "600", "700", "800")
$names = @{
    "400" = "Nunito-Regular.woff2"
    "500" = "Nunito-Medium.woff2"
    "600" = "Nunito-SemiBold.woff2"
    "700" = "Nunito-Bold.woff2"
    "800" = "Nunito-ExtraBold.woff2"
}

foreach ($weight in $weights) {
    $targetBlock = $null
    foreach ($block in $blocks) {
        if ($block -like "*/* vietnamese */*" -and $block -like "*font-weight: $weight;*") {
            $targetBlock = $block
            break
        }
    }
    
    # Fallback to latin if vietnamese not found in split block
    if ($null -eq $targetBlock) {
        foreach ($block in $blocks) {
            if ($block -like "*font-weight: $weight;*") {
                $targetBlock = $block
                break
            }
        }
    }

    if ($targetBlock -and $targetBlock -match 'url\((https://fonts\.gstatic\.com/[^)]+\.woff2)\)') {
        $fontUrl = $Matches[1]
        $fileName = $names[$weight]
        $destPath = Join-Path $fontDir $fileName
        Write-Host "Downloading weight $weight from $fontUrl to $destPath..."
        Invoke-WebRequest -Uri $fontUrl -OutFile $destPath -Headers $headers
    } else {
        Write-Host "Could not find font URL for weight $weight"
    }
}
Write-Host "Done!"
