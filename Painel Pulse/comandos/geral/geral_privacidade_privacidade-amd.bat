@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o AMD User Experience Program (coleta de dados de uso e telemetria do driver)
reg add "HKLM\SOFTWARE\AMD\CN\UserExperienceProgram" /v "Participation" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\UserExperienceProgram" /v "Participation" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\AMD\InstallDir" /v "UEPEnabled" /t REG_DWORD /d 0 /f
:: Para e desativa o serviço de coleta de dados AMD
sc stop "AMD Crash Defender Service" 2>nul
sc config "AMD Crash Defender Service" start= disabled 2>nul
:: Desativa tarefas agendadas de coleta de dados AMD
schtasks /Change /TN "AMD\AMD Install\AMD Installer Launcher" /Disable 2>nul
:: Desativa telemetria e coleta de dados do driver e software AMD
reg add "HKLM\SOFTWARE\AMD\CN\Telemetry" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\Telemetry" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\AMD\CN\CN" /v "TelemetryEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\CN" /v "TelemetryEnabled" /t REG_DWORD /d 0 /f
:: Para e desativa o serviço de telemetria AMD (ETDService)
sc stop "AMD External Events Utility" 2>nul
sc config "AMD External Events Utility" start= disabled 2>nul
:: Desativa tarefas agendadas de telemetria AMD
schtasks /Change /TN "AMD\AMD Radeon Software" /Disable 2>nul
schtasks /Change /TN "AMD\AMD CCC-AEMUpdater" /Disable 2>nul
exit

:revert
:: Reativa o Programa de Experiência do Usuário AMD
reg delete "HKLM\SOFTWARE\AMD\CN\UserExperienceProgram" /v "Participation" /f 2>nul
reg delete "HKCU\Software\AMD\CN\UserExperienceProgram" /v "Participation" /f 2>nul
reg delete "HKLM\SOFTWARE\AMD\InstallDir" /v "UEPEnabled" /f 2>nul
sc config "AMD Crash Defender Service" start= auto 2>nul
sc start "AMD Crash Defender Service" 2>nul
schtasks /Change /TN "AMD\AMD Install\AMD Installer Launcher" /Enable 2>nul
:: Reativa telemetria AMD
reg delete "HKLM\SOFTWARE\AMD\CN\Telemetry" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\Telemetry" /v "Enabled" /f 2>nul
reg delete "HKLM\SOFTWARE\AMD\CN\CN" /v "TelemetryEnabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\CN" /v "TelemetryEnabled" /f 2>nul
sc config "AMD External Events Utility" start= auto 2>nul
sc start "AMD External Events Utility" 2>nul
schtasks /Change /TN "AMD\AMD Radeon Software" /Enable 2>nul
schtasks /Change /TN "AMD\AMD CCC-AEMUpdater" /Enable 2>nul
exit
