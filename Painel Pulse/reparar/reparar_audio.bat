@echo off
setlocal EnableExtensions
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b 1
:reparar
:: Reparar servicos e dispositivos de audio.
sc config AudioEndpointBuilder start= auto >nul 2>&1
sc config Audiosrv start= auto >nul 2>&1
sc config MMCSS start= auto >nul 2>&1
net stop Audiosrv /y >nul 2>&1
net stop AudioEndpointBuilder /y >nul 2>&1
net start MMCSS >nul 2>&1
net start AudioEndpointBuilder >nul 2>&1
net start Audiosrv >nul 2>&1
pnputil /scan-devices >nul 2>&1
exit /b 0
:padrao
:: Compatibilidade: nenhuma acao necessaria.
exit /b 0
