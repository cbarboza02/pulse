@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Mantem o executivo do kernel e drivers carregados sempre na RAM
:: Impede que o sistema pagine codigo do kernel para o disco (arquivo de paginacao)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f
exit

:revert
:: Restaura o comportamento padrao: executivo do kernel pode ser paginado para o disco
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 0 /f
exit
