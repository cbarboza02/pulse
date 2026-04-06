@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply

taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul

del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1

:: Restaura o menu de contexto classico do Windows 10 (remove o menu moderno do Windows 11)
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve

:: Reinicia o Explorer para aplicar imediatamente
start explorer.exe
exit

:revert

taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul

del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1

:: Remove a chave do menu classico, restaurando o menu moderno do Windows 11
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1

:: Reinicia o Explorer para aplicar imediatamente
start explorer.exe
exit
