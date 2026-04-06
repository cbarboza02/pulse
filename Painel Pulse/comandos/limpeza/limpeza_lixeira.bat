@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Esvazia a Lixeira de todas as unidades de disco

:: Esvazia via PowerShell (metodo mais confiavel e abrangente)
:: Clear-RecycleBin opera em todos os drives e lida com permissoes corretamente
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"

:: CORRECAO: Removido o bloco que usava rd /s /q na pasta $Recycle.Bin.
:: Deletar a pasta inteira remove as subpastas de TODOS os usuarios do sistema,
:: nao apenas do usuario atual, e requer permissoes elevadas especiais.
:: Alem disso, o comando wmic para enumerar discos e deprecado no Windows 11.
:: O PowerShell Clear-RecycleBin e o metodo correto e suficiente.
exit

:revert
:: A lixeira esvaziada nao pode ser restaurada
exit
