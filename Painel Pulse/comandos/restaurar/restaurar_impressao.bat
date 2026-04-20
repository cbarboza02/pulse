@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar servicos de Impressao ao padrao do Windows 11

:: Remove politicas que desabilitam impressao via HTTP e Web
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableHTTPPrinting"   /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPDownload" /f 2>nul

:: Reativa o Print Spooler (servico principal - deve ser o primeiro)
sc config Spooler start= auto   >nul 2>&1
sc start  Spooler               >nul 2>&1

:: Reativa servicos de suporte (dependem do Spooler)
sc config PrintNotify start= demand >nul 2>&1
sc start  PrintNotify               >nul 2>&1

:: Fax e adquicao de imagem (scanners): definidos como Manual (padrao Windows)
sc config Fax    start= demand >nul 2>&1
sc config stisvc start= demand >nul 2>&1

:: Servico de configuracao de dispositivo de impressao (Manual por padrao)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "if (Get-Service -Name 'PrintDeviceConfigurationService' -ErrorAction SilentlyContinue) {" ^
  "  Set-Service -Name 'PrintDeviceConfigurationService' -StartupType Manual -ErrorAction SilentlyContinue" ^
  "}"
exit /b

:padrao
:: Re-aplicar desativacao dos servicos de Impressao
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Stop-Service -Name 'Spooler'    -Force -EA SilentlyContinue; Set-Service -Name 'Spooler'    -StartupType Disabled -EA SilentlyContinue;" ^
  "Stop-Service -Name 'PrintNotify' -Force -EA SilentlyContinue; Set-Service -Name 'PrintNotify' -StartupType Disabled -EA SilentlyContinue;" ^
  "Stop-Service -Name 'Fax'        -Force -EA SilentlyContinue; Set-Service -Name 'Fax'        -StartupType Disabled -EA SilentlyContinue;" ^
  "Stop-Service -Name 'stisvc'     -Force -EA SilentlyContinue; Set-Service -Name 'stisvc'     -StartupType Disabled -EA SilentlyContinue;" ^
  "if (Get-Service -Name 'PrintDeviceConfigurationService' -EA SilentlyContinue) {" ^
  "  Stop-Service -Name 'PrintDeviceConfigurationService' -Force -EA SilentlyContinue;" ^
  "  Set-Service  -Name 'PrintDeviceConfigurationService' -StartupType Disabled -EA SilentlyContinue" ^
  "}"

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableHTTPPrinting"   /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPDownload" /t REG_DWORD /d 1 /f
exit /b
