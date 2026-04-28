@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa mitigacoes de Spectre (Variant 1, 2) e Meltdown (Variant 3)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d 3 /f >nul 2>&1
:: Desativa realocacao forcada de imagens nao-ASLR (Mandatory ASLR / Bottom-up ASLR)
:: CORRECAO DE COMENTARIO: MoveImages controla ASLR de imagens, nao Retpoline/IBRS
:: Retpoline e IBRS sao controlados pelos bits de FeatureSettingsOverride acima
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "MoveImages" /t REG_DWORD /d 0 /f >nul 2>&1
exit

:revert
:: Restaura mitigacoes de Spectre e Meltdown (padrao do Windows)
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "MoveImages" /f >nul 2>&1
exit
