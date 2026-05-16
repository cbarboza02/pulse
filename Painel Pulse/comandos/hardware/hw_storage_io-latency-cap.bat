@echo off
:: Verifica qual argumento foi enviado
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Remove o limite de latência de I/O do driver AHCI (0 = sem limite superior)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v "IoLatencyCap" /t REG_DWORD /d 0 /f
:: Remove o limite de latência de I/O do driver NVMe
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IoLatencyCap" /t REG_DWORD /d 0 /f
:: Desativa throttling de I/O para o disco do sistema
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\I/O System" /v "IoTransferThreshold" /t REG_DWORD /d 0 /f
exit

:revert
:: Restaura o limite de latência de I/O ao padrão (controlado pelo driver)
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v "IoLatencyCap" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IoLatencyCap" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\I/O System" /v "IoTransferThreshold" /f 2>nul
exit
