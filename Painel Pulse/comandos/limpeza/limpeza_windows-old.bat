@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Limpa Instalacoes Anteriores do Windows (pasta Windows.old)

:: Verifica se a pasta Windows.old existe antes de prosseguir
if not exist "%SystemDrive%\Windows.old" (
    exit
)

:: Configura o limpador de disco para remover instalacoes anteriores
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations" /v "StateFlags0098" /t REG_DWORD /d 2 /f >nul 2>&1

:: Executa limpeza via Disk Cleanup
cleanmgr /sagerun:98 >nul 2>&1

:: Limpeza via DISM (fallback caso cleanmgr nao remova tudo)
:: CORRECAO: Removido /ResetBase que foi adicionado na versao original.
:: /ResetBase e uma operacao PERMANENTE E IRREVERSIVEL que remove todas as versoes
:: anteriores de componentes do Windows, tornando impossivel reverter atualizacoes
:: futuras e desinstalar hotfixes. Nao deve ser executado em uma limpeza de rotina.
:: StartComponentCleanup sem /ResetBase ja remove componentes obsoletos com seguranca.
dism /Online /Cleanup-Image /StartComponentCleanup >nul 2>&1

:: Forca a remocao manual da pasta residual (caso cleanmgr/dism nao tenham removido)
takeown /f "%SystemDrive%\Windows.old" /r /d y >nul 2>&1
icacls "%SystemDrive%\Windows.old" /grant administrators:F /t /q >nul 2>&1
rd /s /q "%SystemDrive%\Windows.old" >nul 2>&1
exit

:revert
:: A pasta Windows.old nao pode ser restaurada apos remocao
exit
