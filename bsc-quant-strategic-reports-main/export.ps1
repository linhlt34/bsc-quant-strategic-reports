# BSC Quant Research - Windows export entry point
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$edgeCandidates = @(
  "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { $_ -and (Test-Path $_) }
if (-not $edgeCandidates) { throw "Microsoft Edge was not found." }
$edgePath = $edgeCandidates[0]

$data = Get-Content "data/generated/report-data.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$docCode = $data.meta.docCode
$destDir = Join-Path $projectRoot "dist/$docCode"
if (-not (Test-Path $destDir)) { throw "Run build.ps1 before export.ps1." }

$tempDir = Join-Path $env:TEMP "bsc-quant-export"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

$printHtml = (Join-Path $destDir "print.html")
$shareHtml = (Join-Path $destDir "share.html")
$pdfTemp = Join-Path $tempDir "print.pdf"
$pngTemp = Join-Path $tempDir "share.png"
$profile = Join-Path $tempDir "edge-profile"

& $edgePath --headless --disable-gpu --no-sandbox --user-data-dir="$profile" --print-to-pdf="$pdfTemp" --print-to-pdf-no-header "$printHtml"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $pdfTemp)) { throw "PDF export failed." }

& $edgePath --headless --disable-gpu --no-sandbox --user-data-dir="$profile" --screenshot="$pngTemp" --window-size=1200,1500 --hide-scrollbars "$shareHtml"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $pngTemp)) { throw "Share image export failed." }

Copy-Item $pdfTemp (Join-Path $destDir "print.pdf") -Force
Copy-Item $pngTemp (Join-Path $destDir "share.png") -Force
Copy-Item $pdfTemp "dist/print.pdf" -Force
Copy-Item $pngTemp "dist/share.png" -Force
Remove-Item $tempDir -Recurse -Force
Write-Host "[DONE] Exported PDF and PNG to dist/$docCode" -ForegroundColor Green
