@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Define o maior valor possivel para agrupar ao maximo os servicos
:: Reduz ao maximo o numero de processos svchost.exe em segundo plano
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d 4294967295 /f >nul 2>&1
exit

:revert
:: Padrao PulseOS: threshold igual a RAM instalada em KB
:: Mantem a reducao de svchost.exe de forma ajustada ao hardware atual
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ramKB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1KB); reg add 'HKLM\SYSTEM\CurrentControlSet\Control' /v 'SvcHostSplitThresholdInKB' /t REG_DWORD /d $ramKB /f" >nul 2>&1
exit
