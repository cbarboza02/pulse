@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa AMD ReLive (sistema de gravação e streaming de gameplay)
:: Consome VRAM, CPU e memória RAM em segundo plano
reg add "HKLM\SOFTWARE\AMD\CN\DVR" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\DVR" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\DVR" /v "DVREnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\DVR" /v "InstantReplayEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\DVR" /v "RecordingEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\AMD\CN\DVR" /v "StreamingEnabled" /t REG_DWORD /d 0 /f
:: Encerra processos do ReLive em execucao
taskkill /f /im "AMDRSServ.exe" 2>nul
taskkill /f /im "RadeonSoftware.exe" 2>nul
taskkill /f /im "RadeonsoftwareSlimService.exe" 2>nul
:: Para e desativa os servicos AMD relacionados ao ReLive
sc stop "AMD Crash Defender Service" 2>nul
sc config "AMD Crash Defender Service" start= disabled 2>nul
sc stop "AMD Log Utility" 2>nul
sc config "AMD Log Utility" start= disabled 2>nul
exit

:revert
:: Reativa AMD ReLive
reg delete "HKLM\SOFTWARE\AMD\CN\DVR" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\DVR" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\DVR" /v "DVREnabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\DVR" /v "InstantReplayEnabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\DVR" /v "RecordingEnabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\DVR" /v "StreamingEnabled" /f 2>nul
sc config "AMD Crash Defender Service" start= auto 2>nul
sc start "AMD Crash Defender Service" 2>nul
sc config "AMD Log Utility" start= auto 2>nul
sc start "AMD Log Utility" 2>nul
exit
