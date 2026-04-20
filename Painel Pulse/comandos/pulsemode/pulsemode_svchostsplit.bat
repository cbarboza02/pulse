@echo off
if /i "%~1"=="padrao" goto padrao
if /i "%~1"=="maximo" goto maximo
if /i "%~1"=="automatico" goto automatico
exit

:padrao
:: Remove o override e restaura o comportamento padrao do Windows
:: (padrao: ~3670016 KB / 3.5 GB - servicos se separam em sistemas com mais de 3.5 GB de RAM)
reg delete "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /f >nul 2>&1
exit

:maximo
:: Define o maior valor possivel para agrupar ao maximo os servicos
:: Reduz ao maximo o numero de processos svchost.exe em segundo plano
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d 4294967295 /f >nul 2>&1
exit

:automatico
:: Detecta a RAM instalada e define o threshold igual ao total de RAM em KB
:: Impede que servicos se separem neste sistema especifico, reduzindo processos em segundo plano
:: CORRECAO: substituido wmic (removido no Windows 11 22H2+) por Get-CimInstance via PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ramKB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1KB); reg add 'HKLM\SYSTEM\CurrentControlSet\Control' /v 'SvcHostSplitThresholdInKB' /t REG_DWORD /d $ramKB /f" >nul 2>&1
exit
