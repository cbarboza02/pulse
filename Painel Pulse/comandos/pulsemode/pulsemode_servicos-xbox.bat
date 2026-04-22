@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: GameDVR
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d 2 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 2 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f
:: GameBar
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "GamePanelStartupTipIndex" /t REG_DWORD /d 3 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f
:: Servicos Xbox nao essenciais -> modo Manual (demand)
:: XblAuthManager e XblGameSave sao ESSENCIAIS para Xbox Live/GamePass, preservados
sc config XboxGipSvc start= demand >nul 2>&1
sc stop XboxGipSvc 2>nul
sc config XboxNetApiSvc start= demand >nul 2>&1
sc stop XboxNetApiSvc 2>nul
sc config xbgm start= demand >nul 2>&1
sc stop xbgm 2>nul
exit

:revert
:: Restaura GameDVR
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /f 2>nul
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /f 2>nul
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /f 2>nul
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /f 2>nul
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /f 2>nul
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /f 2>nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 1 /f
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "GameDVR_Enabled" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /f 2>nul
:: Restaura GameBar
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar" /v "UseNexusForGameBarEnabled" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar" /v "AllowAutoGameMode" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameBar" /v "AutoGameModeEnabled" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\GameBar" /v "GamePanelStartupTipIndex" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\GameBar" /v "AllowAutoGameMode" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /f 2>nul
:: Servicos Xbox - padrao Manual (NAO auto)
sc config XboxGipSvc start= demand >nul 2>&1
sc config XboxNetApiSvc start= demand >nul 2>&1
sc config xbgm start= demand >nul 2>&1
exit
