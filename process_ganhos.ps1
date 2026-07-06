# PowerShell script to download and process the "Ganhos Econômicos PI" data

$CsvUrl = "https://docs.google.com/spreadsheets/d/1Ybhp3gQvH1vA8-xBiteq18VgObN3vggv/export?format=csv&gid=1299353642"
$WorkspaceDir = "c:\Users\PROINOVA\Documents\Projetos IA\BI"
$TempCsvPath = Join-Path $WorkspaceDir "ganhos_temp_raw.csv"

Write-Host "Downloading Ganhos Econômicos PI CSV..."
try {
    Invoke-WebRequest -Uri $CsvUrl -OutFile $TempCsvPath -TimeoutSec 15
    Write-Host "Downloaded raw CSV."
} catch {
    Write-Error "Failed to download Ganhos Econômicos PI: $_"
    Exit 1
}

# Read raw lines
$RawLines = Get-Content $TempCsvPath -Encoding UTF8

if ($RawLines.Length -le 1) {
    Write-Error "CSV is empty!"
    Exit 1
}

# The header in the sheet is: Data,Descrição,Departamento,Fundação,Valor,UFSM,Departamento,Inventor
# We will replace it with a clean, unique header line:
# Data,Descricao,Departamento,Fundacao,Valor_Total,Valor_UFSM,Valor_Departamento,Valor_Inventor
$NewHeader = "Data,Descricao,Departamento,Fundacao,Valor_Total,Valor_UFSM,Valor_Departamento,Valor_Inventor"
$CsvDataString = @($NewHeader) + $RawLines[1..($RawLines.Length-1)] | Out-String

# Now parse using ConvertFrom-Csv
$RawRecords = ConvertFrom-Csv -InputObject $CsvDataString

Write-Host "Parsed $($RawRecords.Count) rows from CSV."

# Cleaning helper functions
function Clean-Currency($val) {
    if ($null -eq $val -or $val -eq "" -or $val -eq "---" -or $val -like "*#VALUE*") {
        return 0.0
    }
    # Remove R$, dots, spaces and replace comma with dot
    $cleaned = $val -replace "R`\$", "" -replace "\.", "" -replace ",", "." -replace "\s", ""
    $cleaned = $cleaned -replace "[^\d\.-]", ""
    
    $outVal = 0.0
    if ([double]::TryParse($cleaned, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$outVal)) {
        return $outVal
    }
    return 0.0
}

function Clean-Text($val) {
    if ($null -eq $val) { return "" }
    return $val.Trim()
}

$CleanedGanhos = foreach ($row in $RawRecords) {
    # Skip rows without a valid date or where Valor_Total is empty/zero
    if ([string]::IsNullOrWhitespace($row.Data) -or $row.Data -eq "Total" -or $row.Data -eq "Data") {
        continue
    }

    # Extract date parts
    $dateStr = $row.Data.Trim()
    $day = $null
    $mes = $null
    $ano = $null
    
    # Try parsing date format: d/M/yyyy or d/M/yy
    if ($dateStr -match "^(\d{1,2})/(\d{1,2})/(\d{2,4})$") {
        $p1 = [int]$Matches[1]
        $p2 = [int]$Matches[2]
        $ano = [int]$Matches[3]
        if ($ano -lt 100) {
            $ano += 2000 # assume 20xx
        }
        if ($p1 -gt 12) {
            $day = $p1
            $mes = $p2
        } elseif ($p2 -gt 12) {
            $day = $p2
            $mes = $p1
        } else {
            $day = $p1
            $mes = $p2
        }
    } elseif ($dateStr -match "^(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})$") {
        $ano = [int]$Matches[1]
        $mes = [int]$Matches[2]
        $day = [int]$Matches[3]
    }

    if ($null -eq $ano) {
        # Skip if we can't parse a year, as it might be a header or footer
        continue
    }

    $valorTotal = Clean-Currency $row.Valor_Total
    $valorUfsm = Clean-Currency $row.Valor_UFSM
    $valorDept = Clean-Currency $row.Valor_Departamento
    $valorInventor = Clean-Currency $row.Valor_Inventor

    # If all values are 0, skip
    if ($valorTotal -eq 0 -and $valorUfsm -eq 0 -and $valorDept -eq 0 -and $valorInventor -eq 0) {
        continue
    }

    [PSCustomObject]@{
        data               = $dateStr
        dia                = $day
        mes                = $mes
        ano                = $ano
        descricao          = Clean-Text $row.Descricao
        departamento       = Clean-Text $row.Departamento
        fundacao           = Clean-Text $row.Fundacao
        valor_total        = $valorTotal
        valor_ufsm         = $valorUfsm
        valor_departamento = $valorDept
        valor_inventor     = $valorInventor
    }
}

Write-Host "Processed $($CleanedGanhos.Count) clean records."

# Output as JSON
$JsonData = ConvertTo-Json -InputObject $CleanedGanhos -Depth 5
$JsonPath = Join-Path $WorkspaceDir "ganhos_data.json"
[System.IO.File]::WriteAllText($JsonPath, $JsonData, [System.Text.Encoding]::UTF8)
Write-Host "Saved JSON to: $JsonPath"

# Output as JS
$JsContent = "// UFSM BI Ganhos Economicos PI Pre-loaded Data`nvar initialGanhosData = $JsonData;"
$JsPath = Join-Path $WorkspaceDir "ganhos_data.js"
[System.IO.File]::WriteAllText($JsPath, $JsContent, [System.Text.Encoding]::UTF8)
Write-Host "Saved JS to: $JsPath"

# Clean up temp files
if (Test-Path $TempCsvPath) {
    Remove-Item $TempCsvPath
}
if (Test-Path "ganhos_temp.csv") {
    Remove-Item "ganhos_temp.csv"
}

Write-Host "Ganhos Econômicos PI data processing completed!"
