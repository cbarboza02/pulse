@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Limpa Historico do Explorador de Arquivos (File Explorer)
:: LIMPEZA APENAS — nao desativa nenhuma funcionalidade

:: Limpa historico de pastas recentes, Quick Access e menu Iniciar
del /f /q "%APPDATA%\Microsoft\Windows\Recent\*" >nul 2>&1
del /f /q "%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*" >nul 2>&1
del /f /q "%APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*" >nul 2>&1

:: Limpa historico de digitacao na barra de endereco do Explorer
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" /f >nul 2>&1
reg add    "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" /f >nul 2>&1

:: Limpa historico de busca no Explorer (caixa de pesquisa)
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery" /f >nul 2>&1
reg add    "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery" /f >nul 2>&1

:: CORRECAO: As linhas abaixo foram REMOVIDAS pois DESATIVAM funcionalidades,
:: nao apenas limpam o historico. Para desativar o Acesso Rapido,
:: usar o arquivo geral_experiencia_acesso-rapido.bat:
::   reg add ... ShowRecent = 0
::   reg add ... ShowFrequent = 0

:: Reinicia o Explorer para aplicar as mudancas
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
exit

:revert
:: Historico do Explorer e gerado novamente automaticamente pelo uso
:: Nao ha configuracoes alteradas para reverter
exit
