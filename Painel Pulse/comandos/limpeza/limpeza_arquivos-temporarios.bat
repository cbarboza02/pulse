@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Limpa Arquivos Temporários do Sistema, Navegadores, Usuário e Aplicativos

:: --- Sistema ---
del /f /s /q "%SystemRoot%\Temp\*" >nul 2>&1
rd /s /q "%SystemRoot%\Temp" >nul 2>&1
md "%SystemRoot%\Temp" >nul 2>&1

del /f /s /q "%TEMP%\*" >nul 2>&1
rd /s /q "%TEMP%" >nul 2>&1
md "%TEMP%" >nul 2>&1

del /f /s /q "%LOCALAPPDATA%\Temp\*" >nul 2>&1
rd /s /q "%LOCALAPPDATA%\Temp" >nul 2>&1
md "%LOCALAPPDATA%\Temp" >nul 2>&1

:: --- Navegadores ---
:: Google Chrome
del /f /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache\*" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache\*" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\GPUCache\*" >nul 2>&1

:: Microsoft Edge
del /f /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache\*" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Code Cache\*" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\GPUCache\*" >nul 2>&1

:: Mozilla Firefox
:: CORRECAO: del nao suporta wildcards no meio de um caminho (ex: Profiles\*\cache2).
:: Substituido por loop for /d que percorre cada pasta de perfil individualmente.
for /d %%p in ("%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*") do (
    del /f /s /q "%%p\cache2\*" >nul 2>&1
)
for /d %%p in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do (
    del /f /s /q "%%p\cache2\*" >nul 2>&1
)

:: Opera
del /f /s /q "%APPDATA%\Opera Software\Opera Stable\Cache\*" >nul 2>&1

:: Brave
del /f /s /q "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cache\*" >nul 2>&1

:: --- Aplicativos ---
:: Discord
del /f /s /q "%APPDATA%\discord\Cache\*" >nul 2>&1
del /f /s /q "%APPDATA%\discord\Code Cache\*" >nul 2>&1
del /f /s /q "%APPDATA%\discord\GPUCache\*" >nul 2>&1

:: Spotify
del /f /s /q "%LOCALAPPDATA%\Spotify\Storage\*" >nul 2>&1

:: Steam (cache de download, nao dados de jogo)
del /f /s /q "%LOCALAPPDATA%\Steam\htmlcache\*" >nul 2>&1

:: Teams
del /f /s /q "%APPDATA%\Microsoft\Teams\Service Worker\CacheStorage\*" >nul 2>&1
del /f /s /q "%APPDATA%\Microsoft\Teams\Cache\*" >nul 2>&1

:: Arquivos temporarios de instalacoes
del /f /s /q "%SystemRoot%\Downloaded Installations\*" >nul 2>&1

:: Limpeza via Cleanmgr silenciosa
:: NOTA: cleanmgr /sagerun:1 requer configuracao previa via /sageset:1.
:: Se nunca configurado, nao executa itens de limpeza adicionais.
cleanmgr /sagerun:1 >nul 2>&1
exit

:revert
:: Arquivos temporarios nao podem ser restaurados (operacao irreversivel por definicao)
exit
