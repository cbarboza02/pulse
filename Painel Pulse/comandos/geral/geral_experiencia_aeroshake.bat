@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o AeroShake (agitar a janela para minimizar todas as outras)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisallowShaking /t REG_DWORD /d 1 /f
:: Politica de bloqueio em nivel de sistema
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v NoWindowMinimizingShortcuts /t REG_DWORD /d 1 /f
exit

:revert
:: Reativa o AeroShake
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisallowShaking /t REG_DWORD /d 0 /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v NoWindowMinimizingShortcuts /f >nul 2>&1
exit
