@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa os Synthetic Timers do Hyper-V e do kernel do Windows
:: Forca o uso do TSC (Time Stamp Counter) nativo como fonte de clock
bcdedit /set useplatformclock false >nul 2>&1
:: Desativa o tick dinamico (tickless kernel) para reducao de latencia de timer
bcdedit /set disabledynamictick yes >nul 2>&1
:: Sincronizacao de TSC aprimorada entre nucleos
bcdedit /set tscsyncpolicy enhanced >nul 2>&1
:: Impede que processos degradem a resolucao global do timer do sistema
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d 1 /f >nul 2>&1
exit

:revert
:: CORRECAO: usar /deletevalue em vez de /set true - remove a entrada completamente,
:: restaurando o comportamento padrao sem forcar um valor explicito
:: (consistente com os outros /deletevalue do mesmo revert)
bcdedit /deletevalue useplatformclock >nul 2>&1
bcdedit /deletevalue disabledynamictick >nul 2>&1
bcdedit /deletevalue tscsyncpolicy >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "GlobalTimerResolutionRequests" /f >nul 2>&1
exit
