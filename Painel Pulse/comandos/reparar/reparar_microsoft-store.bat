@echo off
setlocal EnableExtensions
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b 1
:reparar
:: Reparar Microsoft Store, licencas e cache.
reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /f >nul 2>&1
sc config AppXSvc start= demand >nul 2>&1
sc config ClipSVC start= demand >nul 2>&1
sc config LicenseManager start= demand >nul 2>&1
sc config wlidsvc start= demand >nul 2>&1
sc config TokenBroker start= demand >nul 2>&1
sc config InstallService start= demand >nul 2>&1
sc config wuauserv start= demand >nul 2>&1
sc config bits start= demand >nul 2>&1
sc start AppXSvc >nul 2>&1
sc start ClipSVC >nul 2>&1
sc start LicenseManager >nul 2>&1
sc start wlidsvc >nul 2>&1
sc start InstallService >nul 2>&1
sc start wuauserv >nul 2>&1
sc start bits >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -AllUsers Microsoft.WindowsStore -ErrorAction SilentlyContinue | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue};Get-AppxPackage -AllUsers Microsoft.StorePurchaseApp -ErrorAction SilentlyContinue | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue};Get-AppxPackage -AllUsers Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue}" >nul 2>&1
start "" wsreset.exe
exit /b 0
:padrao
:: Compatibilidade: nenhuma acao necessaria.
exit /b 0
