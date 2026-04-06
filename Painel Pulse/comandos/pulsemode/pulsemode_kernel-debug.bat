@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa a depuracao do kernel via bcdedit
bcdedit /debug off >nul 2>&1
bcdedit /bootdebug off >nul 2>&1
bcdedit /set {current} debug off >nul 2>&1
bcdedit /set {default} debug off >nul 2>&1
bcdedit /set {default} bootdebug off >nul 2>&1
:: Remove flag de politica de menu de boot (retorna ao padrao standard)
bcdedit /deletevalue {current} bootmenupolicy >nul 2>&1
:: Desativa o servico de kernel debug network adapter
sc config kdnic start= disabled >nul 2>&1
:: Remove filtro de impressao de debug do kernel (evita overhead de log)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Debug Print Filter" /v "DEFAULT" /t REG_DWORD /d 0 /f >nul 2>&1
exit

:revert
:: Debug off ja e o padrao do Windows - garante estado correto
bcdedit /debug off >nul 2>&1
bcdedit /bootdebug off >nul 2>&1
:: Restaura o servico kdnic ao padrao (demand)
sc config kdnic start= demand >nul 2>&1
:: Restaura o filtro de debug do kernel ao padrao
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Debug Print Filter" /v "DEFAULT" /f >nul 2>&1
exit
