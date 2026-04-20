@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Encerra processos do Chat / Teams
taskkill /f /im "Teams.exe" 2>nul
taskkill /f /im "ms-teams.exe" 2>nul
:: Remove o botao de Chat da barra de tarefas (TaskbarMn = 0 oculta)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 0 /f
:: Desativa Chat via Politica de Grupo
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v "ChatIcon" /t REG_DWORD /d 3 /f
:: Remove Teams da inicializacao automatica do Windows
:: CORRECAO: a versao original adicionava a chave com valor vazio e depois a deletava,
:: o que e contraditorio. A intencao e apenas remover a entrada de autostart.
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "com.squirrel.Teams.Teams" /f 2>nul
exit

:revert
:: Restaura o botao de Chat na barra de tarefas
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 1 /f
:: Remove a politica de Chat
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v "ChatIcon" /f 2>nul
exit
