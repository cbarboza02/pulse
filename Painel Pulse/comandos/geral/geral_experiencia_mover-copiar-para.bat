@echo off
if /i "%~1"=="apply" goto pulseos
if /i "%~1"=="revert" goto pulseos
exit /b

:pulseos
:: Reaplica o padrao PulseOS: exibe as opcoes "Copiar para" e "Mover para" no menu de contexto.
reg add "HKLM\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\Copy To" /ve /t REG_SZ /d "{C2FBB630-2971-11D1-A18C-00C04FD75D13}" /f
reg add "HKLM\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\Move To" /ve /t REG_SZ /d "{C2FBB631-2971-11D1-A18C-00C04FD75D13}" /f
exit /b
