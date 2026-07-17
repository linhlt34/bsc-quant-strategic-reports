$path = "data/report-data.json"
Copy-Item $path "$path.bak" -Force
$corruptedStr = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
$enc = [System.Text.Encoding]::GetEncoding(1252)
$bytes = $enc.GetBytes($corruptedStr)
$fixedStr = [System.Text.Encoding]::UTF8.GetString($bytes)

# Kiểm tra nếu decode thành công
if ($fixedStr -match "Danh mục") {
    [System.IO.File]::WriteAllText($path, $fixedStr, [System.Text.Encoding]::UTF8)
    Write-Host "Decoding success! Re-written to file."
} else {
    Write-Host "Decoding failed! Original string kept."
}
