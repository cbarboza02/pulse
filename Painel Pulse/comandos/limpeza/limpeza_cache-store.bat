@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Limpa Cache da Microsoft Store

:: Para o serviço da Store temporariamente
net stop AppXSvc /y >nul 2>&1

:: Limpa cache principal da Store via WSReset (silencioso)
wsreset.exe >nul 2>&1

:: Aguarda a conclusão do WSReset
timeout /t 5 /nobreak >nul

:: Limpa manualmente os diretórios de cache da Store
del /f /s /q "%LOCALAPPDATA%\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalCache\*" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\AC\*" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\cache\*" >nul 2>&1

:: Limpa cache de pacotes baixados pela Store
del /f /s /q "%LOCALAPPDATA%\Temp\WinGet\*" >nul 2>&1

:: Limpa temporários de instalação de pacotes AppX
del /f /s /q "%LOCALAPPDATA%\Temp\*AppX*" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Temp\*Msix*" >nul 2>&1

:: Reinicia o serviço
net start AppXSvc >nul 2>&1

exit

:revert
:: O cache da Microsoft Store é regenerado automaticamente ao abrir a Store
:: Nenhuma ação de reversão necessária
exit
