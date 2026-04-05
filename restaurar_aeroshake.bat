@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar AeroShake ao padrao do Windows 11
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoWindowMinimizingShortcuts" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisallowShaking" /f 2>nul
reg delete "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisallowShaking" /f 2>nul
taskkill /F /IM explorer.exe 2>nul
start explorer.exe
exit /b

:padrao
:: Re-aplicar desativacao do AeroShake
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoWindowMinimizingShortcuts" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisallowShaking" /t REG_DWORD /d 1 /f
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisallowShaking" /t REG_DWORD /d 1 /f
taskkill /F /IM explorer.exe 2>nul
start explorer.exe
exit /b
