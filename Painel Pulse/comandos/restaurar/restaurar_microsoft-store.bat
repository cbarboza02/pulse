@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar/Corrigir Microsoft Store
:: As otimizacoes desabilitam a atualizacao automatica e algumas politicas de conteudo
:: que podem impedir o funcionamento correto da Store.

:: --- 1. Remove politicas que bloqueiam ou limitam a Store ---
:: Remove bloqueio de auto-download de atualizacoes de apps
reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "AutoDownload"      /f 2>nul
reg delete "HKCU\SOFTWARE\Policies\Microsoft\WindowsStore" /v "AutoDownload"      /f 2>nul
:: Remove bloqueio de abertura de apps desconhecidos via Store
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /f 2>nul
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /f 2>nul
:: Remove restricao de instalacao silenciosa de apps
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 1 /f

:: --- 2. Garante servicos necessarios para o funcionamento da Store ---
:: AppXSvc: implantacao de pacotes AppX/MSIX (necessario para instalar apps)
sc config AppXSvc start= demand >nul 2>&1
sc start  AppXSvc              >nul 2>&1

:: ClipSVC: servico de licenciamento de apps da Store
sc config ClipSVC start= demand >nul 2>&1
sc start  ClipSVC              >nul 2>&1

:: LicenseManager: gerencia licencas do Windows e apps da Store
sc config LicenseManager start= demand >nul 2>&1
sc start  LicenseManager              >nul 2>&1

:: wlidsvc: autenticacao com conta Microsoft (login na Store)
sc config wlidsvc start= demand >nul 2>&1
sc start  wlidsvc              >nul 2>&1

:: TokenBroker: broker de tokens OAuth para apps (necessario para login)
sc config TokenBroker start= demand >nul 2>&1

:: --- 3. Garante que o servico de atualizacao do Windows esteja ativo ---
:: A Store depende do Windows Update para baixar e instalar apps
sc config wuauserv start= demand >nul 2>&1
sc start  wuauserv              >nul 2>&1

:: --- 4. Limpa e reseta o cache da Store ---
:: wsreset.exe limpa o cache e reinicia a Store automaticamente
:: Aguarda 3s para os servicos subirem antes de resetar
timeout /t 3 /nobreak >nul
wsreset.exe >nul 2>&1

:: --- 5. Re-registra o app da Store para o usuario atual (corrige apps corrompidos) ---
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try {" ^
  "  Get-AppxPackage -AllUsers 'Microsoft.WindowsStore' -ErrorAction Stop |" ^
  "  ForEach-Object { Add-AppxPackage -DisableDevelopmentMode -Register \"$($_.InstallLocation)\AppXManifest.xml\" -ErrorAction SilentlyContinue };" ^
  "  Get-AppxPackage 'Microsoft.StorePurchaseApp' -ErrorAction SilentlyContinue |" ^
  "  ForEach-Object { Add-AppxPackage -DisableDevelopmentMode -Register \"$($_.InstallLocation)\AppXManifest.xml\" -ErrorAction SilentlyContinue }" ^
  "} catch { Write-Host 'Re-registro da Store: ' $_.Message }"

echo [OK] Microsoft Store restaurada. Aguarde o wsreset concluir. Se o problema persistir, tente reiniciar o sistema.
exit /b

:padrao
:: Re-aplicar as configuracoes de Store que as otimizacoes definem

:: Desativa auto-download de atualizacoes de apps (conforme PS1 de maquina e usuario)
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t REG_DWORD /d 2 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t REG_DWORD /d 2 /f

:: Desativa abertura de apps desconhecidos via Store
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d 1 /f

:: Desativa instalacao silenciosa de apps sugeridos
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f

:: Servicos retornam ao modo Manual (sao iniciados sob demanda pela propria Store)
sc config AppXSvc        start= demand >nul 2>&1
sc config ClipSVC        start= demand >nul 2>&1
sc config LicenseManager start= demand >nul 2>&1
sc config wlidsvc        start= demand >nul 2>&1
exit /b
