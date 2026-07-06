$CsvPath = "ganhos_temp.csv"
$Data = Import-Csv -Path $CsvPath -Encoding UTF8

Write-Host "Total rows imported: $($Data.Count)"
if ($Data.Count -gt 0) {
    Write-Host "First row properties:"
    $First = $Data[0]
    foreach ($prop in $First.PSObject.Properties) {
        Write-Host "  $($prop.Name) = $($prop.Value)"
    }
}

Write-Host "`nLast 5 rows:"
$count = $Data.Count
for ($i = [Math]::Max(0, $count - 5); $i -lt $count; $i++) {
    $row = $Data[$i]
    Write-Host "Row $i`:"
    foreach ($prop in $row.PSObject.Properties) {
        Write-Host "  $($prop.Name) = $($prop.Value)"
    }
}

