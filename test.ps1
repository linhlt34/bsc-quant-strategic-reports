$data = Get-Content "data/report-data.json" -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host $data.meta.reportTitle
