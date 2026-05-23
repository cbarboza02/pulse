@echo off
setlocal EnableExtensions
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b 1
:restaurar
:: Restaurar pagina Inicio no app Configuracoes.
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /f >nul 2>&1
reg delete "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /f >nul 2>&1
reg delete "HKU\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /f >nul 2>&1
taskkill /F /IM SystemSettings.exe >nul 2>&1
exit /b 0
:padrao
:: Reaplicar padrao PulseOS: pagina Inicio ocultada.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f >nul 2>&1
reg add "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f >nul 2>&1
reg add "HKU\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f >nul 2>&1
taskkill /F /IM SystemSettings.exe >nul 2>&1
exit /b 0
