@echo off
echo =================================================================
echo UFSM BI - Atualizando Dados Locais das Planilhas Google
echo =================================================================
echo.
echo [1/3] Sincronizando e processando "Projetos Contratados"...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0process_data.ps1"
echo.
echo [2/3] Sincronizando e processando "Ganhos Economicos PI"...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0process_ganhos.ps1"
echo.
echo [3/3] Sincronizando e processando "Propriedade Intelectual"...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0process_pi.ps1"
echo.
echo =================================================================
echo Processamento concluido com sucesso!
echo Pressione qualquer tecla para fechar esta janela...
echo =================================================================
pause > nul
