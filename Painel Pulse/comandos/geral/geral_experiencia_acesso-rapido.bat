@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o historico de arquivos recentes no Acesso Rapido
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowRecent /t REG_DWORD /d 0 /f
:: Desativa o historico de pastas frequentes no Acesso Rapido
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowFrequent /t REG_DWORD /d 0 /f
:: Limpa o historico atual (destinos automaticos e personalizados)
:: CORRECAO: $env:APPDATA dentro de aspas simples no PowerShell nao e expandido.
:: Substituido por %APPDATA% que e resolvido pelo cmd antes de passar ao PowerShell.
powershell -NoProfile -Command "Remove-Item -Path '%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*' -Force -ErrorAction SilentlyContinue"
powershell -NoProfile -Command "Remove-Item -Path '%APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*' -Force -ErrorAction SilentlyContinue"
exit

:revert
:: Reativa o historico de arquivos recentes e pastas frequentes no Acesso Rapido
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowRecent /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowFrequent /t REG_DWORD /d 1 /f
exit
