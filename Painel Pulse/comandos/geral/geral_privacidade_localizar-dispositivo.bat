@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: ============================================================
:: DESATIVAR LOCALIZAR MEU DISPOSITIVO (Find My Device)
:: ============================================================

:: --- Desativar via Política de Grupo ---
reg add "HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice" /v "AllowFindMyDevice" /t REG_DWORD /d 0 /f

:: --- Desativar sincronização de localização ---
reg add "HKLM\SOFTWARE\Microsoft\Settings\FindMyDevice" /v "LocationSyncEnabled" /t REG_DWORD /d 0 /f

:: --- Desativar serviço FindMyDevice ---
sc config "FindMyDevice" start= disabled 2>nul
sc stop   "FindMyDevice" 2>nul

:: --- Desativar localização (base para o Find My Device) ---
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f

exit

:revert
:: ============================================================
:: REATIVAR LOCALIZAR MEU DISPOSITIVO
:: ============================================================

reg delete "HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice" /v "AllowFindMyDevice"  /f 2>nul
reg add    "HKLM\SOFTWARE\Microsoft\Settings\FindMyDevice"  /v "LocationSyncEnabled" /t REG_DWORD /d 1 /f

sc config "FindMyDevice" start= auto 2>nul
sc start  "FindMyDevice" 2>nul

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /f 2>nul
reg add    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Allow" /f

exit
