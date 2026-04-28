@echo off
if /i "%~1"=="apply" goto pulseos
if /i "%~1"=="revert" goto pulseos
exit /b

:pulseos
:: Reaplica o padrao PulseOS: historico de recentes/frequentes do Acesso Rapido desativado.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowRecent /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowFrequent /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackDocs /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackProgs /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v JumpListItems_Maximum /t REG_DWORD /d 0 /f
powershell -NoProfile -Command "Remove-Item -Path '%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*' -Force -ErrorAction SilentlyContinue"
powershell -NoProfile -Command "Remove-Item -Path '%APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*' -Force -ErrorAction SilentlyContinue"
exit /b
