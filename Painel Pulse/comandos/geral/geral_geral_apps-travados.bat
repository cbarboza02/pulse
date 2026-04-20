@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Ativa encerramento automático de aplicativos que não respondem
reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v "AutoEndTasks" /t REG_SZ /d "1" /f
:: Define tempo de espera antes de encerrar app travado (padrão = 5000ms, otimizado = 2000ms)
reg add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "2000" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillAppTimeout" /t REG_SZ /d "2000" /f
reg add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "2000" /f
:: Define tempo de espera para encerrar serviços (padrão = 5000ms, otimizado = 2000ms)
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "2000" /f
exit

:revert
:: Desativa encerramento automático e restaura tempos padrão
reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "0" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v "AutoEndTasks" /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "5000" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillAppTimeout" /t REG_SZ /d "5000" /f
reg add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "5000" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "5000" /f
exit
