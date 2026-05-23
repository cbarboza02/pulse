@echo off
setlocal EnableExtensions
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b 1
:restaurar
:: Restaurar impressao e scanner basicos.
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableHTTPPrinting" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPDownload" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPPrinting" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "RegisterSpoolerRemoteRpcEndPoint" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "RestrictDriverInstallationToAdministrators" /f >nul 2>&1
sc config Spooler start= auto >nul 2>&1
sc config PrintNotify start= demand >nul 2>&1
sc config Fax start= demand >nul 2>&1
sc config stisvc start= demand >nul 2>&1
sc config fdPHost start= demand >nul 2>&1
sc config FDResPub start= demand >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach($s in @('PrintScanBrokerService','PrintWorkflowUserSvc','PrintDeviceConfigurationService')){if(Get-Service -Name $s -ErrorAction SilentlyContinue){Set-Service -Name $s -StartupType Manual -ErrorAction SilentlyContinue}};Start-Service -Name 'Spooler' -ErrorAction SilentlyContinue;Start-Service -Name 'stisvc' -ErrorAction SilentlyContinue" >nul 2>&1
exit /b 0
:padrao
:: Reaplicar padrao PulseOS: impressao e scanner desativados.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$svcs=@('Spooler','PrintNotify','Fax','stisvc','PrintScanBrokerService','PrintWorkflowUserSvc','PrintDeviceConfigurationService');foreach($s in $svcs){if(Get-Service -Name $s -ErrorAction SilentlyContinue){Stop-Service -Name $s -Force -ErrorAction SilentlyContinue;Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue}}" >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableHTTPPrinting" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPDownload" /t REG_DWORD /d 1 /f >nul 2>&1
exit /b 0
