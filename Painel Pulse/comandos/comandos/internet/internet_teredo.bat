@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o Teredo (tunel IPv6 sobre IPv4) - elimina overhead de encapsulamento
netsh interface teredo set state disabled >nul 2>&1
netsh interface ipv6 set teredo disabled >nul 2>&1
:: CORRECAO: valor 8 (bit 3) desativa apenas Teredo
:: valor 1 desativaria todos os tuneis (6to4, ISATAP e Teredo), que e excessivo
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v "DisabledComponents" /t REG_DWORD /d 8 /f >nul 2>&1
exit

:revert
:: Restaura o Teredo ao estado padrao
netsh interface teredo set state default >nul 2>&1
:: CORRECAO: restaura tambem o comando espelhado do apply
netsh interface ipv6 set teredo default >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v "DisabledComponents" /f >nul 2>&1
exit
