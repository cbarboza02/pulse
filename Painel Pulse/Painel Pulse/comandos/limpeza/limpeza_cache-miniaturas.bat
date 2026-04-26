@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Limpa Cache de Miniaturas, Icones e Fontes

taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul

:: --- Cache de Miniaturas e Icones ---
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1

:: Remove IconCache.db (pode ter atributo oculto)
attrib -h "%LOCALAPPDATA%\IconCache.db" >nul 2>&1
del /f /q "%LOCALAPPDATA%\IconCache.db" >nul 2>&1

:: Notifica o sistema para reconstruir o cache de icones
:: CORRECAO: "-show" nao e o flag de limpeza de icones.
:: O correto e "-ClearIconCache" (Windows 7-10) ou simplesmente reiniciar o Explorer,
:: que ja reconstroi o cache automaticamente ao ser iniciado.
ie4uinit.exe -ClearIconCache >nul 2>&1

:: --- Cache de Fontes ---
:: Para o servico de cache de fontes
net stop "FontCache" /y >nul 2>&1
net stop "FontCache3.0.0.0" /y >nul 2>&1

del /f /s /q "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*" >nul 2>&1
del /f /s /q "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache3.0.0.0\*" >nul 2>&1

:: Reinicia os servicos de fonte
:: CORRECAO: FontCache3.0.0.0 era parado mas nunca reiniciado — corrigido
net start "FontCache" >nul 2>&1
net start "FontCache3.0.0.0" >nul 2>&1

:: Reinicia o Explorer (reconstruira o cache de icones e miniaturas automaticamente)
start explorer.exe
exit

:revert
:: Cache de miniaturas, icones e fontes sao regenerados automaticamente pelo sistema
exit
