@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply

taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul

del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1

:: Posiciona os icones da Barra de Tarefas a esquerda
:: TaskbarAl = 0 (esquerda) | 1 = centro (padrao Windows 11)
:: No Windows 10 os icones ja ficam a esquerda por padrao
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f

start explorer.exe
exit

:revert

taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul

del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1

:: Restaura os icones da Barra de Tarefas ao centro (padrao do Windows 11)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 1 /f

start explorer.exe
exit
