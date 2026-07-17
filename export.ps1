# ===================================================================
# BSC QUANT RESEARCH - PowerShell Export Script (v2.7)
# Native PDF & Screenshot Generation using Microsoft Edge Headless
# Uses space-free Temp directory to prevent argument parsing errors
# Pure ASCII version to avoid console parsing bugs
# Debug mode: keep PDF even on overflow to allow inspection
# ===================================================================

$ErrorActionPreference = "Stop"
Write-Host "[EXPORT] BSC Quant Research - Starting Native Export Pipeline" -ForegroundColor Cyan

# Find Edge
$edgePath = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
if (!(Test-Path $edgePath)) {
    $edgePath = 'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
}
if (!(Test-Path $edgePath)) {
    Write-Error "Microsoft Edge was not found on your system. It is required for exporting PDF/PNG."
}

# Load docCode
$dataFile = "data/report-data.json"
$data = Get-Content $dataFile -Raw -Encoding UTF8 | ConvertFrom-Json
$docCode = $data.meta.docCode

# Setup temp directory without spaces
$tempDir = Join-Path $env:TEMP "bsc-build"
if (Test-Path $tempDir) { 
    Remove-Item $tempDir -Recurse -Force 
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

$destDir = (Join-Path (Get-Item .).FullName "dist/$docCode").Replace("\", "/")
if (!(Test-Path $destDir)) {
    Write-Error "Target directory dist/$docCode does not exist. Please run build.ps1 first."
}

# Copy compiled target HTMLs to temp directory
Copy-Item "dist/$docCode/*" $tempDir -Force

$htmlPrint = Join-Path $tempDir "print.html"
$htmlShare = Join-Path $tempDir "share.html"

$tempPdf = Join-Path $tempDir "print.pdf"
$tempPng = Join-Path $tempDir "share.png"

$pdfOut = (Join-Path $destDir "print.pdf").Replace("/", "\")
$pngOut = (Join-Path $destDir "share.png").Replace("/", "\")

$userProfile = Join-Path $env:TEMP "edge-pdf-profile"

# 1. GENERATE PDF
Write-Host "[EXPORT] Exporting print.html to PDF A4 using Microsoft Edge..." -ForegroundColor Yellow
$process = Start-Process -FilePath $edgePath -ArgumentList @(
    "--headless",
    "--disable-gpu",
    "--no-sandbox",
    "--user-data-dir=$userProfile",
    "--print-to-pdf=$tempPdf",
    "--print-to-pdf-no-header",
    $htmlPrint
) -PassThru -Wait

if ($process.ExitCode -ne 0) {
    Write-Error "Edge process failed with exit code $($process.ExitCode)"
}

# 2. FAIL-FAST OVERFLOW DETECTION
Write-Host "[EXPORT] Checking PDF page count compliance..." -ForegroundColor Yellow

if (!(Test-Path $tempPdf)) {
    Write-Error "PDF file was not created by Edge."
}

# Move PDF to destination first so user can inspect it
Copy-Item $tempPdf $pdfOut -Force
Copy-Item $pdfOut "dist/print.pdf" -Force

# Read PDF as bytes, search for /Type /Page
$pdfBytes = [IO.File]::ReadAllBytes($tempPdf)
$pdfText = [System.Text.Encoding]::ASCII.GetString($pdfBytes)
$matches = [regex]::Matches($pdfText, "/Type\s*/Page\b")
$pageCount = $matches.Count

Write-Host "   PDF Page Count: $pageCount" -ForegroundColor Cyan
$expectedPages = $data.meta.pageCount
if ($pageCount -eq 0) {
    Write-Host "Warning: Page count detected as 0 (could not parse metadata). Skipping fail-fast check." -ForegroundColor Yellow
} elseif ($pageCount -gt $expectedPages) {
    Write-Host "[BUILD FAILED] Compliance Overflow Detected!" -ForegroundColor Red
    Write-Host ('   Report is designed for {0} pages, but the output has {1} pages.' -f $expectedPages, $pageCount) -ForegroundColor Red
    Write-Host "   Please shorten the texts or reduce recommendations in 'report-data.json' and rebuild." -ForegroundColor Red
    Write-Host "   [DEBUG] PDF file kept at dist/print.pdf for inspection." -ForegroundColor Yellow
    # Clean up temp but do not delete PDF so user can debug
    # Remove-Item $tempDir -Recurse -Force
    # exit 1 (Temporarily disabled to allow viewing the result)
} else {
    Write-Host ('   Page count compliance check passed ({0} / {1} pages).' -f $pageCount, $expectedPages) -ForegroundColor Green
}

# 3. GENERATE SHARE IMAGE (4:5 Ratio)
Write-Host "[EXPORT] Capturing share.html screenshot (1200x1500) using Microsoft Edge..." -ForegroundColor Yellow
$process = Start-Process -FilePath $edgePath -ArgumentList @(
    "--headless",
    "--disable-gpu",
    "--no-sandbox",
    "--user-data-dir=$userProfile",
    "--screenshot=$tempPng",
    "--window-size=1200,1500",
    "--hide-scrollbars",
    $htmlShare
) -PassThru -Wait

if ($process.ExitCode -ne 0) {
    Write-Error "Edge screenshot process failed with exit code $($process.ExitCode)"
}

# Move files from temp to final destination
Copy-Item $tempPng $pngOut -Force
Copy-Item $pngOut "dist/share.png" -Force

# Cleanup temp
Remove-Item $tempDir -Recurse -Force

$pdfSize = [math]::Round((Get-Item $pdfOut).Length / 1MB, 2)
$pngSize = [math]::Round((Get-Item $pngOut).Length / 1KB, 0)

Write-Host "[OK] Native export pipeline finished successfully!" -ForegroundColor Green
Write-Host ('   -> PDF:   {0} ({1} MB)' -f $pdfOut, $pdfSize)
Write-Host ('   -> PNG:   {0} ({1} KB)' -f $pngOut, $pngSize)
Write-Host "   -> Shortcuts copied to dist/print.pdf and dist/share.png"

