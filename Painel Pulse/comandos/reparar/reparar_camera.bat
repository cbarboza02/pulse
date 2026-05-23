@echo off
setlocal EnableExtensions
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b 1
:reparar
:: Reparar camera, microfone e captura.
sc config FrameServer start= demand >nul 2>&1
sc config FrameServerMonitor start= demand >nul 2>&1
sc config camsvc start= demand >nul 2>&1
sc config stisvc start= demand >nul 2>&1
sc start FrameServer >nul 2>&1
sc start camsvc >nul 2>&1
sc start stisvc >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Allow" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Allow" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v "Value" /t REG_SZ /d "Allow" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v "Value" /t REG_SZ /d "Allow" /f >nul 2>&1
pnputil /scan-devices >nul 2>&1
exit /b 0
:padrao
:: Compatibilidade: nenhuma acao necessaria.
exit /b 0
