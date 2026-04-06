@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: ============================================================
:: DESATIVAR SENSORES
:: ============================================================

:: --- Desativar serviços de sensores ---
sc config "SensorService"     start= demand
sc stop   "SensorService"     2>nul
sc config "SensorDataService" start= disabled
sc stop   "SensorDataService" 2>nul
sc config "SensrSvc"          start= disabled
sc stop   "SensrSvc"          2>nul
sc config "SensorFrameworkSvc" start= disabled
sc stop   "SensorFrameworkSvc" 2>nul

:: --- Desativar localização e sensores via Política de Grupo ---
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation"                    /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableSensors"                     /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableWindowsLocationProvider"     /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocationScripting"           /t REG_DWORD /d 1 /f

:: --- Desativar permissão de localização para o usuário ---
reg add "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v "CheckedOEMPrivacyPolicy" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v "SensorPermissionState"   /t REG_DWORD /d 0 /f

:: --- Desativar localização via política de privacidade ---
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f

exit

:revert
:: ============================================================
:: REATIVAR SENSORES
:: ============================================================

sc config "SensorService"      start= demand
sc start  "SensorService"      2>nul
sc config "SensorDataService"  start= demand
sc start  "SensorDataService"  2>nul
sc config "SensrSvc"           start= demand
sc start  "SensrSvc"           2>nul
sc config "SensorFrameworkSvc" start= demand
sc start  "SensorFrameworkSvc" 2>nul

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation"                /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableSensors"                 /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableWindowsLocationProvider" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocationScripting"       /f 2>nul

reg add "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v "CheckedOEMPrivacyPolicy" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v "SensorPermissionState"   /t REG_DWORD /d 1 /f

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Allow" /f

exit
