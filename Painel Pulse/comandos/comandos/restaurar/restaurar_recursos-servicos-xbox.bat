@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar Game Bar, Game DVR e servicos Xbox.

:: Restaurar Game DVR/Game Bar para o usuario atual e novos usuarios.
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 1 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 1 /f
reg delete "HKCU\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /f 2>nul

reg add "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 1 /f
reg add "HKU\.DEFAULT\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 1 /f
reg add "HKU\.DEFAULT\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 1 /f
reg add "HKU\.DEFAULT\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 1 /f
reg delete "HKU\.DEFAULT\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /f 2>nul

:: Remover politicas que bloqueiam captura e Game DVR.
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /f 2>nul
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /f 2>nul

:: Reativar servicos Xbox/Store relacionados em modo Manual.
sc config XblAuthManager start= demand >nul 2>&1
sc config XblGameSave start= demand >nul 2>&1
sc config XboxNetApiSvc start= demand >nul 2>&1
sc config XboxGipSvc start= demand >nul 2>&1
sc config xbgm start= demand >nul 2>&1
sc config GamingServices start= demand >nul 2>&1
sc config GamingServicesNet start= demand >nul 2>&1

sc start XblAuthManager >nul 2>&1
sc start XblGameSave >nul 2>&1
sc start XboxNetApiSvc >nul 2>&1
sc start XboxGipSvc >nul 2>&1
sc start GamingServices >nul 2>&1
sc start GamingServicesNet >nul 2>&1

:: Re-registrar pacotes Xbox/Gaming se estiverem instalados.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-AppxPackage -AllUsers Microsoft.XboxGamingOverlay -ErrorAction SilentlyContinue | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue};" ^
  "Get-AppxPackage -AllUsers Microsoft.GamingApp -ErrorAction SilentlyContinue | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue};" ^
  "Get-AppxPackage -AllUsers Microsoft.GamingServices -ErrorAction SilentlyContinue | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue}"

taskkill /F /IM GameBar.exe 2>nul
taskkill /F /IM GameBarFTServer.exe 2>nul
exit /b

:padrao
:: Reaplicar padrao PulseOS: Game Bar/Game DVR desativados e servicos Xbox nao essenciais em Manual/Desativados.

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /t REG_DWORD /d 0 /f

reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f

reg add "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f
reg add "HKU\.DEFAULT\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
reg add "HKU\.DEFAULT\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 0 /f
reg add "HKU\.DEFAULT\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f
reg add "HKU\.DEFAULT\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f

sc stop xbgm >nul 2>&1
sc config xbgm start= disabled >nul 2>&1

sc config XblAuthManager start= demand >nul 2>&1
sc config XblGameSave start= demand >nul 2>&1
sc config XboxNetApiSvc start= demand >nul 2>&1
sc config XboxGipSvc start= demand >nul 2>&1
sc config GamingServices start= demand >nul 2>&1
sc config GamingServicesNet start= demand >nul 2>&1

taskkill /F /IM GameBar.exe 2>nul
taskkill /F /IM GameBarFTServer.exe 2>nul
exit /b
