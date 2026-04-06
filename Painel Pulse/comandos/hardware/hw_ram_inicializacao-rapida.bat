@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa a Inicializacao Rapida (Fast Startup / Hiberboot)
:: Garante um desligamento e inicializacao completos, eliminando estado de hibernacao parcial
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f
exit

:revert
:: Reativa a Inicializacao Rapida do Windows
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 1 /f
exit
