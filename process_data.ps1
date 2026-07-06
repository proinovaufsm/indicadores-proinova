# Script do PowerShell para processar e limpar os dados de projetos (Cabecalho Dinamico Corrigido e Otimizado)

$LocalFallback = "C:\Users\PROINOVA\.gemini\antigravity-ide\brain\e7e2ae65-5067-4020-b1af-415a085083a2\.system_generated\steps\7\content.md"
$WorkspaceDir = "c:\Users\PROINOVA\Documents\Projetos IA\BI"

Write-Host "Iniciando processamento com PowerShell..."

# Tentar obter dados online diretamente do Google Sheets
$CsvUrl = "https://docs.google.com/spreadsheets/d/1PVyTdBjFmtqMMFt4OqiSHhofmOPx15Re_8ddEiNro6U/export?format=csv&gid=409266791&t=" + (Get-Date -UFormat %s)
$TempCsvPath = Join-Path $WorkspaceDir "temp_data.csv"

try {
    Write-Host "Tentando baixar dados atualizados do Google Sheets..."
    # Baixar diretamente para o arquivo temporario para preservar os bytes brutos sem decodificacao do PS
    Invoke-WebRequest -Uri $CsvUrl -OutFile $TempCsvPath -TimeoutSec 15
    Write-Host "Dados baixados com sucesso diretamente da internet!"
} catch {
    Write-Warning "Falha ao baixar do Google Sheets online: $_. Usando fallback local..."
    if (Test-Path $LocalFallback) {
        $Content = Get-Content $LocalFallback -Raw -Encoding UTF8
        $CsvData = ""
        if ($Content -match "---(?s)(.*)") {
            $CsvData = $Matches[1].Trim()
        } else {
            $CsvData = $Content.Trim()
        }
        [System.IO.File]::WriteAllText($TempCsvPath, $CsvData, [System.Text.Encoding]::UTF8)
        Write-Host "Dados do fallback local carregados com sucesso."
    } else {
        Write-Error "Erro grave: Fallback local nao encontrado!"
        Exit 1
    }
}

# Importar CSV explicitamente usando UTF-8
$RawCsv = Import-Csv -Path $TempCsvPath -Delimiter "," -Encoding UTF8
Write-Host "Total de linhas importadas: $($RawCsv.Count)"

# Funcoes de Limpeza
function Clean-Currency($val) {
    if ($null -eq $val -or $val -eq "" -or $val -eq "---" -or $val -like "*#VALUE*" -or $val -like "*excluído*") {
        return 0.0
    }
    $cleaned = $val -replace "R`\$", "" -replace "\.", "" -replace ",", "." -replace "\s", ""
    $cleaned = $cleaned -replace "[^\d\.-]", ""
    
    $outVal = 0.0
    if ([double]::TryParse($cleaned, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$outVal)) {
        return $outVal
    }
    return 0.0
}

function Clean-Year($val) {
    if ($null -eq $val -or $val -eq "" -or $val -eq "---") { return $null }
    $cleaned = $val -replace "\s", ""
    $outVal = 0
    if ([int]::TryParse($cleaned, [ref]$outVal)) {
        if ($outVal -ge 2000 -and $outVal -le 2030) {
            return $outVal
        }
    }
    return $null
}

function Clean-Month($val) {
    if ($null -eq $val -or $val -eq "" -or $val -eq "---") { return $null }
    $cleaned = $val -replace "\s", ""
    $outVal = 0
    if ([int]::TryParse($cleaned, [ref]$outVal)) {
        if ($outVal -ge 1 -and $outVal -le 12) {
            return $outVal
        }
    }
    return $null
}

