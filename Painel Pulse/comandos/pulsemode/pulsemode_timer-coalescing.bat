@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o agrupamento de timers (Timer Coalescing)
:: Impede que o Windows agrupe interrupcoes de timer para reduzir latencia de resposta
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f
exit

:revert
:: Restaura o Timer Coalescing ao padrao do Windows
:: Remove a chave para que o kernel use o intervalo padrao (~15.6ms)
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v CoalescingTimerInterval /f 2>nul
exit
