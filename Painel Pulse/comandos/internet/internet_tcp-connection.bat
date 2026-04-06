@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Ajusta as configurações de conexão TCP para melhor desempenho e menor latência
:: Desativa auto-tuning level (evita variações de buffer indesejadas)
netsh int tcp set global autotuninglevel=disabled >nul 2>&1
:: Ativa ECN (Explicit Congestion Notification) para detecção de congestionamento sem perda
netsh int tcp set global ecncapability=enabled >nul 2>&1
:: Define timestamps como desativados (reduz overhead por pacote)
netsh int tcp set global timestamps=disabled >nul 2>&1
:: Configura heurística de autotuning como restrita
netsh int tcp set heuristics disabled >nul 2>&1
:: Define TTL padrão de 64 (padrão Linux/otimizado)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "DefaultTTL" /t REG_DWORD /d 64 /f >nul 2>&1
:: Aumenta o número máximo de conexões TCP semi-abertas
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpMaxHalfOpen" /t REG_DWORD /d 100 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpMaxHalfOpenRetried" /t REG_DWORD /d 80 /f >nul 2>&1
:: Aumenta o tamanho do buffer de janela inicial TCP
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "GlobalMaxTcpWindowSize" /t REG_DWORD /d 65535 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpWindowSize" /t REG_DWORD /d 65535 /f >nul 2>&1
:: Reduz o número de retransmissões antes de desistir
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpMaxDataRetransmissions" /t REG_DWORD /d 3 /f >nul 2>&1
exit

:revert
:: Restaura as configurações padrão de TCP
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global ecncapability=default >nul 2>&1
netsh int tcp set global timestamps=default >nul 2>&1
netsh int tcp set heuristics enabled >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "DefaultTTL" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpMaxHalfOpen" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpMaxHalfOpenRetried" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "GlobalMaxTcpWindowSize" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpWindowSize" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpMaxDataRetransmissions" /f >nul 2>&1
exit
