@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar Som de Inicializacao do Windows 11
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" /v "DisableStartupSound" /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "EnableSIHostIntegration" /t REG_DWORD /d 1 /f
reg add "HKCU\AppEvents\Schemes\Apps\.Default\SystemStart\.Current" /ve /t REG_SZ /d "%SystemRoot%\Media\Windows Startup.wav" /f
exit /b

:padrao
:: Re-aplicar desativacao do Som de Inicializacao
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" /v "DisableStartupSound" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "EnableSIHostIntegration" /t REG_DWORD /d 0 /f
reg add "HKCU\AppEvents\Schemes\Apps\.Default\SystemStart\.Current" /ve /t REG_SZ /d "" /f
exit /b
