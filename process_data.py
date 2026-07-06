import csv
import json
import re
import urllib.request
import os

import time
CSV_URL = f"https://docs.google.com/spreadsheets/d/1PVyTdBjFmtqMMFt4OqiSHhofmOPx15Re_8ddEiNro6U/export?format=csv&gid=409266791&t={int(time.time())}"
LOCAL_FALLBACK = r"C:\Users\PROINOVA\.gemini\antigravity-ide\brain\e7e2ae65-5067-4020-b1af-415a085083a2\.system_generated\steps\7\content.md"
WORKSPACE_DIR = r"c:\Users\PROINOVA\Documents\Projetos IA\BI"

def clean_currency(val):
    if not val or val.strip() == "---" or "#VALUE" in val or "excluído" in val.lower():
        return 0.0
    # Remover R$, pontos de milhar, espaços e trocar vírgula por ponto
    cleaned = val.replace("R$", "").replace(".", "").replace(",", ".").replace(" ", "").strip()
    # Manter apenas números, pontos e hífens
    cleaned = re.sub(r'[^\d.-]', '', cleaned)
    try:
        return float(cleaned) if cleaned else 0.0
    except ValueError:
        return 0.0

def clean_year(val):
    if not val or val.strip() == "---" or not val.strip().isdigit():
        return None
    try:
        y = int(val.strip())
        if 2000 <= y <= 2030:
            return y
        return None
    except ValueError:
        return None

def clean_month(val):
    if not val or val.strip() == "---" or not val.strip().isdigit():
        return None
    try:
        m = int(val.strip())
        if 1 <= m <= 12:
            return m
        return None
    except ValueError:
        return None

def fix_encoding(val):
    if not val:
        return ""
    if any(x in val for x in ["Ã", "Â", "ª", "º"]):
        try:
            return val.encode('latin-1').decode('utf-8')
        except Exception:
            pass
    return val

