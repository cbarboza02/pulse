@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o Network Throttling Index
:: O Windows limita o processamento de pacotes de rede a ~10 pacotes/ms por padrão
:: Definir como 0xFFFFFFFF (4294967295) remove esse limite
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 4294967295 /f >nul 2>&1
exit

:revert
:: Restaura o limite padrão do Network Throttling Index (10 pacotes/ms)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 10 /f >nul 2>&1
exit