function Fix-Encoding($val) {
    if ($null -eq $val -or $val -eq "") { return "" }
    
    $hasDoubleEncoding = $false
    for ($i = 0; $i -lt $val.Length; $i++) {
        $c = [int][char]$val[$i]
        # 195 is Ã, 194 is Â, 170 is ª, 186 is º
        if ($c -eq 195 -or $c -eq 194 -or $c -eq 170 -or $c -eq 186) {
            $hasDoubleEncoding = $true
            break
        }
    }
    
    if ($hasDoubleEncoding) {
        try {
            $bytes = [System.Text.Encoding]::GetEncoding(1252).GetBytes($val)
            return [System.Text.Encoding]::UTF8.GetString($bytes)
        } catch {
            return $val
        }
    }
    return $val
}

function Normalize-CoordinatorName($name) {
    if ($null -eq $name -or $name -eq "") { return "" }
    $cleanName = (Fix-Encoding $name) -replace "[\r\n]+", " " -replace "\s+", " "
    $cleanName = $cleanName.Trim()
    $nameLower = $cleanName.ToLower()
    
    $mapping = @{
        "adriano arrué" = "Adriano Arrué Melo"
        "adriano arrué melo" = "Adriano Arrué Melo"
        "alysson raniere seidel" = "Alysson Raniere Seidel"
        "alencar zanon" = "Alencar Junior Zanon"
        "alencar junior zanon" = "Alencar Junior Zanon"
        "ana eucares von laer" = "Ana Eucares von Laer"
        "ana paula rovedder" = "Ana Paula Moreira Rovedder"
        "ana paula moreira rovedder" = "Ana Paula Moreira Rovedder"
        "anderson pain" = "Anderson Cardozo Paim"
        "anderson cardozo paim" = "Anderson Cardozo Paim"
        "andré da rosa ulguim" = "André da Rosa Ulguim"
        "andré rosa ulguin" = "André da Rosa Ulguim"
        "andré lubeck" = "André Lübeck"
        "andré lübeck" = "André Lübeck"
        "andré passaglia shuch" = "André Passaglia Schuch"
        "andré passaglia schuch" = "André Passaglia Schuch"
        "andrea nummer" = "Andrea Valli Nummer"
        "andrea valli nummer" = "Andrea Valli Nummer"
        "bruno lopes da silveira" = "Bruno Lopes da Silveira"
        "carlos raniery" = "Carlos Raniery Paula dos Santos"
        "carlos raniery paula dos santos" = "Carlos Raniery Paula dos Santos"
        "carmem brum" = "Carmen Brum Rosa"
        "carmem brum rosa" = "Carmen Brum Rosa"
        "carmen brum rosa" = "Carmen Brum Rosa"
        "carlos henrique barrichello" = "Carlos Henrique Barriquello"
        "carlos henrique barriquello" = "Carlos Henrique Barriquello"
        "claudia sautter" = "Cláudia Sautter"
        "cláudia sautter" = "Cláudia Sautter"
        "claudio weissheimer rot" = "Cláudio Weissheimer Roth"
        "claudio weissheimer roth" = "Cláudio Weissheimer Roth"
        "cláudio weissheimer roth" = "Cláudio Weissheimer Roth"
        "cricieli martins" = "Criciele Castro Martins"
        "criciéle castro martins" = "Criciele Castro Martins"
        "criciele castro martins" = "Criciele Castro Martins"
        "cristiano jose scheuer" = "Cristiano José Scheuer"
        "cristiano josé scheuer" = "Cristiano José Scheuer"
        "daniel assumpcao bertuol" = "Daniel Assumpção Bertuol"
        "daniel assumpção bertuol" = "Daniel Assumpção Bertuol"
        "daniel bertuol" = "Daniel Assumpção Bertuol"
        "daniel bernardon" = "Daniel Pinheiro Bernardon"
        "daniel pinheiro bernardon" = "Daniel Pinheiro Bernardon"
        "dilson bisognin" = "Dilson Antonio Bisognin"
        "dilson antonio biosgnin" = "Dilson Antonio Bisognin"
        "eduardo escobar bürger" = "Eduardo Escobar Bürger"
        "eduardo escobar bã¼rger" = "Eduardo Escobar Bürger"
        "elvis carissimi" = "Élvis Carissimi"
        "eneias tavares" = "Eneias Farias Tavares"
        "eneias farias tavares" = "Eneias Farias Tavares"
        "erich rodrigues" = "Erich David Rodriguez Martinez"
        "erich david rodriguez martinez" = "Erich David Rodriguez Martinez"
        "fábio a. duarte (extensão)" = "Fábio Andrei Duarte"
        "fábio a. duarte (pesquisa)" = "Fábio Andrei Duarte"
        "fábio duarte" = "Fábio Andrei Duarte"
        "fábio andrei duarte" = "Fábio Andrei Duarte"
        "fabricio de araujo pedron" = "Fabrício de Araújo Pedron"
        "fabrício de araujo pedron" = "Fabrício de Araújo Pedron"
        "fabrício de araújo pedron" = "Fabrício de Araújo Pedron"
        "fabricio jaques sutili" = "Fabrício Jaques Sutili"
        "fabrício sutili" = "Fabrício Jaques Sutili"
        "fabrício jaques sutili" = "Fabrício Jaques Sutili"
        "fernanda castillos" = "Fernanda de Castilhos"
        "fernanda de castilhos" = "Fernanda de Castilhos"
        "flavio de la corte" = "Flávio Desessards de la Corte"
        "flavio desessards de la corte" = "Flávio Desessards de la Corte"
        "flávio desessards de la corte" = "Flávio Desessards de la Corte"
        "gilberto vilmar kozlosk" = "Gilberto Vilmar Kozloski"
        "gilberto vilmar kozloski" = "Gilberto Vilmar Kozloski"
        "gilson antonio pessoa" = "Gilson Antônio Pessoa"
        "gilson antônio pessoa" = "Gilson Antônio Pessoa"
        "hamiltom sartori" = "Hamiltom Confortin Sartori"
        "hamiltom confortin sartori" = "Hamiltom Confortin Sartori"
        "ivana da cruz / doutoranda neida" = "Ivana Beatrice Manica da Cruz"
        "ivana beatrice manica da cruz" = "Ivana Beatrice Manica da Cruz"
        "janio morais santurio" = "Janio Morais Santuário"
        "janio santuario" = "Janio Morais Santuário"
        "janio morais santuário" = "Janio Morais Santuário"
        "janio morais santuario" = "Janio Morais Santuário"
        "jansen pereira dos santos" = "Jansen Rodrigo Pereira Santos"
        "jansen rodrigo pereira santos" = "Jansen Rodrigo Pereira Santos"
        "jeronimo siqueira tybusch" = "Jerônimo Siqueira Tybusch"
        "jerônimo tybush" = "Jerônimo Siqueira Tybusch"
        "jerônimo siqueira tybusch" = "Jerônimo Siqueira Tybusch"
        "jorge antonio de farias" = "Jorge Antônio de Farias"
        "jorge farias" = "Jorge Antônio de Farias"
        "jorge antônio de farias" = "Jorge Antônio de Farias"
        "jose fernando schlosser" = "José Fernando Schlosser"
        "josé fernando schlosser" = "José Fernando Schlosser"
        "jose newton cardoso marchiori" = "José Newton Cardoso Marchiori"
        "josé newton cardoso marchiori" = "José Newton Cardoso Marchiori"
        "juliana felipetto" = "Juliana Felipetto Cargnelutti"
        "juliana felipetto cargnelutti" = "Juliana Felipetto Cargnelutti"
        "juliano dalcin martins" = "Juliano Dalcin Martins"
        "julio siluk" = "Julio Cezar Mairesse Siluk"
        "julio cezar mairesse siluk" = "Julio Cezar Mairesse Siluk"
        "leandro machado" = "Leandro Machado de Carvalho"
        "leandro m. de carvalho" = "Leandro Machado de Carvalho"
        "leandro machado de carvalho" = "Leandro Machado de Carvalho"
        "leonardo emmendorfer" = "Leonardo Ramos Emmendorfer"
        "leonardo ramos emmendorfer" = "Leonardo Ramos Emmendorfer"
        "lígia gomes" = "Lígia Gomes Miyazato"
        "ligia gomes miyazato" = "Lígia Gomes Miyazato"
        "lígia gomes miyazato" = "Lígia Gomes Miyazato"
        "luis felipe dutra côrrea" = "Luís Felipe Dutra Corrêa"
        "luis felipe dutra corrêa" = "Luís Felipe Dutra Corrêa"
        "luís felipe dutra corrêa" = "Luís Felipe Dutra Corrêa"
        "luis f. vilani de pellegrin" = "Luis Fernando Vilani de Pellegrin"
        "luis pellegrin" = "Luis Fernando Vilani de Pellegrin"
        "luis fernando vilani de pellegrin" = "Luis Fernando Vilani de Pellegrin"
        "maisa pimentel martins" = "Maisa Pimentel Martins Corder"
        "maisa pimentel martins corder" = "Maisa Pimentel Martins Corder"
        "marcio mazutti" = "Marcio Antonio Mazutti"
        "marcio antonio mazutti" = "Marcio Antonio Mazutti"
        "marco antonio dalla costa" = "Marco Antônio Dalla Costa"
        "marco antônio dalla costa" = "Marco Antônio Dalla Costa"
        "maria daniele" = "Maria Daniele dos Santos Dutra"
        "maria daniele dos santos dutra" = "Maria Daniele dos Santos Dutra"
        "mariana bassaco" = "Mariana Moro Bassaco"
        "mariana moro bassaco" = "Mariana Moro Bassaco"
        "mario e. santos martins" = "Mario Eduardo Santos Martins"
        "mario eduardo martins" = "Mario Eduardo Santos Martins"
        "mario eduardo santos martins" = "Mario Eduardo Santos Martins"
        "rafael c. beltrame" = "Rafael Concatto Beltrame"
        "rafael concatto beltrame" = "Rafael Concatto Beltrame"
        "roberto begnis hausen" = "Roberto Begnis Hausen"
        "rodrigo j. s. jacques" = "Rodrigo Josemar Seminoti Jacques"
        "rodrigo jacques" = "Rodrigo Josemar Seminoti Jacques"
        "rodrigo seminoti jacques" = "Rodrigo Josemar Seminoti Jacques"
        "rodrigo josemar seminoti jacques" = "Rodrigo Josemar Seminoti Jacques"
        "rogério luis backes" = "Rogério Luiz Backes"
        "rogerio luiz backes" = "Rogério Luiz Backes"
        "rogério luiz backes" = "Rogério Luiz Backes"
        "rudney soares pereira" = "Rudiney Soares Pereira"
        "rudiney soares pereira" = "Rudiney Soares Pereira"
        "sérgio dias da silva" = "Sérgio Dias da Silva"
        "sabrina zancan" = "Sabrina Zancan Peripolli"
        "sabrina zancan peripolli" = "Sabrina Zancan Peripolli"
        "sandro jose giacomini" = "Sandro José Giacomini"
        "sandro josé giacomini" = "Sandro José Giacomini"
        "silvia gonzalez monteiro" = "Silvia González Monteiro"
        "silvia gonzález monteiro" = "Silvia González Monteiro"
        "thompson diórdinis" = "Thompson Diórdinis Metzka Lanzanova"
        "thompson diórdinis metzka lanzanova" = "Thompson Diórdinis Metzka Lanzanova"
        "vinicius jacques garcia" = "Vinícius Jacques Garcia"
        "vinicius jaques garcia" = "Vinícius Jacques Garcia"
        "vinícius jacques garcia" = "Vinícius Jacques Garcia"
        "vinicius maran" = "Vinícius Maran"
        "vinícius maran" = "Vinícius Maran"
        "vinicius marini" = "Vinicius Kaster Marini"
        "vinicius kaster marini" = "Vinicius Kaster Marini"
        "vitor bender" = "Vitor Cristiano Bender"
        "vitor cristiano bender" = "Vitor Cristiano Bender"
        "alexandre aparecido buenos" = "Alexandre Aparecido Bueno"
        "alexandre buenos" = "Alexandre Aparecido Bueno"
        "alexandre aparecido bueno" = "Alexandre Aparecido Bueno"
        "alexandre vargas" = "Alexandre Vargas Schwarzbold"
        "alexandre v. schwarzbold" = "Alexandre Vargas Schwarzbold"
        "alexandre vargas schwarzbold" = "Alexandre Vargas Schwarzbold"
    }
    
    # Adiciona chaves com caracteres especiais dinamicos para evitar quebra de encoding no parser do PS
    $keyMangled = "eduardo escobar bã" + [char]339 + "rger"
    $mapping[$keyMangled] = "Eduardo Escobar Bürger"
    
    if ($mapping.Contains($nameLower)) {
        return $mapping[$nameLower]
    }
    return $cleanName
}

