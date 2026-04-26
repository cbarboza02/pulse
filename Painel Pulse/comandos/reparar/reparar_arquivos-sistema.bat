@echo off
if /i "%~1"=="reparar" goto reparar
if /i "%~1"=="padrao" goto padrao
exit /b

:reparar
:: Reparar arquivos do sistema com DISM e SFC.
:: Pode demorar bastante.

DISM /Online /Cleanup-Image /RestoreHealth
sfc /scannow
exit /b

:padrao
:: Reparacao nao altera o padrao PulseOS automaticamente.
exit /b
