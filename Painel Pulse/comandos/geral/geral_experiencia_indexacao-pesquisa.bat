@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit /b

:apply
:: Desativa somente a indexacao local da Pesquisa do Windows.
sc stop WSearch >nul 2>&1
sc config WSearch start= disabled >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Shell\IndexerAutomaticMaintenance" /Disable >nul 2>&1
exit /b

:revert
:: O PulseOS nao desativa a indexacao local por padrao; volta ao comportamento funcional do Windows.
sc config WSearch start= delayed-auto >nul 2>&1
sc start WSearch >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Shell\IndexerAutomaticMaintenance" /Enable >nul 2>&1
exit /b
