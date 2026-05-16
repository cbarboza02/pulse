@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa as Otimizacoes de Tela Cheia globalmente via GameConfigStore
:: Forca o modo exclusivo verdadeiro (FSE) em vez do modo borderless gerenciado pelo DWM
reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d 1 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d 2 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 2 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 1 /f
:: Desativa via politica de sistema (afeta todos os usuarios)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 2 /f
exit

:revert
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /f 2>nul
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /f 2>nul
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /f 2>nul
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "GameDVR_FSEBehaviorMode" /f 2>nul
exit