function Normalize-Financiador($val) {
    if ($null -eq $val -or $val -eq "") { return "" }
    
    $s = (Fix-Encoding $val).Trim()
    $s = $s -replace "\s+", " "
    
    if ($s -eq "-" -or $s -eq "---" -or $s -eq "--" -or $s -eq "." -or $s.ToLower() -eq "sem financiador") {
        return ""
    }
    
    $sLower = $s.ToLower()
    
    if ($sLower -like "*27194*30*" -or $sLower -like "*rota 2030*") {
        return "Rota 2030"
    }
    if ($sLower -like "*finep*") {
        return "FINEP"
    }
    if ($sLower -like "*embrapii*") {
        return "EMBRAPII"
    }
    if ($sLower -like "*aneel*") {
        return "ANEEL"
    }
    if ($sLower -like "*sict*") {
        return "SICT"
    }
    
    return $s
}

function Clean-Text($val) {
    if ($null -eq $val -or $val.Trim() -eq "---" -or $val.Trim() -eq "--- ") {
        return ""
    }
    return (Fix-Encoding $val.Trim())
}

$Count = 0

# Otimizacao: Atribuicao direta do loop foreach para evitar lentidao
$Projects = foreach ($row in $RawCsv) {
    # Mapeamento dinamico baseado em curingas resilientes a encoding nos cabecalhos
    $id = ""
    $n_antiga = ""
    $planilha = ""
    $mes = ""
    $ano = ""
    $data_instrucao = ""
    $responsavel = ""
    $tipo_contrato = ""
    $fundacao = ""
    $tipo_projeto = ""
    $situacao = ""
    $nup = ""
    $coordenador = ""
    $contato_coordenador = ""
    $unidade = ""
    $subunidade = ""
    $fiscal = ""
    $participes = ""
    $titulo = ""
    $registro_portal = ""
    $id_projeto_fundacao = ""
    $valor = ""
    $taxa_ufsm = ""
    $numero_contrato = ""
    $vigencia_inicial = ""
    $vigencia_final = ""
    $remuneracao_pi = ""
    $propriedade_intelectual = ""
    $financiador = ""

    # Iterar pelas propriedades do objeto do CSV
    foreach ($prop in $row.PSObject.Properties) {
        $name = $prop.Name.Trim()
        $val = $prop.Value

        if ($name -eq "" -or $name -eq "H1") { $id = $val }
        elseif ($name -like "*antiga*") { $n_antiga = $val }
        elseif ($name -like "*Planilha*") { $planilha = $val }
        elseif ($name -like "*M*s*" -and $name -notlike "*Taxa*" -and $name -notlike "*PI*") { $mes = $val }
        elseif ($name -like "*Ano*") { $ano = $val }
        elseif ($name -like "*Instru*") { $data_instrucao = $val }
        elseif ($name -like "*Acompanhamento*" -or $name -like "*Respons*") { $responsavel = $val }
        elseif ($name -like "*Tipo de Contrato*" -or $name -like "*Tipo deContrato*") { $tipo_contrato = $val }
        elseif ($name -like "*id*funda*") { $id_projeto_fundacao = $val }
        elseif ($name -like "*Tipo de Projeto*" -or $name -like "*Tipo deProjeto*" -or ($name -like "*Tipo*" -and $name -like "*Projeto*")) { $tipo_projeto = $val }
        elseif ($name -like "*Funda*") { $fundacao = $val }
        elseif ($name -like "*Situa*") { $situacao = $val }
        elseif ($name -like "*NUP*") { $nup = $val }
        elseif ($name -like "*Coordenador*" -and $name -notlike "*Contato*") { $coordenador = $val }
        elseif ($name -like "*Contato*") { $contato_coordenador = $val }
        elseif ($name -like "*Unidade*" -or $name -like "*Centro*") { $unidade = $val }
        elseif ($name -like "*Subunidade*") { $subunidade = $val }
        elseif ($name -like "*Fiscal*") { $fiscal = $val }
        elseif ($name -like "*Part*cipes*" -or $name -like "*Participe*") { $participes = $val }
        elseif ($name -like "*Portal*" -or $name -like "*Registro*") { $registro_portal = $val }
        elseif ($name -like "*T*tulo*" -or $name -like "*Titulo*" -or $name -like "*Projeto*") { $titulo = $val }
        elseif ($name -like "*Valor*") { $valor = $val }
        elseif ($name -like "*Taxa*") { $taxa_ufsm = $val }
        elseif ($name -like "*contrato*" -and $name -notlike "*Valor*" -and $name -notlike "*Tipo*") { $numero_contrato = $val }
        elseif ($name -like "*Vig*Inicial*" -or $name -like "*Vig*Ini*") { $vigencia_inicial = $val }
        elseif ($name -like "*Vig*Final*" -or $name -like "*Vig*Fim*") { $vigencia_final = $val }
        elseif ($name -like "*PI?*" -or $name -like "*PI*") { $remuneracao_pi = $val }
        elseif ($name -like "*Intelectual*") { $propriedade_intelectual = $val }
        elseif ($name -like "*Financiador*" -or $name -like "*Edital*") { $financiador = $val }
    }

    # Se nao conseguiu o ID do primeiro campo H1, usar Nº antiga ou Nº antiga modificado
    if ($null -eq $id -or $id -eq "") {
        $id = $n_antiga
    }

    $id = Clean-Text $id
    $titulo = Clean-Text $titulo
    $clean_reg = Clean-Text $registro_portal

    # Pular se o titulo for vazio ou se for uma linha excluida
    if ($titulo -eq "" -or $titulo -like "*(excluído)*" -or $titulo -like "*registro duplicado*") {
        continue
    }

    # Juntar Registro Portal de Projetos com o Projeto/Título
    if ($clean_reg -and $clean_reg -ne "---") {
        $titulo = "$clean_reg - $titulo"
    }

    # Pular a linha do cabecalho se tiver sido importada como dados por engano
    if ($id -eq "Nº antiga" -or $id -eq "Nº" -or $titulo -like "*Projeto/Título*" -or $titulo -like "*Projeto/Ttulo*" -or $titulo -eq "Projeto" -or $titulo -eq "Projeto/Ttulo") {
        continue
    }

    $fundacao = Clean-Text $fundacao
    if ($fundacao -eq "") { $fundacao = "SEM FUNDAÇÃO" }

    $tipoProj = Clean-Text $tipo_projeto
    if ($tipoProj -eq "") { $tipoProj = "Outro" }

    $situacao = Clean-Text $situacao
    if ($situacao -eq "") { $situacao = "Indefinida" }

    $unidade = Clean-Text $unidade
    if ($unidade -eq "") { $unidade = "OUTRA" }

    $numValor = Clean-Currency $valor
    $numTaxaUfsm = Clean-Currency $taxa_ufsm

    # Normalizar Tipo de Projeto
    $tipoNorm = "Outro"
    $tipoUpper = $tipoProj.ToUpper()
    if ($tipoUpper -like "*PESQUISA*") { $tipoNorm = "Pesquisa" }
    elseif ($tipoUpper -like "*EXTENS*") { $tipoNorm = "Extensão" }
    elseif ($tipoUpper -like "*DES.*" -or $tipoUpper -like "*DESENVOLVIMENTO*") { $tipoNorm = "Des. Institucional" }

    # Normalizar Situacao
    $sitNorm = "Outros"
    $sitUpper = $situacao.ToUpper()
    if ($sitUpper -like "*ENCERRADO*") { $sitNorm = "Encerrado" }
    elseif ($sitUpper -like "*VIGÊNCIA*" -or $sitUpper -like "*VIGENCIA*" -or $sitUpper -like "*EM VIG*") { $sitNorm = "Em vigência" }
    elseif ($sitUpper -like "*CANC*" -or $sitUpper -like "*ARQ*" -or $sitUpper -like "*SUSP*") { $sitNorm = "Cancelado/Suspenso" }

    # Normalizar Unidade
    $unidNorm = $unidade.ToUpper()
    if ($unidNorm -like "*REITORIA*") { $unidNorm = "REITORIA" }
    elseif ($unidNorm -like "*POLI*" -or $unidNorm -like "*COLÉGIO POLITÉCNICO*") { $unidNorm = "POLITÉCNICO" }
    elseif ($unidNorm -like "*CTISM*") { $unidNorm = "CTISM" }
    elseif ($unidNorm -like "*FW*" -or $unidNorm -like "*FREDERICO*") { $unidNorm = "UFSM-FW" }

    # Retorna o objeto estruturado
    [PSCustomObject]@{
        id                      = $id
        n_antiga                = Clean-Text $n_antiga
        planilha                = Clean-Text $planilha
        mes                     = Clean-Month $mes
        ano                     = Clean-Year $ano
        data_instrucao          = Clean-Text $data_instrucao
        responsavel             = Clean-Text $responsavel
        tipo_contrato           = Clean-Text $tipo_contrato
        fundacao                = $fundacao
        tipo_projeto            = $tipoProj
        tipo_projeto_norm       = $tipoNorm
        situacao                = $situacao
        situacao_norm           = $sitNorm
        nup                     = Clean-Text $nup
        coordenador             = Normalize-CoordinatorName (Clean-Text $coordenador)
        contato_coordenador     = Clean-Text $contato_coordenador
        unidade                 = $unidade
        unid_norm               = $unidNorm
        subunidade              = Clean-Text $subunidade
        fiscal                  = Clean-Text $fiscal
        participes              = Clean-Text $participes
        titulo                  = $titulo
        registro_portal         = Clean-Text $registro_portal
        id_projeto_fundacao     = Clean-Text $id_projeto_fundacao
        valor                   = $numValor
        taxa_ufsm               = $numTaxaUfsm
        numero_contrato         = Clean-Text $numero_contrato
        vigencia_inicial        = Clean-Text $vigencia_inicial
        vigencia_final          = Clean-Text $vigencia_final
        remuneracao_pi          = Clean-Text $remuneracao_pi
        propriedade_intelectual = Clean-Text $propriedade_intelectual
        financiador             = Normalize-Financiador $financiador
    }
    $Count++
}

Write-Host "Total de projetos processados com sucesso: $($Projects.Count) (contador: $Count)"

# Converter para JSON
$JsonData = ConvertTo-Json -InputObject $Projects -Depth 5

# Salvar json
$JsonPath = Join-Path $WorkspaceDir "projects_data.json"
[System.IO.File]::WriteAllText($JsonPath, $JsonData, [System.Text.Encoding]::UTF8)
Write-Host "projects_data.json salvo em: $JsonPath"

# Salvar data.js
$JsContent = "// UFSM BI Projects Pre-loaded Data`nvar initialProjectsData = $JsonData;"
$JsPath = Join-Path $WorkspaceDir "data.js"
[System.IO.File]::WriteAllText($JsPath, $JsContent, [System.Text.Encoding]::UTF8)
Write-Host "data.js salvo em: $JsPath"

# Remover arquivo temporario
if (Test-Path $TempCsvPath) {
    Remove-Item $TempCsvPath
}

Write-Host "PowerShell process concluido com sucesso!"
