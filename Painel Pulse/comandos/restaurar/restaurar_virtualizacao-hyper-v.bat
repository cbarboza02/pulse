@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar Virtualizacao e Hyper-V
:: REQUER REINICIALIZACAO
bcdedit /set hypervisorlaunchtype auto 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequirePlatformSecurityFeatures" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "Locked" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard" /v "Enabled" /f 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "$svcs=@('vmcompute','vmms','HvHost','vmicguestinterface','vmicheartbeat','vmickvpexchange','vmicrdv','vmicshutdown','vmictimesync','vmicvmsession','vmicvss'); foreach($s in $svcs){ if(Get-Service -Name $s -ErrorAction SilentlyContinue){ Set-Service -Name $s -StartupType Manual -ErrorAction SilentlyContinue } }"
dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /norestart /all 2>nul
dism /online /enable-feature /featurename:VirtualMachinePlatform /norestart 2>nul
dism /online /enable-feature /featurename:HypervisorPlatform /norestart 2>nul
exit /b

:padrao
:: Re-aplicar desativacao do Hyper-V e Virtualizacao
:: REQUER REINICIALIZACAO
bcdedit /set hypervisorlaunchtype off 2>nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard" /v "Enabled" /t REG_DWORD /d 0 /f
powershell -NoProfile -ExecutionPolicy Bypass -Command "$svcs=@('vmcompute','vmms','HvHost','vmicguestinterface','vmicheartbeat','vmickvpexchange','vmicrdv','vmicshutdown','vmictimesync','vmicvmsession','vmicvss'); foreach($s in $svcs){ if(Get-Service -Name $s -ErrorAction SilentlyContinue){ Stop-Service -Name $s -Force -ErrorAction SilentlyContinue; Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue } }"
dism /online /disable-feature /featurename:Microsoft-Hyper-V-All /norestart 2>nul
dism /online /disable-feature /featurename:VirtualMachinePlatform /norestart 2>nul
dism /online /disable-feature /featurename:HypervisorPlatform /norestart 2>nul
exit /b
