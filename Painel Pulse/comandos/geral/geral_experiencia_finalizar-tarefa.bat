@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Ativa a opcao 'Finalizar Tarefa' ao clicar com o botao direito em um app na Barra de Tarefas
:: Disponivel a partir do Windows 11 build 22621.2361 (23H2)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" /v TaskbarEndTask /t REG_DWORD /d 1 /f
exit

:revert
:: Desativa a opcao 'Finalizar Tarefa' na Barra de Tarefas
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" /v TaskbarEndTask /t REG_DWORD /d 0 /f
exit
