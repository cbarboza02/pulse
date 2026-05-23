@echo off
setlocal EnableExtensions
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b 1
:reparar
:: Reparar Bluetooth e radios sem fio.
sc config bthserv start= demand >nul 2>&1
sc config BthAvctpSvc start= demand >nul 2>&1
sc config BTAGService start= demand >nul 2>&1
sc config BluetoothUserService start= demand >nul 2>&1
sc config RadioMgmtSvc start= demand >nul 2>&1
sc start bthserv >nul 2>&1
sc start RadioMgmtSvc >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetooth" /v "Value" /t REG_SZ /d "Allow" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync" /v "Value" /t REG_SZ /d "Allow" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetooth" /v "Value" /t REG_SZ /d "Allow" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync" /v "Value" /t REG_SZ /d "Allow" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Wireless\GPTWirelessPolicy" /v "DisableBluetoothDevice" /f >nul 2>&1
pnputil /scan-devices >nul 2>&1
exit /b 0
:padrao
:: Compatibilidade: nenhuma acao necessaria.
exit /b 0
