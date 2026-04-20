@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar Pagina Inicio e Acesso Rapido no Explorador de Arquivos

:: Restaura exibicao de recentes e frequentes no Quick Access
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent"   /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 1 /f

:: Restaura o pin de Bibliotecas no painel de navegacao do Explorer
reg add "HKCU\SOFTWARE\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 1 /f

:: Equivalentes para o perfil DEFAULT (novos usuarios)
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent"   /t REG_DWORD /d 1 /f
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 1 /f
reg add "HKU\.DEFAULT\Software\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 1 /f

:: Restaura a secao Recomendados no Menu Iniciar
:: CORRECAO: O script PS1 desativa HideRecommendedSection e HideRecentlyAddedApps,
:: mas o restaurar original so removia HideRecentlyAddedApps. Adicionados ambos.
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps"  /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /f 2>nul
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps"  /f 2>nul
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /f 2>nul

:: Restaura recomendacoes do Iris (sugestoes personalizadas no Start)
:: CORRECAO: O script PS1 desativa Start_IrisRecommendations e ShowRecentList,
:: mas esses nao eram restaurados. Adicionados.
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" /v "ShowRecentList" /f 2>nul
reg delete "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /f 2>nul
reg delete "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Start" /v "ShowRecentList" /f 2>nul

taskkill /F /IM explorer.exe 2>nul
start explorer.exe
exit /b

:padrao
:: Re-aplicar desativacao do Acesso Rapido, Historico e Secao Recomendados

reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent"   /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0 /f

reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent"   /t REG_DWORD /d 0 /f
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 0 /f
reg add "HKU\.DEFAULT\Software\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0 /f

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps"  /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d 1 /f

reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Start"              /v "ShowRecentList"            /t REG_DWORD /d 0 /f
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d 0 /f
reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Start"             /v "ShowRecentList"            /t REG_DWORD /d 0 /f

taskkill /F /IM explorer.exe 2>nul
start explorer.exe
exit /b