def normalize_coordinator_name(name):
    if not name:
        return ""
    cleaned = fix_encoding(name).replace('\r', ' ').replace('\n', ' ')
    while '  ' in cleaned:
        cleaned = cleaned.replace('  ', ' ')
    name = cleaned.strip()
    name_lower = name.lower()
    
    mapping = {
        "adriano arrué": "Adriano Arrué Melo",
        "adriano arrué melo": "Adriano Arrué Melo",
        "alysson raniere seidel": "Alysson Raniere Seidel",
        "alencar zanon": "Alencar Junior Zanon",
        "alencar junior zanon": "Alencar Junior Zanon",
        "ana eucares von laer": "Ana Eucares von Laer",
        "ana paula rovedder": "Ana Paula Moreira Rovedder",
        "ana paula moreira rovedder": "Ana Paula Moreira Rovedder",
        "anderson pain": "Anderson Cardozo Paim",
        "anderson cardozo paim": "Anderson Cardozo Paim",
        "andré da rosa ulguim": "André da Rosa Ulguim",
        "andré rosa ulguin": "André da Rosa Ulguim",
        "andré lubeck": "André Lübeck",
        "andré lübeck": "André Lübeck",
        "andré passaglia shuch": "André Passaglia Schuch",
        "andré passaglia schuch": "André Passaglia Schuch",
        "andrea nummer": "Andrea Valli Nummer",
        "andrea valli nummer": "Andrea Valli Nummer",
        "bruno lopes da silveira": "Bruno Lopes da Silveira",
        "carlos raniery": "Carlos Raniery Paula dos Santos",
        "carlos raniery paula dos santos": "Carlos Raniery Paula dos Santos",
        "carmem brum": "Carmen Brum Rosa",
        "carmem brum rosa": "Carmen Brum Rosa",
        "carmen brum rosa": "Carmen Brum Rosa",
        "carlos henrique barrichello": "Carlos Henrique Barriquello",
        "carlos henrique barriquello": "Carlos Henrique Barriquello",
        "claudia sautter": "Cláudia Sautter",
        "cláudia sautter": "Cláudia Sautter",
        "claudio weissheimer rot": "Cláudio Weissheimer Roth",
        "claudio weissheimer roth": "Cláudio Weissheimer Roth",
        "cláudio weissheimer roth": "Cláudio Weissheimer Roth",
        "cricieli martins": "Criciele Castro Martins",
        "criciéle castro martins": "Criciele Castro Martins",
        "criciele castro martins": "Criciele Castro Martins",
        "cristiano jose scheuer": "Cristiano José Scheuer",
        "cristiano josé scheuer": "Cristiano José Scheuer",
        "daniel assumpcao bertuol": "Daniel Assumpção Bertuol",
        "daniel assumpção bertuol": "Daniel Assumpção Bertuol",
        "daniel bertuol": "Daniel Assumpção Bertuol",
        "daniel bernardon": "Daniel Pinheiro Bernardon",
        "daniel pinheiro bernardon": "Daniel Pinheiro Bernardon",
        "dilson bisognin": "Dilson Antonio Bisognin",
        "dilson antonio bisognin": "Dilson Antonio Bisognin",
        "eduardo escobar bürger": "Eduardo Escobar Bürger",
        "eduardo escobar bãœrger": "Eduardo Escobar Bürger",
        "eduardo escobar bã¼rger": "Eduardo Escobar Bürger",
        "elvis carissimi": "Élvis Carissimi",
        "eneias tavares": "Eneias Farias Tavares",
        "eneias farias tavares": "Eneias Farias Tavares",
        "erich rodrigues": "Erich David Rodriguez Martinez",
        "erich david rodriguez martinez": "Erich David Rodriguez Martinez",
        "fábio a. duarte (extensão)": "Fábio Andrei Duarte",
        "fábio a. duarte (pesquisa)": "Fábio Andrei Duarte",
        "fábio duarte": "Fábio Andrei Duarte",
        "fábio andrei duarte": "Fábio Andrei Duarte",
        "fabricio de araujo pedron": "Fabrício de Araújo Pedron",
        "fabrício de araujo pedron": "Fabrício de Araújo Pedron",
        "fabrício de araújo pedron": "Fabrício de Araújo Pedron",
        "fabricio jaques sutili": "Fabrício Jaques Sutili",
        "fabrício sutili": "Fabrício Jaques Sutili",
        "fabrício jaques sutili": "Fabrício Jaques Sutili",
        "fernanda castillos": "Fernanda de Castilhos",
        "fernanda de castilhos": "Fernanda de Castilhos",
        "flavio de la corte": "Flávio Desessards de la Corte",
        "flavio desessards de la corte": "Flávio Desessards de la Corte",
        "flávio desessards de la corte": "Flávio Desessards de la Corte",
        "gilberto vilmar kozlosk": "Gilberto Vilmar Kozloski",
        "gilberto vilmar kozloski": "Gilberto Vilmar Kozloski",
        "gilson antonio pessoa": "Gilson Antônio Pessoa",
        "gilson antônio pessoa": "Gilson Antônio Pessoa",
        "hamiltom sartori": "Hamiltom Confortin Sartori",
        "hamiltom confortin sartori": "Hamiltom Confortin Sartori",
        "ivana da cruz / doutoranda neida": "Ivana Beatrice Manica da Cruz",
        "ivana beatrice manica da cruz": "Ivana Beatrice Manica da Cruz",
        "janio morais santurio": "Janio Morais Santuário",
        "janio santuario": "Janio Morais Santuário",
        "janio morais santuário": "Janio Morais Santuário",
        "janio morais santuario": "Janio Morais Santuário",
        "jansen pereira dos santos": "Jansen Rodrigo Pereira Santos",
        "jansen rodrigo pereira santos": "Jansen Rodrigo Pereira Santos",
        "jeronimo siqueira tybusch": "Jerônimo Siqueira Tybusch",
        "jerônimo tybush": "Jerônimo Siqueira Tybusch",
        "jerônimo siqueira tybusch": "Jerônimo Siqueira Tybusch",
        "jorge antonio de farias": "Jorge Antônio de Farias",
        "jorge farias": "Jorge Antônio de Farias",
        "jorge antônio de farias": "Jorge Antônio de Farias",
        "jose fernando schlosser": "José Fernando Schlosser",
        "josé fernando schlosser": "José Fernando Schlosser",
        "jose newton cardoso marchiori": "José Newton Cardoso Marchiori",
        "josé newton cardoso marchiori": "José Newton Cardoso Marchiori",
        "juliana felipetto": "Juliana Felipetto Cargnelutti",
        "juliana felipetto cargnelutti": "Juliana Felipetto Cargnelutti",
        "juliano dalcin martins": "Juliano Dalcin Martins",
        "julio siluk": "Julio Cezar Mairesse Siluk",
        "julio cezar mairesse siluk": "Julio Cezar Mairesse Siluk",
        "leandro machado": "Leandro Machado de Carvalho",
        "leandro m. de carvalho": "Leandro Machado de Carvalho",
        "leandro machado de carvalho": "Leandro Machado de Carvalho",
        "leonardo emmendorfer": "Leonardo Ramos Emmendorfer",
        "leonardo ramos emmendorfer": "Leonardo Ramos Emmendorfer",
        "lígia gomes": "Lígia Gomes Miyazato",
        "ligia gomes miyazato": "Lígia Gomes Miyazato",
        "lígia gomes miyazato": "Lígia Gomes Miyazato",
        "luis felipe dutra côrrea": "Luís Felipe Dutra Corrêa",
        "luis felipe dutra corrêa": "Luís Felipe Dutra Corrêa",
        "luís felipe dutra corrêa": "Luís Felipe Dutra Corrêa",
        "luis f. vilani de pellegrin": "Luis Fernando Vilani de Pellegrin",
        "luis pellegrin": "Luis Fernando Vilani de Pellegrin",
        "luis fernando vilani de pellegrin": "Luis Fernando Vilani de Pellegrin",
        "maisa pimentel martins": "Maisa Pimentel Martins Corder",
        "maisa pimentel martins corder": "Maisa Pimentel Martins Corder",
        "marcio mazutti": "Marcio Antonio Mazutti",
        "marcio antonio mazutti": "Marcio Antonio Mazutti",
        "marco antonio dalla costa": "Marco Antônio Dalla Costa",
        "marco antônio dalla costa": "Marco Antônio Dalla Costa",
        "maria daniele": "Maria Daniele dos Santos Dutra",
        "maria daniele dos santos dutra": "Maria Daniele dos Santos Dutra",
        "mariana bassaco": "Mariana Moro Bassaco",
        "mariana moro bassaco": "Mariana Moro Bassaco",
        "mario e. santos martins": "Mario Eduardo Santos Martins",
        "mario eduardo martins": "Mario Eduardo Santos Martins",
        "mario eduardo santos martins": "Mario Eduardo Santos Martins",
        "rafael c. beltrame": "Rafael Concatto Beltrame",
        "rafael concatto beltrame": "Rafael Concatto Beltrame",
        "roberto begnis hausen": "Roberto Begnis Hausen",
        "rodrigo j. s. jacques": "Rodrigo Josemar Seminoti Jacques",
        "rodrigo jacques": "Rodrigo Josemar Seminoti Jacques",
        "rodrigo seminoti jacques": "Rodrigo Josemar Seminoti Jacques",
        "rodrigo josemar seminoti jacques": "Rodrigo Josemar Seminoti Jacques",
        "rogério luis backes": "Rogério Luiz Backes",
        "rogerio luiz backes": "Rogério Luiz Backes",
        "rogério luiz backes": "Rogério Luiz Backes",
        "rudney soares pereira": "Rudiney Soares Pereira",
        "rudiney soares pereira": "Rudiney Soares Pereira",
        "sérgio dias da silva": "Sérgio Dias da Silva",
        "sabrina zancan": "Sabrina Zancan Peripolli",
        "sabrina zancan peripolli": "Sabrina Zancan Peripolli",
        "sandro jose giacomini": "Sandro José Giacomini",
        "sandro josé giacomini": "Sandro José Giacomini",
        "silvia gonzalez monteiro": "Silvia González Monteiro",
        "silvia gonzález monteiro": "Silvia González Monteiro",
        "thompson diórdinis": "Thompson Diórdinis Metzka Lanzanova",
        "thompson diórdinis metzka lanzanova": "Thompson Diórdinis Metzka Lanzanova",
        "vinicius jacques garcia": "Vinícius Jacques Garcia",
        "vinicius jaques garcia": "Vinícius Jacques Garcia",
        "vinícius jacques garcia": "Vinícius Jacques Garcia",
        "vinicius maran": "Vinícius Maran",
        "vinícius maran": "Vinícius Maran",
        "vinicius marini": "Vinicius Kaster Marini",
        "vinicius kaster marini": "Vinicius Kaster Marini",
        "vitor bender": "Vitor Cristiano Bender",
        "vitor cristiano bender": "Vitor Cristiano Bender",
        "alexandre aparecido buenos": "Alexandre Aparecido Bueno",
        "alexandre buenos": "Alexandre Aparecido Bueno",
        "alexandre aparecido bueno": "Alexandre Aparecido Bueno",
        "alexandre vargas": "Alexandre Vargas Schwarzbold",
        "alexandre v. schwarzbold": "Alexandre Vargas Schwarzbold",
        "alexandre vargas schwarzbold": "Alexandre Vargas Schwarzbold"
    }
    return mapping.get(name_lower, name)

