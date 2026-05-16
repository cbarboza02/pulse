@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa a Seguranca Baseada em Virtualizacao (VBS)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequirePlatformSecurityFeatures" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "Locked" /t REG_DWORD /d 0 /f >nul 2>&1
:: Desativa Credential Guard (componente do VBS)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LsaCfgFlags" /t REG_DWORD /d 0 /f >nul 2>&1
:: Desativa o hypervisor (necessario para desativar VBS completamente)
bcdedit /set hypervisorlaunchtype off >nul 2>&1
exit

:revert
:: Reativa a Seguranca Baseada em Virtualizacao (VBS)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequirePlatformSecurityFeatures" /t REG_DWORD /d 1 /f >nul 2>&1
:: CORRECAO: Locked foi definido no apply e deve ser revertido - deleta para retornar ao padrao
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "Locked" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LsaCfgFlags" /t REG_DWORD /d 1 /f >nul 2>&1
bcdedit /set hypervisorlaunchtype auto >nul 2>&1
exit
