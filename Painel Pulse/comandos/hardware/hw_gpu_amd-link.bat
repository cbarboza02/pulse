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
exit

:revert
:: Reativa AMD Link
reg delete "HKLM\SOFTWARE\AMD\CN\Link" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\Link" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\Link" /v "AMDLinkEnabled" /f 2>nul
sc config "AMD Link Server" start= auto 2>nul
sc start "AMD Link Server" 2>nul
exit
