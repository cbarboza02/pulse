@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa AMD Link (streaming de jogos para dispositivos móveis)
:: Mantém um servidor em segundo plano aguardando conexões, consome recursos
reg add "HKLM\SOFTWARE\AMD\CN\Link" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\Link" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\Link" /v "AMDLinkEnabled" /t REG_DWORD /d 0 /f
:: Encerra e desativa o processo/serviço do AMD Link
taskkill /f /im "AMDLink.exe" 2>nul
sc stop "AMD Link Server" 2>nul
sc config "AMD Link Server" start= disabled 2>nul
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
:: Desativa AMD Instant Replay (grava os últimos minutos de gameplay em segundo plano)
:: Consome VRAM, CPU e disco mesmo quando não está gravando ativamente
reg add "HKLM\SOFTWARE\AMD\CN\InstantReplay" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\InstantReplay" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\DVR" /v "InstantReplayEnabled" /t REG_DWORD /d 0 /f
:: Para e desativa serviços relacionados ao Instant Replay
sc stop "AMDRSLinuxAgent" 2>nul
sc config "AMDRSLinuxAgent" start= disabled 2>nul
:: Desativa AMD Noise Suppression (processamento de áudio via GPU/driver AMD)
:: Consome ciclos de GPU e CPU mesmo quando o microfone não está em uso
reg add "HKLM\SOFTWARE\AMD\CN\NoiseSuppression" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\NoiseSuppression" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\Audio" /v "NoiseSuppressionEnabled" /t REG_DWORD /d 0 /f
:: Desativa via driver de áudio AMD (se instalado)
sc stop "AMDAudioService" 2>nul
sc config "AMDAudioService" start= disabled 2>nul
exit

:revert
:: Reativa AMD Link
reg delete "HKLM\SOFTWARE\AMD\CN\Link" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\Link" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\Link" /v "AMDLinkEnabled" /f 2>nul
sc config "AMD Link Server" start= auto 2>nul
sc start "AMD Link Server" 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Connect" /v "AllowProjectionToPC" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Connect" /v "AllowProjectionToPCOverInfrastructure" /f 2>nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\WirelessDisplay" /v "MiracastEnabled" /f 2>nul
sc config "WFDSConMgrSvc" start= auto 2>nul
sc start "WFDSConMgrSvc" 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\WirelessDisplay\Settings" /v "EnableInjectorService" /f 2>nul
:: Reativa AMD Instant Replay
reg delete "HKLM\SOFTWARE\AMD\CN\InstantReplay" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\InstantReplay" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\DVR" /v "InstantReplayEnabled" /f 2>nul
sc config "AMDRSLinuxAgent" start= auto 2>nul
sc start "AMDRSLinuxAgent" 2>nul
:: Reativa AMD Noise Suppression
reg delete "HKLM\SOFTWARE\AMD\CN\NoiseSuppression" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\NoiseSuppression" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\Audio" /v "NoiseSuppressionEnabled" /f 2>nul
sc config "AMDAudioService" start= auto 2>nul
sc start "AMDAudioService" 2>nul
exit
