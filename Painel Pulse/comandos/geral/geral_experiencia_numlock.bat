@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Ativa NumLock para o usuario atual apos o login
reg add "HKCU\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f

:: Ativa NumLock na tela de login via Winlogon
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f

:: Ativa NumLock no perfil DEFAULT (usado pela tela de login antes de qualquer usuario autenticar)
:: Este e o metodo mais compativel para ativar NumLock na tela de logon
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f

:: Aplica tambem para novos usuarios via hive padrao
reg load "HKLM\TempHive" "%SystemDrive%\Users\Default\NTUSER.DAT" >nul 2>&1
reg add "HKLM\TempHive\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f >nul 2>&1
reg unload "HKLM\TempHive" >nul 2>&1
exit

:revert
:: Restaura NumLock para usar o estado do hardware/BIOS (padrao real do Windows = 2147483648)
:: Definir "0" forcaria desligado explicitamente; o padrao correto e deixar o hardware decidir
reg add "HKCU\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2147483648" /f

:: Remove o override do Winlogon (era ele que forcava NumLock ligado mesmo apos o revert)
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "InitialKeyboardIndicators" /f >nul 2>&1

:: Restaura o perfil DEFAULT para o padrao do Windows
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2147483648" /f

:: Reverte para novos usuarios via hive padrao
reg load "HKLM\TempHive" "%SystemDrive%\Users\Default\NTUSER.DAT" >nul 2>&1
reg add "HKLM\TempHive\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2147483648" /f >nul 2>&1
reg unload "HKLM\TempHive" >nul 2>&1
exit
