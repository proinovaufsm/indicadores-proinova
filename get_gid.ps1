$Url = "https://docs.google.com/spreadsheets/d/1Ybhp3gQvH1vA8-xBiteq18VgObN3vggv/edit?usp=sharing"
$HtmlPath = "sheet.html"

try {
    Invoke-WebRequest -Uri $Url -OutFile $HtmlPath -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    $Content = Get-Content $HtmlPath -Raw -Encoding UTF8
    
    # 1. Look for bootstrapData or initial data variables
    $Lines = $Content -split "`n"
    foreach ($Line in $Lines) {
        if ($Line -like "*bootstrapData*" -or $Line -like "*_INITIAL_DATA_*") {
            # Write-Host "Found data line: " + $Line.Substring(0, [Math]::Min(200, $Line.Length))
            # Let's search inside this line for "Valor Recebido"
            if ($Line -like "*Valor Recebido*") {
                Write-Host "Found 'Valor Recebido' in data line."
                # Find all numbers around "Valor Recebido"
                $regex = [regex]'"([^"]+)":'
                # Let's find any sequence of digits of length 5-10 near "Valor Recebido"
                $idx = $Line.IndexOf("Valor Recebido")
                $start = [Math]::Max(0, $idx - 300)
                $len = [Math]::Min(600, $Line.Length - $start)
                $sub = $Line.Substring($start, $len)
                Write-Host "JSON Context: $sub"
            }
        }
    }
    
    # 2. General regex search for gid/id near "Valor Recebido"
    $matches = [regex]::Matches($Content, '(?i)(?:id|gid|sheetId)["\s:]*(\d+)[^}]+?Valor Recebido')
    foreach ($m in $matches) {
        Write-Host "Regex match 1: $($m.Value)"
    }
    
    $matches2 = [regex]::Matches($Content, '(?i)Valor Recebido[^}]+?(?:id|gid|sheetId)["\s:]*(\d+)')
    foreach ($m in $matches2) {
        Write-Host "Regex match 2: $($m.Value)"
    }

    # 3. Search for any sheet tab references
    $matches3 = [regex]::Matches($Content, '(?i)(?:[^a-zA-Z0-9]|^)(\d{5,15})[^a-zA-Z0-9]+?Valor Recebido')
    foreach ($m in $matches3) {
        Write-Host "Regex match 3: $($m.Value)"
    }
    
    $matches4 = [regex]::Matches($Content, '(?i)Valor Recebido[^a-zA-Z0-9]+?(\d{5,15})')
    foreach ($m in $matches4) {
        Write-Host "Regex match 4: $($m.Value)"
    }

} catch {
    Write-Error "Error: $_"
} finally {
    if (Test-Path $HtmlPath) {
        Remove-Item $HtmlPath
    }
}
