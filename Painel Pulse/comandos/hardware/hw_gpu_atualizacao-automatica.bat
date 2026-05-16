@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa atualização automática de software e drivers AMD
reg add "HKLM\SOFTWARE\AMD\CN\AutoUpdate" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\AutoUpdate" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\AMD\CN\AutoUpdate" /v "AutoDownload" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\AMD\CN\AutoUpdate" /v "AutoInstall" /t REG_DWORD /d 0 /f
:: Para e desativa o serviço AMD Update
sc stop "AMD Update" 2>nul
sc config "AMD Update" start= disabled 2>nul
:: Desativa tarefas agendadas de update AMD
schtasks /Change /TN "AMD\AMD Install\AMD Installer" /Disable 2>nul
schtasks /Change /TN "AMD\AMD Install\AMD Installer Launcher" /Disable 2>nul
exit

:revert
:: Reativa atualização automática de drivers AMD
reg delete "HKLM\SOFTWARE\AMD\CN\AutoUpdate" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\AutoUpdate" /v "Enabled" /f 2>nul
reg delete "HKLM\SOFTWARE\AMD\CN\AutoUpdate" /v "AutoDownload" /f 2>nul
reg delete "HKLM\SOFTWARE\AMD\CN\AutoUpdate" /v "AutoInstall" /f 2>nul
sc config "AMD Update" start= auto 2>nul
sc start "AMD Update" 2>nul
schtasks /Change /TN "AMD\AMD Install\AMD Installer" /Enable 2>nul
schtasks /Change /TN "AMD\AMD Install\AMD Installer Launcher" /Enable 2>nul
exit
