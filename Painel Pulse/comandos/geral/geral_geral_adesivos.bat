@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa Adesivos (Stickers) na área de trabalho
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StickersEnabled" /v "StickersEnabled" /t REG_DWORD /d 0 /f
:: Desativa via política do sistema
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableStickers" /t REG_DWORD /d 1 /f
exit

:revert
:: Restaura Adesivos na área de trabalho
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StickersEnabled" /v "StickersEnabled" /t REG_DWORD /d 1 /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableStickers" /f 2>nul
exit
