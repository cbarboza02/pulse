@echo off
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b

:reparar
:: Reparar servicos de audio.

sc config AudioEndpointBuilder start= auto >nul 2>&1
sc config Audiosrv start= auto >nul 2>&1
sc config MMCSS start= auto >nul 2>&1

net stop Audiosrv /y >nul 2>&1
net stop AudioEndpointBuilder /y >nul 2>&1
net start MMCSS >nul 2>&1
net start AudioEndpointBuilder >nul 2>&1
net start Audiosrv >nul 2>&1

pnputil /scan-devices >nul 2>&1
exit /b

:padrao
:: Reparacao nao altera o padrao PulseOS automaticamente.
exit /b
