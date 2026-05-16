@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o Modern Standby (S0 Low Power Idle), forcando modo S3 classico
:: Elimina processos em segundo plano que continuam ativos durante o standby moderno
:: Requer reinicializacao para ter efeito completo
reg add "HKLM\System\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /t REG_DWORD /d 0 /f
:: Forca desconexao de rede durante o standby (1 = enforcar standby desconectado)
:: Valor 0 significa "nao enforcar" = permite conectividade, o que e o oposto do desejado
reg add "HKLM\System\CurrentControlSet\Control\Power" /v EnforceDisconnectedStandby /t REG_DWORD /d 1 /f
exit

:revert
:: Restaura o Modern Standby ao comportamento padrao do sistema
:: Requer reinicializacao para ter efeito completo
reg delete "HKLM\System\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /f 2>nul
reg delete "HKLM\System\CurrentControlSet\Control\Power" /v EnforceDisconnectedStandby /f 2>nul
exit
