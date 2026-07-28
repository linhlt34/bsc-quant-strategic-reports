# BSC Quant Research - Windows build entry point
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command py -ErrorAction SilentlyContinue
}
if (-not $python) {
    throw "Python 3 was not found. Install Python 3.10+ and run build.ps1 again."
}

if ($python.Name -eq "py.exe") {
    & $python.Source -3 app/build.py
} else {
    & $python.Source app/build.py
}
if ($LASTEXITCODE -ne 0) {
    throw "Build failed with exit code $LASTEXITCODE"
}
