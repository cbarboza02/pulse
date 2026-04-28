@echo off
:: Verifica qual argumento foi enviado
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o Fault Tolerant Heap (FTH) - elimina overhead de monitoramento de heap
reg add "HKLM\SOFTWARE\Microsoft\FTH" /v "Enabled" /t REG_DWORD /d 0 /f
:: Desativa o FTH também para processos de 32 bits em sistemas 64 bits
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\FTH" /v "Enabled" /t REG_DWORD /d 0 /f
exit

:revert
:: Reativa o Fault Tolerant Heap (FTH) - padrão do Windows
reg add "HKLM\SOFTWARE\Microsoft\FTH" /v "Enabled" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\FTH" /v "Enabled" /t REG_DWORD /d 1 /f
exit
