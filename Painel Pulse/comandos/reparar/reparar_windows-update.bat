@echo off
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b

:reparar
:: Reparar Windows Update, BITS e cache de atualizacoes.

sc config wuauserv start= demand >nul 2>&1
sc config bits start= delayed-auto >nul 2>&1
sc config cryptsvc start= auto >nul 2>&1
sc config usosvc start= demand >nul 2>&1
sc config WaaSMedicSvc start= demand >nul 2>&1
sc config msiserver start= demand >nul 2>&1

net stop wuauserv /y >nul 2>&1
net stop bits /y >nul 2>&1
net stop cryptsvc /y >nul 2>&1
net stop usosvc /y >nul 2>&1

if exist "%SystemRoot%\SoftwareDistribution" ren "%SystemRoot%\SoftwareDistribution" "SoftwareDistribution.pulsebak" 2>nul
if exist "%SystemRoot%\System32\catroot2" ren "%SystemRoot%\System32\catroot2" "catroot2.pulsebak" 2>nul

netsh winhttp reset proxy >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f 2>nul

net start cryptsvc >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
net start usosvc >nul 2>&1

UsoClient StartScan >nul 2>&1
exit /b

:padrao
:: Reparacao nao altera o padrao PulseOS automaticamente.
exit /b
