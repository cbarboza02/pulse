@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Aumenta o tempo que o SCM aguarda um servico conectar ao pipe apos ser iniciado
:: Valor padrao: 30000 ms (30 segundos) - Valor otimizado: 60000 ms (60 segundos)
:: Evita falhas prematuras de servicos lentos para iniciar e reduz erros de timeout no boot
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "ServicesPipeTimeout" /t REG_DWORD /d 60000 /f
exit

:revert
:: Restaura o timeout padrao do Windows (remove o override, padrao = 30000 ms)
reg delete "HKLM\SYSTEM\CurrentControlSet\Control" /v "ServicesPipeTimeout" /f 2>nul
exit
