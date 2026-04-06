@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa ISATAP (Intra-Site Automatic Tunnel Addressing Protocol)
netsh interface isatap set state disabled >nul 2>&1
:: Desativa 6to4 (tunel automatico IPv6 sobre IPv4)
netsh interface 6to4 set state disabled >nul 2>&1
:: CORRECAO: os caminhos de registro originais (TCPIP6TUNNEL e tunnel\Parameters)
:: nao sao chaves padrao do Windows e nao tem efeito real - removidos.
:: O mecanismo real de desativacao persistente e via netsh (persiste entre reboots).
exit

:revert
:: Restaura ISATAP e 6to4 ao estado padrao
netsh interface isatap set state default >nul 2>&1
netsh interface 6to4 set state default >nul 2>&1
exit
