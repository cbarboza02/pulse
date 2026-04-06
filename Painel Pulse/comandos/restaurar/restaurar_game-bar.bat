@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar Game Bar e GameDVR ao padrao do Windows 11

:: Remove a politica de grupo que bloqueia o GameDVR
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /f 2>nul

:: Restaura servicos Xbox ao estado padrao (Manual/Automatico)
:: CORRECAO: xbgm (Xbox Game Monitoring) era desabilitado pelo script PS1
:: mas nao era restaurado. Adicionado.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Set-Service -Name 'XboxNetApiSvc' -StartupType Manual  -ErrorAction SilentlyContinue;" ^
  "Set-Service -Name 'XblGameSave'   -StartupType Automatic -ErrorAction SilentlyContinue;" ^
  "Start-Service -Name 'XblGameSave' -ErrorAction SilentlyContinue;" ^
  "if (Get-Service -Name 'xbgm' -ErrorAction SilentlyContinue) {" ^
  "  Set-Service -Name 'xbgm' -StartupType Manual -ErrorAction SilentlyContinue" ^
  "}"

:: Restaura captura de gameplay (GameDVR)
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 1 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 1 /f

:: Remove overrides de Full-Screen Exclusive (FSE)
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior"                    /f 2>nul
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode"                 /f 2>nul
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode"        /f 2>nul
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible"   /f 2>nul

:: Restaura Game Bar (Win+G overlay)
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "GameDVR_Enabled" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 1 /f
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar" /v "AllowAutoGameMode"   /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar" /v "AutoGameModeEnabled" /f 2>nul
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 1 /f
reg delete "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /f 2>nul
exit /b

:padrao
:: Re-aplicar desativacao da Game Bar e GameDVR

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Stop-Service -Name 'XboxNetApiSvc' -Force -ErrorAction SilentlyContinue;" ^
  "Set-Service  -Name 'XboxNetApiSvc' -StartupType Disabled -ErrorAction SilentlyContinue;" ^
  "Stop-Service -Name 'XblGameSave'   -Force -ErrorAction SilentlyContinue;" ^
  "Set-Service  -Name 'XblGameSave'   -StartupType Disabled -ErrorAction SilentlyContinue;" ^
  "if (Get-Service -Name 'xbgm' -ErrorAction SilentlyContinue) {" ^
  "  Stop-Service -Name 'xbgm' -Force -ErrorAction SilentlyContinue;" ^
  "  Set-Service  -Name 'xbgm' -StartupType Disabled -ErrorAction SilentlyContinue" ^
  "}"

reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled"  /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "GameDVR_Enabled"    /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled"                           /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior"                       /t REG_DWORD /d 2 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode"                   /t REG_DWORD /d 2 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode"          /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible"    /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar" /v "AllowAutoGameMode"         /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar" /v "AutoGameModeEnabled"       /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel"          /t REG_DWORD /d 0 /f
exit /b
