@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o Power Throttling globalmente no sistema
:: Impede que o Windows reduza a frequencia da CPU em processos em segundo plano
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f
exit

:revert
:: Restaura o Power Throttling ao comportamento padrao do Windows
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /f 2>nul
exit