def normalize_financiador(val):
    if not val:
        return ""
    s = fix_encoding(str(val)).strip()
    s = re.sub(r'\s+', ' ', s)
    if s in ['-', '---', '--', '.', 'sem financiador']:
        return ""
    s_lower = s.lower()
    if '27194*30' in s_lower or 'rota 2030' in s_lower:
        return 'Rota 2030'
    if 'finep' in s_lower:
        return 'FINEP'
    if 'embrapii' in s_lower:
        return 'EMBRAPII'
    if 'aneel' in s_lower:
        return 'ANEEL'
    if 'sict' in s_lower:
        return 'SICT'
    return s

def clean_text(val):
    if not val or val.strip() == "---" or val.strip() == "--- ":
        return ""
    return fix_encoding(val.strip())

def run():
    print("Iniciando carregamento de dados...")
    csv_data = ""
    
    # Tentar baixar diretamente da internet
    try:
        print(f"Tentando baixar dados do Google Sheets: {CSV_URL}")
        with urllib.request.urlopen(CSV_URL, timeout=10) as response:
            csv_data = response.read().decode('utf-8')
        print("Dados baixados com sucesso via internet!")
    except Exception as e:
        print(f"Erro ao baixar da internet: {e}. Tentando ler fallback local...")
        if os.path.exists(LOCAL_FALLBACK):
            with open(LOCAL_FALLBACK, 'r', encoding='utf-8') as f:
                content = f.read()
                # Extrair a seção após o delimitador ---
                if "---" in content:
                    csv_data = content.split("---", 1)[1].strip()
                else:
                    csv_data = content
            print("Dados locais lidos com sucesso!")
        else:
            print("Erro: Fallback local não encontrado!")
            return

    if not csv_data:
        print("Erro: Nenhum dado carregado.")
        return

    # Processar CSV
    reader = csv.reader(csv_data.splitlines())
    header = next(reader)
    
    # Remover campos extras de quebras de linha ou strings vazias iniciais se o header estiver deslocado
    # Verificando a primeira linha do cabeçalho que lemos
    # No arquivo que vimos, a primeira linha de dados reais começa com Nº ou similar.
    # Vamos validar se o primeiro elemento é vazio ou se temos que realinhar
    
    # Vamos imprimir o cabeçalho original para debug
    print("Cabeçalho detectado:", header)
    
    projects = []
    
    # Mapeamento do cabeçalho
    # Headers detectados:
    # 0: (index/empty)
    # 1: "Nº antiga"
    # 2: Planilha
    # 3: Mês
    # 4: Ano
    # 5: Data Instrução processual 
    # 6: Responsável Acompanhamento 
    # 7: Tipo de Contrato
    # 8: Fundação
    # 9: Tipo de Projeto
    # 10: Situação/ Trâmite
    # 11: NUP PEN-SIE
    # 12: Coordenador
    # 13: Contato Coordenador
    # 14: Unidade/ Centro
    # 15: Subunidade
    # 16: Fiscal
    # 17: Partícipes
    # 18: Projeto/Título
    # 19: Registro Portal de Projetos
    # 20: ID_projeto fundação
    # 21: Valor do contrato
    # 22: Taxa UFSM (R$)
    # 23: Pasta de Documentos
    # 24: Número do contrato
    # 25: Vigência Inicial
    # 26: (vazio)
    # 27: (vazio)
    # 28: Vigência Final
    # 29: Remuneração PI?
    # 30: Propriedade Intelectual?
    # 31: Edital/Financiador
    
    count = 0
    for row in reader:
        if not row:
            continue
        # Se a linha for menor que o esperado, preencher com vazio
        if len(row) < 23:
            row.extend([""] * (23 - len(row)))
            
        # Pular linhas que contêm informações de registro excluído
        title = row[18] if len(row) > 18 else ""
        if "(excluído)" in title.lower() or "registro duplicado" in title.lower():
            continue
            
        # Capturar id_projeto (campo 0 ou 1)
        proj_id = row[0].strip() if row[0] else (row[1].strip() if len(row) > 1 else "")
        if not proj_id or proj_id == "Nº":
            continue
            
        reg = clean_text(row[19]) if len(row) > 19 else ""
        raw_title = clean_text(row[18]) if len(row) > 18 else "Sem Título"
        combined_title = f"{reg} - {raw_title}" if reg and reg != "---" else raw_title
        
        proj = {
            "id": proj_id,
            "n_antiga": clean_text(row[1]) if len(row) > 1 else "",
            "planilha": clean_text(row[2]) if len(row) > 2 else "",
            "mes": clean_month(row[3]) if len(row) > 3 else None,
            "ano": clean_year(row[4]) if len(row) > 4 else None,
            "data_instrucao": clean_text(row[5]) if len(row) > 5 else "",
            "responsavel": clean_text(row[6]) if len(row) > 6 else "",
            "tipo_contrato": clean_text(row[7]) if len(row) > 7 else "",
            "fundacao": clean_text(row[8]) if len(row) > 8 else "SEM FUNDAÇÃO",
            "tipo_projeto": clean_text(row[9]) if len(row) > 9 else "Outro",
            "situacao": clean_text(row[10]) if len(row) > 10 else "Indefinida",
            "nup": clean_text(row[11]) if len(row) > 11 else "",
            "coordenador": normalize_coordinator_name(clean_text(row[12])) if len(row) > 12 else "",
            "contato_coordenador": clean_text(row[13]) if len(row) > 13 else "",
            "unidade": clean_text(row[14]) if len(row) > 14 else "OUTRA",
            "subunidade": clean_text(row[15]) if len(row) > 15 else "",
            "fiscal": clean_text(row[16]) if len(row) > 16 else "",
            "participes": clean_text(row[17]) if len(row) > 17 else "",
            "titulo": combined_title,
            "registro_portal": reg,
            "id_projeto_fundacao": clean_text(row[20]) if len(row) > 20 else "",
            "valor": clean_currency(row[21]) if len(row) > 21 else 0.0,
            "taxa_ufsm": clean_currency(row[22]) if len(row) > 22 else 0.0,
            "numero_contrato": clean_text(row[24]) if len(row) > 24 else "",
            "vigencia_inicial": clean_text(row[25]) if len(row) > 25 else "",
            "vigencia_final": clean_text(row[28]) if len(row) > 28 else "",
            "remuneracao_pi": clean_text(row[29]) if len(row) > 29 else "",
            "propriedade_intelectual": clean_text(row[30]) if len(row) > 30 else "",
            "financiador": normalize_financiador(row[31]) if len(row) > 31 else ""
        }
        
        # Normalização de tipos de projeto para visualizações melhores
        tipo = proj["tipo_projeto"].upper()
        if "PESQUISA" in tipo:
            proj["tipo_projeto_norm"] = "Pesquisa"
        elif "EXTENSÃO" in tipo or "EXTENSAO" in tipo:
            proj["tipo_projeto_norm"] = "Extensão"
        elif "DES." in tipo or "DESENVOLVIMENTO INSTITUCIONAL" in tipo or "DESENVOLVIMENTO" in tipo:
            proj["tipo_projeto_norm"] = "Des. Institucional"
        elif "OUTRO" in tipo or not proj["tipo_projeto"]:
            proj["tipo_projeto_norm"] = "Outro"
        else:
            proj["tipo_projeto_norm"] = proj["tipo_projeto"].capitalize()

        # Normalização de situação/trâmite
        sit = proj["situacao"].upper()
        if "ENCERRADO" in sit:
            proj["situacao_norm"] = "Encerrado"
        elif "VIGÊNCIA" in sit or "VIGENCIA" in sit or "EM VIG" in sit:
            proj["situacao_norm"] = "Em vigência"
        elif "CANC" in sit or "ARQ" in sit or "SUSP" in sit:
            proj["situacao_norm"] = "Cancelado/Suspenso"
        else:
            proj["situacao_norm"] = "Outros"

        # Normalização de Unidades
        unid = proj["unid_norm"] = proj["unidade"].upper()
        if "REITORIA" in unid:
            proj["unid_norm"] = "REITORIA"
        elif "POLI" in unid or "COLÉGIO POLITÉCNICO" in unid:
            proj["unid_norm"] = "POLITÉCNICO"
        elif "CTISM" in unid:
            proj["unid_norm"] = "CTISM"
        elif "FW" in unid or "FREDERICO" in unid:
            proj["unid_norm"] = "UFSM-FW"
        
        projects.append(proj)
        count += 1

    print(f"Total de {count} projetos limpos e processados!")

    # Escrever data.js no workspace
    js_content = f"// UFSM BI Projects Pre-loaded Data\nvar initialProjectsData = {json.dumps(projects, indent=2, ensure_ascii=False)};\n"
    js_path = os.path.join(WORKSPACE_DIR, "data.js")
    with open(js_path, "w", encoding="utf-8") as f:
        f.write(js_content)
    print(f"data.js salvo com sucesso em: {js_path}")

    # Escrever json no workspace para portabilidade
    json_path = os.path.join(WORKSPACE_DIR, "projects_data.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(projects, f, indent=2, ensure_ascii=False)
    print(f"projects_data.json salvo com sucesso em: {json_path}")

if __name__ == "__main__":
    run()
