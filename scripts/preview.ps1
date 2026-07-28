$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Start-Process (Join-Path $projectRoot "dist/index.html")
