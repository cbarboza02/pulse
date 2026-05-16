@echo off
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b

:reparar
:: Reparar Menu Iniciar, ShellExperienceHost e Explorer.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-AppxPackage -AllUsers Microsoft.Windows.StartMenuExperienceHost -ErrorAction SilentlyContinue | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue};" ^
  "Get-AppxPackage -AllUsers Microsoft.Windows.ShellExperienceHost -ErrorAction SilentlyContinue | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue};" ^
  "Get-AppxPackage -AllUsers MicrosoftWindows.Client.CBS -ErrorAction SilentlyContinue | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue}"

taskkill /F /IM StartMenuExperienceHost.exe 2>nul
taskkill /F /IM ShellExperienceHost.exe 2>nul
taskkill /F /IM explorer.exe 2>nul
start explorer.exe
exit /b

:padrao
:: Reparacao nao altera o padrao PulseOS automaticamente.
exit /b
