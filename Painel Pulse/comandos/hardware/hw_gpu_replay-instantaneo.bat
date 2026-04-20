@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa AMD Instant Replay (grava os últimos minutos de gameplay em segundo plano)
:: Consome VRAM, CPU e disco mesmo quando não está gravando ativamente
reg add "HKLM\SOFTWARE\AMD\CN\InstantReplay" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\InstantReplay" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\DVR" /v "InstantReplayEnabled" /t REG_DWORD /d 0 /f
:: Para e desativa serviços relacionados ao Instant Replay
sc stop "AMDRSLinuxAgent" 2>nul
sc config "AMDRSLinuxAgent" start= disabled 2>nul
exit

:revert
:: Reativa AMD Instant Replay
reg delete "HKLM\SOFTWARE\AMD\CN\InstantReplay" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\InstantReplay" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\DVR" /v "InstantReplayEnabled" /f 2>nul
sc config "AMDRSLinuxAgent" start= auto 2>nul
sc start "AMDRSLinuxAgent" 2>nul
exit
