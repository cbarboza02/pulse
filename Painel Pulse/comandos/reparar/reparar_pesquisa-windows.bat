@echo off
setlocal EnableExtensions
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b 1
:reparar
:: Reparar Pesquisa do Windows e indexacao local.
sc config WSearch start= delayed-auto >nul 2>&1
net stop WSearch >nul 2>&1
net start WSearch >nul 2>&1
taskkill /F /IM SearchHost.exe /T >nul 2>&1
taskkill /F /IM SearchIndexer.exe /T >nul 2>&1
taskkill /F /IM SearchProtocolHost.exe /T >nul 2>&1
taskkill /F /IM SearchFilterHost.exe /T >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -AllUsers MicrosoftWindows.Client.CBS -ErrorAction SilentlyContinue | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue}" >nul 2>&1
exit /b 0
:padrao
:: Compatibilidade: nenhuma acao necessaria.
exit /b 0
