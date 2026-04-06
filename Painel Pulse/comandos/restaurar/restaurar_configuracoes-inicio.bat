@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar Pagina Inicio no app Configuracoes
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /f 2>nul
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /f 2>nul
reg delete "HKU\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /f 2>nul

:: Reinicia o app Configuracoes para aplicar imediatamente
taskkill /F /IM SystemSettings.exe 2>nul
exit /b

:padrao
:: Re-aplicar ocultacao da Pagina Inicio nas Configuracoes

:: HKLM: politica de maquina (afeta todos os usuarios - espelha o script PS1 de maquina)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f

:: HKCU: politica de usuario (afeta o usuario atual)
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f

:: CORRECAO: HKU\.DEFAULT estava no restaurar mas ausente no padrao.
:: Adicionado para garantir que novos usuarios tambem recebam a otimizacao ao fazer logon.
reg add "HKU\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\Settings" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f

:: Reinicia o app Configuracoes para aplicar imediatamente
taskkill /F /IM SystemSettings.exe 2>nul
exit /b
