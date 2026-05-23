@echo off
setlocal EnableExtensions
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b 1
:restaurar
:: Restaurar Inicio, Acesso Rapido, recentes e frequentes.
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\.DEFAULT\Software\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKU\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKU\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" /v "ShowRecentList" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Start" /v "ShowRecentList" /t REG_DWORD /d 1 /f >nul 2>&1
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe
exit /b 0
:padrao
:: Reaplicar padrao PulseOS: Inicio, recentes e recomendados ativos.
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\.DEFAULT\Software\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKU\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKU\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" /v "ShowRecentList" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Start" /v "ShowRecentList" /t REG_DWORD /d 1 /f >nul 2>&1
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe
exit /b 0
