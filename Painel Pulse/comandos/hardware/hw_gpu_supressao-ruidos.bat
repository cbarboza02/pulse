@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
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
:: Reativa AMD Noise Suppression
reg delete "HKLM\SOFTWARE\AMD\CN\NoiseSuppression" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\NoiseSuppression" /v "Enabled" /f 2>nul
reg delete "HKCU\Software\AMD\CN\Audio" /v "NoiseSuppressionEnabled" /f 2>nul
sc config "AMDAudioService" start= auto 2>nul
sc start "AMDAudioService" 2>nul
exit
