@echo off
if /i "%~1"=="padrao" goto padrao
if /i "%~1"=="gaming" goto gaming
if /i "%~1"=="competitivo" goto competitivo
exit

:padrao
:: Padrao PulseOS: fila de mouse e teclado com 50 entradas
:: Reduz levemente o buffer para menor latencia sem impactar estabilidade
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v MouseDataQueueSize /t REG_DWORD /d 50 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v KeyboardDataQueueSize /t REG_DWORD /d 50 /f
exit

:gaming
:: Fila de mouse e teclado com 25 entradas
:: Buffer reduzido para menor latencia em jogos competitivos
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v MouseDataQueueSize /t REG_DWORD /d 25 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v KeyboardDataQueueSize /t REG_DWORD /d 25 /f
exit

:competitivo
:: Fila de mouse e teclado com 16 entradas (minimo estavel recomendado)
:: Buffer minimo para latencia mais baixa possivel
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v MouseDataQueueSize /t REG_DWORD /d 16 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v KeyboardDataQueueSize /t REG_DWORD /d 16 /f
exit
