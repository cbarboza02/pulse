@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o DeviceSetupManager (DsmSvc) - responsavel por buscar drivers online automaticamente
:: Elimina requisicoes de rede em segundo plano ao conectar novos dispositivos
:: CORRECAO: adicionado >nul 2>&1 nos sc config (imprimia "SUCCESS" ou erro no console)
sc stop DsmSvc 2>nul
sc config DsmSvc start= disabled >nul 2>&1
:: Desativa tambem a busca automatica de drivers na internet via politica
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 0 /f
exit

:revert
sc config DsmSvc start= demand >nul 2>&1
sc start DsmSvc 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" /v "SearchOrderConfig" /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 1 /f
exit
