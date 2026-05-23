@echo off
setlocal EnableExtensions
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b 1
:restaurar
:: Restaurar som de inicializacao do Windows.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" /v "DisableStartupSound" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\AppEvents\EventLabels\WindowsLogon" /v "ExcludeFromCPL" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\AppEvents\Schemes\Apps\.Default\WindowsLogon\.Current" /ve /t REG_SZ /d "C:\Windows\Media\Windows Logon.wav" /f >nul 2>&1
exit /b 0
:padrao
:: Reaplicar padrao PulseOS: som de inicializacao desativado.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" /v "DisableStartupSound" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\AppEvents\EventLabels\WindowsLogon" /v "ExcludeFromCPL" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\AppEvents\Schemes\Apps\.Default\WindowsLogon\.Current" /ve /t REG_SZ /d "" /f >nul 2>&1
exit /b 0
