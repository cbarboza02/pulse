@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Para o servico SysMain (Superfetch) imediatamente
:: CORRECAO: adicionados >nul 2>&1 em todos os sc commands (imprimiam no console)
sc stop SysMain >nul 2>&1
:: Desativa o servico SysMain (Superfetch) para nao iniciar com o Windows
sc config SysMain start= disabled >nul 2>&1
:: Desativa Prefetch (0 = desativado)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 0 /f
:: Desativa Superfetch via registro (0 = desativado)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 0 /f
:: Desativa rastreamento de boot para Prefetch
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableBootTrace" /t REG_DWORD /d 0 /f
exit

:revert
:: Reativa o servico SysMain (Superfetch)
sc config SysMain start= auto >nul 2>&1
sc start SysMain >nul 2>&1
:: Restaura Prefetch (3 = ativar prefetch de aplicativos e boot)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 3 /f
:: Restaura Superfetch (3 = ativar)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 3 /f
:: EnableBootTrace padrao = 0 (nunca muda por atualizacoes)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableBootTrace" /t REG_DWORD /d 0 /f
exit
