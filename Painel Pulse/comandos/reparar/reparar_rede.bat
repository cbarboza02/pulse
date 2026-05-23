@echo off
setlocal EnableExtensions
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b 1
:reparar
:: Reparar rede, DNS, Winsock e Wi-Fi.
sc config Dhcp start= auto >nul 2>&1
sc config Dnscache start= auto >nul 2>&1
sc config NlaSvc start= auto >nul 2>&1
sc config netprofm start= demand >nul 2>&1
sc config WlanSvc start= demand >nul 2>&1
sc config DusmSvc start= auto >nul 2>&1
sc config LanmanWorkstation start= demand >nul 2>&1
netsh winsock reset >nul 2>&1
netsh int ip reset >nul 2>&1
netsh winhttp reset proxy >nul 2>&1
ipconfig /flushdns >nul 2>&1
ipconfig /registerdns >nul 2>&1
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
net start Dhcp >nul 2>&1
net start Dnscache >nul 2>&1
net start NlaSvc >nul 2>&1
net start DusmSvc >nul 2>&1
net start WlanSvc >nul 2>&1
exit /b 0
:padrao
:: Compatibilidade: nenhuma acao necessaria.
exit /b 0
