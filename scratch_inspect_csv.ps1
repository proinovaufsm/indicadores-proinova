$CsvUrl = "https://docs.google.com/spreadsheets/d/1PVyTdBjFmtqMMFt4OqiSHhofmOPx15Re_8ddEiNro6U/export?format=csv&gid=409266791"
$Response = Invoke-WebRequest -Uri $CsvUrl -UseBasicParsing -TimeoutSec 15
$bytes = $Response.Content
Write-Host "Total bytes: $($bytes.Length)"
# Print first 200 bytes as hex and as chars using different encodings
Write-Host "First 200 bytes:"
$hex = ""
for ($i=0; $i -lt [Math]::Min(200, $bytes.Length); $i++) {
    $hex += "{0:X2} " -f $bytes[$i]
}
Write-Host $hex

# Check decoding with CP1252 and UTF8
$str1252 = [System.Text.Encoding]::GetEncoding(1252).GetString($bytes, 0, [Math]::Min(1000, $bytes.Length))
$strUtf8 = [System.Text.Encoding]::UTF8.GetString($bytes, 0, [Math]::Min(1000, $bytes.Length))

Write-Host "`n--- Decode using CP1252 (first 500 chars) ---"
Write-Host $str1252.Substring(0, [Math]::Min(500, $str1252.Length))
Write-Host "`n--- Decode using UTF-8 (first 500 chars) ---"
Write-Host $strUtf8.Substring(0, [Math]::Min(500, $strUtf8.Length))
