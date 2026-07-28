# BSC Quant Research - Windows build entry point
$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

$entrypoint = Join-Path $projectRoot "src/bsc_quant_research/build.py"
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command py -ErrorAction SilentlyContinue
}
if (-not $python) {
    throw "Python 3 was not found. Install Python 3.10+ and run scripts/build.ps1 again."
}

if ($python.Name -eq "py.exe") {
    & $python.Source -3 $entrypoint
} else {
    & $python.Source $entrypoint
}
if ($LASTEXITCODE -ne 0) {
    throw "Build failed with exit code $LASTEXITCODE"
}