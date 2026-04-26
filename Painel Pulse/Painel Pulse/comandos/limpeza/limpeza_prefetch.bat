@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Limpa Prefetch e Superfetch (SysMain)

:: Salva o estado atual do SysMain antes de para-lo
:: CORRECAO: A versao original sempre chamava "net start SysMain" no final,
:: o que reiniciaria o servico mesmo que ele estivesse DESABILITADO pelo usuario
:: (ex: via geral_geral_prefetch-superfetch.bat). Agora o servico so e reiniciado
:: se estava em execucao antes da limpeza.
sc query SysMain | findstr /i "RUNNING" >nul 2>&1
set "SYSMAIN_WAS_RUNNING=%errorlevel%"

net stop SysMain /y >nul 2>&1

:: --- Limpa os arquivos Prefetch ---
del /f /s /q "%SystemRoot%\Prefetch\*.pf" >nul 2>&1
del /f /s /q "%SystemRoot%\Prefetch\ReadyBoot\*" >nul 2>&1
del /f /s /q "%SystemRoot%\Prefetch\ag*.db" >nul 2>&1
del /f /s /q "%SystemRoot%\Prefetch\*.db" >nul 2>&1
del /f /q "%SystemRoot%\Prefetch\Layout.ini" >nul 2>&1
del /f /s /q "%SystemRoot%\System32\config\systemprofile\AppData\Local\Microsoft\Windows\Caches\*" >nul 2>&1

:: Reinicia o SysMain apenas se estava em execucao antes da limpeza
if "%SYSMAIN_WAS_RUNNING%"=="0" (
    net start SysMain >nul 2>&1
)
exit

:revert
:: Prefetch e Superfetch sao regenerados automaticamente pelo Windows conforme o uso
exit
