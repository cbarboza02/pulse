@echo off
setlocal EnableExtensions
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b 1
:reparar
:: Reparar Menu Iniciar, Shell e Explorer.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -AllUsers Microsoft.Windows.StartMenuExperienceHost -ErrorAction SilentlyContinue | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue};Get-AppxPackage -AllUsers Microsoft.Windows.ShellExperienceHost -ErrorAction SilentlyContinue | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue};Get-AppxPackage -AllUsers MicrosoftWindows.Client.CBS -ErrorAction SilentlyContinue | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue}" >nul 2>&1
taskkill /F /IM StartMenuExperienceHost.exe /T >nul 2>&1
taskkill /F /IM ShellExperienceHost.exe /T >nul 2>&1
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe
exit /b 0
:padrao
:: Compatibilidade: nenhuma acao necessaria.
exit /b 0
