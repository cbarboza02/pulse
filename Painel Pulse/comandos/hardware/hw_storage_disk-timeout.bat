@echo off
:: Verifica qual argumento foi enviado
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o timeout de disco (0 = sem limite de tempo para resposta do disco)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Disk" /v "TimeOutValue" /t REG_DWORD /d 0 /f
:: Desativa o timeout de operações de I/O para StorAHCI e StorNVMe
reg add "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v "RequestTimeout" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "RequestTimeout" /t REG_DWORD /d 0 /f
exit

:revert
:: Restaura o timeout padrão de disco (120 segundos)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Disk" /v "TimeOutValue" /t REG_DWORD /d 120 /f
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v "RequestTimeout" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "RequestTimeout" /f 2>nul
exit
