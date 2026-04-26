@echo off
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b

:reparar
:: Reparar Pesquisa do Windows e indexacao.

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /f 2>nul

sc config WSearch start= delayed-auto >nul 2>&1
net stop WSearch >nul 2>&1
net start WSearch >nul 2>&1

taskkill /F /IM SearchHost.exe 2>nul
taskkill /F /IM SearchIndexer.exe 2>nul
taskkill /F /IM SearchProtocolHost.exe 2>nul
taskkill /F /IM SearchFilterHost.exe 2>nul

exit /b

:padrao
:: Reparacao nao altera o padrao PulseOS automaticamente.
exit /b
