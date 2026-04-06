@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar Widgets ao padrao do Windows 11

:: Remove politicas de bloqueio dos Widgets
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /f 2>nul

:: CORRECAO CRITICA: O restaurar original usava o caminho errado:
::   reg delete "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests" /v "AllowNewsAndInterests"
:: O caminho correto (espelhando o que o script PS1 e o padrao definem) e:
::   "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value"
reg delete "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /f 2>nul

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"                     /v "EnableFeeds"        /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"           /v "HideTaskbarFeeds"   /f 2>nul

:: Restaura o botao de Widgets na barra de tarefas
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 1 /f

:: Remove configuracoes de usuario dos Widgets
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode"   /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarOpenOnHover" /f 2>nul

taskkill /F /IM explorer.exe 2>nul
start explorer.exe
exit /b

:padrao
:: Re-aplicar desativacao dos Widgets

reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"               /v "EnableFeeds"      /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"     /v "HideTaskbarFeeds" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"     /v "TaskbarDa"        /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds"                 /v "ShellFeedsTaskbarViewMode"    /t REG_DWORD /d 2 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds"                 /v "ShellFeedsTaskbarOpenOnHover" /t REG_DWORD /d 0 /f

taskkill /F /IM explorer.exe 2>nul
start explorer.exe
exit /b
