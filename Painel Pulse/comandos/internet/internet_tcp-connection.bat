@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Ajusta configuracoes globais de conexao TCP para menor overhead e latencia
:: Desativa auto-tuning (janela TCP fixa, comportamento previsivel)
netsh int tcp set global autotuninglevel=disabled >nul 2>&1
:: Ativa ECN (deteccao de congestionamento sem perda de pacotes)
netsh int tcp set global ecncapability=enabled >nul 2>&1
:: Desativa timestamps TCP (reduz overhead por pacote)
netsh int tcp set global timestamps=disabled >nul 2>&1
:: Desativa heuristicas de auto-tuning
netsh int tcp set heuristics disabled >nul 2>&1
:: Define janela TCP fixa de 1 MB (adequada para conexoes modernas sem auto-tuning)
:: CORRECAO: 65535 bytes (64KB) era muito restrito para conexoes modernas,
:: substituido por 1048576 bytes (1MB) para equilibrar latencia e throughput
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "GlobalMaxTcpWindowSize" /t REG_DWORD /d 1048576 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpWindowSize" /t REG_DWORD /d 1048576 /f >nul 2>&1
:: Reduz tentativas de retransmissao antes de desistir da conexao
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpMaxDataRetransmissions" /t REG_DWORD /d 3 /f >nul 2>&1
:: REMOVIDO: DefaultTTL = 64 (convencao Linux, sem ganho de desempenho no Windows)
:: REMOVIDO: TcpMaxHalfOpen / TcpMaxHalfOpenRetried (configuracoes da era XP, sem efeito no Win10/11)
exit

:revert
:: Restaura as configuracoes padrao de TCP
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global ecncapability=default >nul 2>&1
netsh int tcp set global timestamps=default >nul 2>&1
netsh int tcp set heuristics enabled >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "GlobalMaxTcpWindowSize" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpWindowSize" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpMaxDataRetransmissions" /f >nul 2>&1
exit
