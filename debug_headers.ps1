# Script do PowerShell de diagnostico de cabecalhos

$LocalFallback = "C:\Users\PROINOVA\.gemini\antigravity-ide\brain\e7e2ae65-5067-4020-b1af-415a085083a2\.system_generated\steps\7\content.md"
$WorkspaceDir = "c:\Users\PROINOVA\Documents\Projetos IA\BI"

# Ler arquivo local e extrair a parte do CSV
$Content = Get-Content $LocalFallback -Raw -Encoding UTF8
$CsvData = ""

if ($Content -match "---(?s)(.*)") {
    $CsvData = $Matches[1].Trim()
} else {
    $CsvData = $Content.Trim()
}

# Salvar temporariamente como um arquivo CSV limpo em UTF-8
$TempCsvPath = Join-Path $WorkspaceDir "temp_data_debug.csv"
$CsvData | Out-File $TempCsvPath -Encoding UTF8

# Importar CSV explicitamente usando UTF-8
$RawCsv = Import-Csv -Path $TempCsvPath -Delimiter "," -Encoding UTF8

if ($RawCsv.Count -gt 0) {
    $FirstRow = $RawCsv[0]
    $PropNames = $FirstRow.PSObject.Properties | Select-Object -ExpandProperty Name
    Write-Host "Total de linhas importadas: $($RawCsv.Count)"
    Write-Host "Todos os cabecalhos detectados no CSV UTF-8:"
    foreach ($p in $PropNames) {
        Write-Host "Header: [$p] - Valor do primeiro registro: [$($FirstRow.$p)]"
    }
} else {
    Write-Error "Nenhum dado encontrado no CSV."
}
