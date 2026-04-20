@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Limpa Cache do Windows Update e Otimização de Entrega

:: Para os serviços relacionados para liberar os arquivos
net stop wuauserv /y >nul 2>&1
net stop bits /y >nul 2>&1
net stop dosvc /y >nul 2>&1
net stop cryptsvc /y >nul 2>&1

:: --- Cache do Windows Update ---
del /f /s /q "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
rd /s /q "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
md "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1

del /f /s /q "%SystemRoot%\SoftwareDistribution\DataStore\Logs\*" >nul 2>&1

:: Limpa cache de catálogo de componentes
del /f /s /q "%SystemRoot%\SoftwareDistribution\PostRebootEventCache\*" >nul 2>&1

:: --- Cache de Otimização de Entrega ---
del /f /s /q "%SystemRoot%\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\*" >nul 2>&1
rd /s /q "%SystemRoot%\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization" >nul 2>&1

del /f /s /q "%SystemDrive%\Windows\SoftwareDistribution\DeliveryOptimization\*" >nul 2>&1

:: Reinicia os serviços
net start cryptsvc >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
net start dosvc >nul 2>&1

exit

:revert
:: O cache do Windows Update é regenerado automaticamente na próxima execução do serviço
:: Nenhuma ação de reversão necessária
exit
