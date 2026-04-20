@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Adiciona 'Copiar para pasta...' ao menu de contexto de arquivos e pastas
reg add "HKLM\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\Copy To" /ve /t REG_SZ /d "{C2FBB630-2971-11D1-A18C-00C04FD75D13}" /f
:: Adiciona 'Mover para pasta...' ao menu de contexto de arquivos e pastas
reg add "HKLM\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\Move To" /ve /t REG_SZ /d "{C2FBB631-2971-11D1-A18C-00C04FD75D13}" /f
exit

:revert
:: Remove 'Copiar para pasta...' do menu de contexto
reg delete "HKLM\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\Copy To" /f >nul 2>&1
:: Remove 'Mover para pasta...' do menu de contexto
reg delete "HKLM\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\Move To" /f >nul 2>&1
exit
