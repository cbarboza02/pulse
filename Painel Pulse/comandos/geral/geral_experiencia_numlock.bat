@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Ativa NumLock para o usuario atual apos o login
reg add "HKCU\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f
:: Ativa NumLock na tela de login via Winlogon
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f
:: Ativa NumLock no perfil DEFAULT
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f
:: Aplica para novos usuarios via hive padrao
reg load "HKLM\TempHive" "%SystemDrive%\Users\Default\NTUSER.DAT" >nul 2>&1
reg add "HKLM\TempHive\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f >nul 2>&1
reg unload "HKLM\TempHive" >nul 2>&1
exit

:revert
reg add "HKCU\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2147483648" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "InitialKeyboardIndicators" /f >nul 2>&1
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2147483648" /f
reg load "HKLM\TempHive" "%SystemDrive%\Users\Default\NTUSER.DAT" >nul 2>&1
reg add "HKLM\TempHive\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2147483648" /f >nul 2>&1
reg unload "HKLM\TempHive" >nul 2>&1
exit
