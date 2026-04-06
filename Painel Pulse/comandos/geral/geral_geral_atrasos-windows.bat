@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Reduz tempo de espera para encerrar apps e servicos no desligamento
reg add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "2000" /f
reg add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "2000" /f
reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillAppTimeout" /t REG_SZ /d "2000" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "2000" /f
:: NOTA: FastShutdown nao e uma chave de registro reconhecida pelo Windows para controle de
:: desligamento. O Windows nao le esse valor. Mantida apenas por compatibilidade com outras
:: ferramentas que possam referencia-la, mas sem efeito funcional real.
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "FastShutdown" /t REG_DWORD /d 1 /f
:: Desativa o dialogo de registro de motivo de desligamento (servidores Windows)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v "ShutdownReasonOn" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v "ShutdownReasonUI" /t REG_DWORD /d 0 /f
:: Remove atraso artificial de inicializacao dos apps de startup
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f
:: Reduz atraso de exibicao de menus para 0ms (padrao Windows = 400ms) — efeito visual imediato
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "0" /f
:: Aplica imediatamente as configuracoes de Desktop
rundll32.exe user32.dll,UpdatePerUserSystemParameters ,1,True
exit

:revert
reg add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "5000" /f
reg add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "5000" /f
reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillAppTimeout" /t REG_SZ /d "5000" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "5000" /f
reg delete "HKLM\SYSTEM\CurrentControlSet\Control" /v "FastShutdown" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v "ShutdownReasonOn" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v "ShutdownReasonUI" /f 2>nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "400" /f
rundll32.exe user32.dll,UpdatePerUserSystemParameters ,1,True
exit
