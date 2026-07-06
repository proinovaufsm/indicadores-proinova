# PowerShell script to download and process the "Propriedade Intelectual" data
$WorkspaceDir = "c:\Users\PROINOVA\Documents\Projetos IA\BI"

$DepositosUrl = "https://docs.google.com/spreadsheets/d/1bbggicJTbGSlMNlTejCMIf4q-lSsD_-_/export?format=csv&gid=1043650506"
$ConcedidosUrl = "https://docs.google.com/spreadsheets/d/1bbggicJTbGSlMNlTejCMIf4q-lSsD_-_/export?format=csv&gid=1892076428"

$TempCsvDepositos = Join-Path $WorkspaceDir "pi_depositos_raw.csv"
$TempCsvConcedidos = Join-Path $WorkspaceDir "pi_concedidos_raw.csv"

# Helper function to clean integers
function Clean-Int($val) {
    if ($null -eq $val -or $val.Trim() -eq "" -or $val.Trim() -eq "---" -or $val -like "*#VALUE*") {
        return 0
    }
    $cleaned = $val.Trim() -replace "\s", ""
    $outVal = 0
    if ([int]::TryParse($cleaned, [ref]$outVal)) {
        return $outVal
    }
    return 0
}

# 1. PROCESS DEPOSITOS
Write-Host "Downloading Depositos..."
try {
    Invoke-WebRequest -Uri $DepositosUrl -OutFile $TempCsvDepositos -TimeoutSec 15 -ErrorAction Stop
} catch {
    Write-Error "Failed to download Depositos: $_"
    Exit 1
}

$RawLinesDep = Get-Content $TempCsvDepositos -Encoding UTF8
$NewHeaderDep = "Ano,Patente,Removido,ProgramaComputador,DesenhoIndustrial,Marca,Cultivar,Total"
$CsvDataStringDep = @($NewHeaderDep) + $RawLinesDep[1..($RawLinesDep.Length-1)] | Out-String
$RawRecordsDep = ConvertFrom-Csv -InputObject $CsvDataStringDep

$CleanedDepositos = foreach ($row in $RawRecordsDep) {
    $anoStr = $row.Ano.Trim()
    if ([string]::IsNullOrWhitespace($anoStr) -or $anoStr -eq "Total" -or $anoStr.StartsWith("Revisado") -or $anoStr.StartsWith("Atualizado") -or $anoStr.StartsWith("Sistema") -or $anoStr.StartsWith("Observação")) {
        continue
    }
    if (-not ($anoStr -match "^\d{4}")) {
        continue
    }
    [PSCustomObject]@{
        ano = $anoStr
        patente = Clean-Int $row.Patente
        programa_computador = Clean-Int $row.ProgramaComputador
        desenho_industrial = Clean-Int $row.DesenhoIndustrial
        marca = Clean-Int $row.Marca
        cultivar = Clean-Int $row.Cultivar
        total = Clean-Int $row.Total
    }
}

# 2. PROCESS CONCEDIDOS
Write-Host "Downloading Concedidos..."
try {
    Invoke-WebRequest -Uri $ConcedidosUrl -OutFile $TempCsvConcedidos -TimeoutSec 15 -ErrorAction Stop
} catch {
    Write-Error "Failed to download Concedidos: $_"
    Exit 1
}

$RawLinesConc = Get-Content $TempCsvConcedidos -Encoding UTF8
$NewHeaderConc = "Ano,Patente,PIExterior,ProgramaComputador,DesenhoIndustrial,Marca,Cultivar,Total"
$CsvDataStringConc = @($NewHeaderConc) + $RawLinesConc[1..($RawLinesConc.Length-1)] | Out-String
$RawRecordsConc = ConvertFrom-Csv -InputObject $CsvDataStringConc

$CleanedConcedidos = foreach ($row in $RawRecordsConc) {
    $anoStr = $row.Ano.Trim()
    if ([string]::IsNullOrWhitespace($anoStr) -or $anoStr -eq "Total" -or $anoStr.StartsWith("Revisado") -or $anoStr.StartsWith("Atualizado") -or $anoStr.StartsWith("Sistema") -or $anoStr.StartsWith("Observação")) {
        continue
    }
    if (-not ($anoStr -match "^\d{4}")) {
        continue
    }
    
    # Patente counts are the sum of local patents and external patents
    $patVal = (Clean-Int $row.Patente) + (Clean-Int $row.PIExterior)
    
    [PSCustomObject]@{
        ano = $anoStr
        patente = $patVal
        programa_computador = Clean-Int $row.ProgramaComputador
        desenho_industrial = Clean-Int $row.DesenhoIndustrial
        marca = Clean-Int $row.Marca
        cultivar = Clean-Int $row.Cultivar
        total = Clean-Int $row.Total
    }
}

Write-Host "Depositos: $($CleanedDepositos.Count) rows. Concedidos: $($CleanedConcedidos.Count) rows."

# Convert to JSON objects
$JsonDep = $CleanedDepositos | ConvertTo-Json -Depth 4
$JsonConc = $CleanedConcedidos | ConvertTo-Json -Depth 4

# Write as JavaScript file with both datasets
$JsContent = "// UFSM BI Propriedade Intelectual Pre-loaded Data`nvar initialPiData = $JsonDep;`nvar initialPiConcedidos = $JsonConc;"
$JsPath = Join-Path $WorkspaceDir "pi_data.js"
[System.IO.File]::WriteAllText($JsPath, $JsContent, [System.Text.Encoding]::UTF8)
Write-Host "Saved pi_data.js successfully."

# Write as JSON files
$JsonContent = @{
    depositos = $CleanedDepositos
    concedidos = $CleanedConcedidos
} | ConvertTo-Json -Depth 4
$JsonPath = Join-Path $WorkspaceDir "pi_data.json"
[System.IO.File]::WriteAllText($JsonPath, $JsonContent, [System.Text.Encoding]::UTF8)
Write-Host "Saved pi_data.json successfully."

# Cleanup
if (Test-Path $TempCsvDepositos) { Remove-Item $TempCsvDepositos }
if (Test-Path $TempCsvConcedidos) { Remove-Item $TempCsvConcedidos }
