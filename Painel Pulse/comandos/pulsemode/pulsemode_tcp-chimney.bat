@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa offload de tarefas TCP/IP na pilha de rede
:: CORRECAO: removidos os comandos de TCP Chimney Offload (chimney=disabled/default)
:: O Chimney Offload foi removido no Windows 8.1+ e nao existe no Windows 10/11
netsh int ip set global taskoffload=disabled >nul 2>&1
:: Desativa offload de checksum e tarefas TCP via registro para todas as NICs
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "DisableTaskOffload" /t REG_DWORD /d 1 /f >nul 2>&1
exit

:revert
:: Restaura offload de tarefas TCP ao padrao do Windows
netsh int ip set global taskoffload=enabled >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "DisableTaskOffload" /f >nul 2>&1
exit
