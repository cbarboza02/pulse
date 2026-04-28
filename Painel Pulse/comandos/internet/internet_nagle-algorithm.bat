@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o Nagle Algorithm para todas as interfaces de rede
:: O Nagle agrupa pacotes pequenos, causando latencia extra em jogos/tempo real
:: CORRECAO: reg query retorna "HKEY_LOCAL_MACHINE", nao "HKLM" - findstr ajustado
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul ^| findstr /i "HKEY_LOCAL_MACHINE"') do (
    reg add "%%i" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%i" /v "TCPNoDelay" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%i" /v "TcpDelAckTicks" /t REG_DWORD /d 0 /f >nul 2>&1
)
reg add "HKLM\SOFTWARE\Microsoft\MSMQ\Parameters" /v "TCPNoDelay" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f >nul 2>&1
exit

:revert
:: Restaura o comportamento padrao do Nagle Algorithm
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul ^| findstr /i "HKEY_LOCAL_MACHINE"') do (
    reg delete "%%i" /v "TcpAckFrequency" /f >nul 2>&1
    reg delete "%%i" /v "TCPNoDelay" /f >nul 2>&1
    reg delete "%%i" /v "TcpDelAckTicks" /f >nul 2>&1
)
reg delete "HKLM\SOFTWARE\Microsoft\MSMQ\Parameters" /v "TCPNoDelay" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpAckFrequency" /f >nul 2>&1
exit
