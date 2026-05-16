@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar suporte a impressao, fax e scanners.

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableHTTPPrinting" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPDownload" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPPrinting" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "RegisterSpoolerRemoteRpcEndPoint" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "RestrictDriverInstallationToAdministrators" /f 2>nul

sc config Spooler start= auto >nul 2>&1
sc config PrintNotify start= demand >nul 2>&1
sc config Fax start= demand >nul 2>&1
sc config stisvc start= demand >nul 2>&1
sc config fdPHost start= demand >nul 2>&1
sc config FDResPub start= demand >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "if(Get-Service -Name 'PrintDeviceConfigurationService' -ErrorAction SilentlyContinue){Set-Service -Name 'PrintDeviceConfigurationService' -StartupType Manual -ErrorAction SilentlyContinue};" ^
  "Start-Service -Name 'Spooler' -ErrorAction SilentlyContinue;" ^
  "Start-Service -Name 'stisvc' -ErrorAction SilentlyContinue"

exit /b

:padrao
:: Reaplicar padrao PulseOS: impressao e scanners desativados.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$svcs=@('Spooler','PrintNotify','Fax','stisvc','PrintDeviceConfigurationService');" ^
  "foreach($s in $svcs){if(Get-Service -Name $s -ErrorAction SilentlyContinue){Stop-Service -Name $s -Force -ErrorAction SilentlyContinue;Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue}}"

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableHTTPPrinting" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPDownload" /t REG_DWORD /d 1 /f

exit /b
