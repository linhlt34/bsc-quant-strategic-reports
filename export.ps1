# BSC Quant Research - Windows export entry point
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$programFilesX86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
$programFiles = [Environment]::GetEnvironmentVariable("ProgramFiles")
$edgeCandidates = @(
  @(
    (Join-Path $programFilesX86 "Microsoft\Edge\Application\msedge.exe"),
    (Join-Path $programFiles "Microsoft\Edge\Application\msedge.exe")
  ) | Where-Object { $_ -and (Test-Path $_) }
)

if (-not $edgeCandidates) {
  throw "Microsoft Edge was not found. It is required for PDF/PNG export."
}
$edgePath = $edgeCandidates[0]

$dataFile = "data/generated/report-data.json"
if (-not (Test-Path $dataFile)) {
  throw "Missing data/generated/report-data.json. Run build.ps1 before export.ps1."
}
$data = Get-Content $dataFile -Raw -Encoding UTF8 | ConvertFrom-Json
$docCode = $data.meta.docCode
$destDir = Join-Path $projectRoot "dist/$docCode"
if (-not (Test-Path $destDir)) {
  throw "Missing dist/$docCode. Run build.ps1 before export.ps1."
}

$tempDir = Join-Path $env:TEMP "bsc-quant-export"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

$printHtml = Join-Path $destDir "print.html"
$shareHtml = Join-Path $destDir "share.html"
$pdfTemp = Join-Path $tempDir "print.pdf"
$pngTemp = Join-Path $tempDir "share.png"
$profile = Join-Path $tempDir "edge-profile"

& $edgePath --headless --disable-gpu --no-sandbox --user-data-dir="$profile" --print-to-pdf="$pdfTemp" --print-to-pdf-no-header "$printHtml"
$pdfExitCode = $LASTEXITCODE
for ($i = 0; $i -lt 20 -and -not (Test-Path $pdfTemp); $i++) {
  Start-Sleep -Milliseconds 250
}
if (-not (Test-Path $pdfTemp)) {
  throw "PDF export failed."
}
if ($null -ne $pdfExitCode -and $pdfExitCode -ne 0) {
  Write-Host "[WARN] Edge returned exit code $pdfExitCode after writing PDF." -ForegroundColor Yellow
}

& $edgePath --headless --disable-gpu --no-sandbox --user-data-dir="$profile" --screenshot="$pngTemp" --window-size=1200,1500 --hide-scrollbars "$shareHtml"
$pngExitCode = $LASTEXITCODE
for ($i = 0; $i -lt 20 -and -not (Test-Path $pngTemp); $i++) {
  Start-Sleep -Milliseconds 250
}
if (-not (Test-Path $pngTemp)) {
  throw "Share image export failed."
}
if ($null -ne $pngExitCode -and $pngExitCode -ne 0) {
  Write-Host "[WARN] Edge returned exit code $pngExitCode after writing share image." -ForegroundColor Yellow
}

Copy-Item $pdfTemp (Join-Path $destDir "print.pdf") -Force
Copy-Item $pngTemp (Join-Path $destDir "share.png") -Force
Copy-Item $pdfTemp "dist/print.pdf" -Force
Copy-Item $pngTemp "dist/share.png" -Force
for ($i = 0; $i -lt 10 -and (Test-Path $tempDir); $i++) {
  try {
    Remove-Item $tempDir -Recurse -Force -ErrorAction Stop
  } catch {
    Start-Sleep -Milliseconds 500
  }
}
if (Test-Path $tempDir) {
  Write-Host "[WARN] Temporary export folder is still locked: $tempDir" -ForegroundColor Yellow
}
Write-Host "[DONE] Exported PDF and PNG to dist/$docCode" -ForegroundColor Green