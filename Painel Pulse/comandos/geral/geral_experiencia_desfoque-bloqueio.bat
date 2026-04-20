@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o efeito de desfoque Acrylic na tela de bloqueio e login
:: DisableAcrylicBackgroundOnLogon e a chave especifica para a tela de bloqueio/logon
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DisableAcrylicBackgroundOnLogon" /t REG_DWORD /d 1 /f
:: REMOVIDO: EnableTransparency = 0 desativa a transparencia de TODA a interface do Windows
:: (barra de tarefas, menu Iniciar, etc.), nao apenas da tela de bloqueio.
:: Isso ultrapassa o escopo desta otimizacao. Se desejado, deve ser um arquivo separado.
exit

:revert
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DisableAcrylicBackgroundOnLogon" /f 2>nul
exit
