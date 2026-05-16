@echo off
if /i "%~1"=="padrao" goto padrao
if /i "%~1"=="competitivo" goto competitivo
if /i "%~1"=="ultra" goto ultra
exit

:padrao
:: Padrao PulseOS: IoPageLockLimit em 128 MB (134217728 bytes)
:: Aumenta o buffer de memoria travada para I/O sem exagerar no uso de RAM
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v IoPageLockLimit /t REG_DWORD /d 134217728 /f
exit

:competitivo
:: Define o limite de paginas fixas de I/O em 256 MB (268435456 bytes)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v IoPageLockLimit /t REG_DWORD /d 268435456 /f
exit

:ultra
:: Define o limite de paginas fixas de I/O em 512 MB (536870912 bytes)
:: Recomendado apenas para sistemas com 16 GB ou mais de RAM
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v IoPageLockLimit /t REG_DWORD /d 536870912 /f
exit
