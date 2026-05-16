@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa AMD Crash Defender (monitora o sistema em segundo plano e envia relatórios de crash)
:: Consome CPU e disco continuamente para monitoramento
sc stop "AMD Crash Defender Service" 2>nul
sc config "AMD Crash Defender Service" start= disabled 2>nul
:: Desativa via registro
reg add "HKLM\SOFTWARE\AMD\CN\CrashDefender" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\CrashDefender" /v "Enabled" /t REG_DWORD /d 0 /f
:: Encerra o processo se estiver rodando
taskkill /f /im "AMDCrashDefender.exe" 2>nul
exit

:revert
:: Reativa AMD Crash Defender
sc config "AMD Crash Defender Service" start= auto 2>nul
sc start "AMD Crash Defender Service" 2>nul
reg delete "HKLM\SOFTWARE\AMD\CN\CrashDefender" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\CrashDefender" /v "Enabled" /f 2>nul
exit
