@echo off
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b

:reparar
:: Reparar pilha de rede, DNS, Winsock e servicos basicos.

sc config Dhcp start= auto >nul 2>&1
sc config Dnscache start= auto >nul 2>&1
sc config NlaSvc start= auto >nul 2>&1
sc config netprofm start= demand >nul 2>&1
sc config WlanSvc start= auto >nul 2>&1
sc config LanmanWorkstation start= auto >nul 2>&1

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
net start WlanSvc >nul 2>&1

exit /b

:padrao
:: Reparacao nao altera o padrao PulseOS automaticamente.
exit /b
