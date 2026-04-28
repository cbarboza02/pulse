@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar a pagina "Inicio" no app Configuracoes.

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /f 2>nul
reg delete "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /f 2>nul

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /f 2>nul
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /f 2>nul
reg delete "HKU\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /f 2>nul

taskkill /F /IM SystemSettings.exe 2>nul
exit /b

:padrao
:: Reaplicar padrao PulseOS: ocultar a pagina "Inicio" de Configuracoes.

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f
reg add "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f
reg add "HKU\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f

taskkill /F /IM SystemSettings.exe 2>nul
exit /b
