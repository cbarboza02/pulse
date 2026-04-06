@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa Miracast (Wireless Display / Projeção sem fio)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Connect" /v "AllowProjectionToPC" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Connect" /v "AllowProjectionToPCOverInfrastructure" /t REG_DWORD /d 0 /f
:: Desativa via chave de usuário
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\WirelessDisplay" /v "MiracastEnabled" /t REG_DWORD /d 0 /f
:: Desativa o serviço correto do Miracast: Wi-Fi Direct Services Connection Manager
:: WFDSConMgrSvc e o servico responsavel pela descoberta e conexao de dispositivos Miracast
sc stop "WFDSConMgrSvc" 2>nul
sc config "WFDSConMgrSvc" start= disabled 2>nul
:: Desativa Miracast via registro do adaptador
reg add "HKLM\SOFTWARE\Microsoft\WirelessDisplay\Settings" /v "EnableInjectorService" /t REG_DWORD /d 0 /f
exit

:revert
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Connect" /v "AllowProjectionToPC" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Connect" /v "AllowProjectionToPCOverInfrastructure" /f 2>nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\WirelessDisplay" /v "MiracastEnabled" /f 2>nul
sc config "WFDSConMgrSvc" start= auto 2>nul
sc start "WFDSConMgrSvc" 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\WirelessDisplay\Settings" /v "EnableInjectorService" /f 2>nul
exit
