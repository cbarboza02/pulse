@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Encerra o processo do OneDrive
taskkill /f /im OneDrive.exe 2>nul
:: Desativa OneDrive via Politica de Grupo (bloqueia sincronizacao e uso)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableLibrariesDefaultSaveToOneDrive" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableOneDriveFileSync" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "PreventNetworkTrafficPreUserSignIn" /t REG_DWORD /d 1 /f
:: Remove OneDrive da inicializacao do Windows (usuario atual)
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f 2>nul
:: Remove OneDrive do painel de navegacao do Explorer
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0 /f
reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0 /f
:: Para e desativa o servico de sincronizacao
sc stop "OneSyncSvc" 2>nul
sc config "OneSyncSvc" start= disabled 2>nul
:: CORRECAO: sc stop com wildcards (OneSyncSvc_*) nao funciona no Windows.
:: O servico OneSyncSvc tem instancias por usuario com sufixo aleatorio.
:: Substituido por PowerShell que localiza e para todas as instancias corretamente.
powershell -NoProfile -Command "Get-Service 'OneSyncSvc_*' -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue"
powershell -NoProfile -Command "Get-Service 'OneSyncSvc_*' -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled -ErrorAction SilentlyContinue"
exit

:revert
:: Reativa as politicas do OneDrive
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableLibrariesDefaultSaveToOneDrive" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableOneDriveFileSync" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "PreventNetworkTrafficPreUserSignIn" /f 2>nul
:: Restaura OneDrive no painel de navegacao do Explorer
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 1 /f
reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 1 /f
:: Reativa servico de sincronizacao
sc config "OneSyncSvc" start= auto 2>nul
sc start "OneSyncSvc" 2>nul
powershell -NoProfile -Command "Get-Service 'OneSyncSvc_*' -ErrorAction SilentlyContinue | Set-Service -StartupType Automatic -ErrorAction SilentlyContinue"
powershell -NoProfile -Command "Get-Service 'OneSyncSvc_*' -ErrorAction SilentlyContinue | Start-Service -ErrorAction SilentlyContinue"
exit
