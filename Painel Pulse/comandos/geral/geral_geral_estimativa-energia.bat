@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa estimativa de carga de energia do sistema (Energy Estimation Engine)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EEEnabled" /t REG_DWORD /d 0 /f
:: Para e desativa o Sensor Monitoring Service (coleta dados de energia do hardware)
sc stop "SensrSvc" 2>nul
sc config "SensrSvc" start= disabled 2>nul
:: REMOVIDO: sc stop "EFS" - EFS e o servico de Criptografia de Sistema de Arquivos (Encrypting
:: File System), completamente sem relacao com energia. Parar esse servico pode bloquear acesso
:: a arquivos criptografados com EFS, causando perda de dados ou falhas no sistema.
exit

:revert
:: Reativa estimativa de energia
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EEEnabled" /t REG_DWORD /d 1 /f
sc config "SensrSvc" start= auto 2>nul
sc start "SensrSvc" 2>nul
exit
