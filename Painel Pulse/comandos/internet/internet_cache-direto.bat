@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Ativa o Acesso Direto ao Cache (DCA - Direct Cache Access)
:: Permite que dados de rede sejam escritos diretamente no cache da CPU,
:: reduzindo latencia de memoria e ciclos de busca em operacoes de rede
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "EnableDCA" /t REG_DWORD /d 1 /f >nul 2>&1
:: Ativa RSS (Receive Side Scaling) para distribuicao de carga entre nucleos
netsh int tcp set global rss=enabled >nul 2>&1
:: Habilita Direct Cache Access globalmente
netsh int tcp set global dca=enabled >nul 2>&1
:: CORRECAO: Chimney Offload foi removido no Windows 8.1+ e nao funciona no Windows 10/11 - removido
exit

:revert
:: Desativa as configuracoes de acesso direto ao cache
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "EnableDCA" /f >nul 2>&1
netsh int tcp set global dca=disabled >nul 2>&1
:: CORRECAO: restaura RSS ao padrao (enabled), espelhando o apply
netsh int tcp set global rss=enabled >nul 2>&1
exit
