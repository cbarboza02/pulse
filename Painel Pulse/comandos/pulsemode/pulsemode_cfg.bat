@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o Control Flow Guard (CFG) globalmente no sistema
:: CFG adiciona verificacoes em cada chamada de funcao indireta, causando overhead de CPU
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /t REG_QWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions" /t REG_QWORD /d 0 /f
:: Desativa CFG via politica de exploracao de sistema (Process Mitigation Policy)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\*" /v "MitigationOptions" /t REG_QWORD /d 0 /f
exit

:revert
:: Restaura o CFG ao comportamento padrao (remove os overrides)
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\*" /v "MitigationOptions" /f 2>nul
exit
