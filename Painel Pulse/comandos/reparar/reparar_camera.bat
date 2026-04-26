@echo off
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b

:reparar
:: Reparar camera, scanner e permissoes de captura.

sc config FrameServer start= demand >nul 2>&1
sc config stisvc start= demand >nul 2>&1
sc start FrameServer >nul 2>&1
sc start stisvc >nul 2>&1

reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Allow" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Allow" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v "Value" /t REG_SZ /d "Allow" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v "Value" /t REG_SZ /d "Allow" /f

pnputil /scan-devices >nul 2>&1
exit /b

:padrao
:: Reparacao nao altera o padrao PulseOS automaticamente.
exit /b
