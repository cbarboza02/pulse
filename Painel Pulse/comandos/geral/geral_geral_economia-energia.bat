@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa gestão de energia para dispositivos USB (evita desligar USB para economizar energia)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v "DisableSelectiveSuspend" /t REG_DWORD /d 1 /f
:: Desativa suspensão seletiva USB via política de energia
reg add "HKLM\SYSTEM\CurrentControlSet\Services\usbhub\Parameters" /v "DisableSelectiveSuspend" /t REG_DWORD /d 1 /f
:: Desativa power management em adaptadores de rede (via powershell para todos os adaptadores)
powershell -NoProfile -Command "Get-NetAdapter | ForEach-Object { $path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}'; $adapters = Get-ChildItem $path -ErrorAction SilentlyContinue; foreach ($a in $adapters) { if ((Get-ItemProperty $a.PSPath -Name 'NetCfgInstanceId' -ErrorAction SilentlyContinue).NetCfgInstanceId -eq $_.InterfaceGuid) { Set-ItemProperty $a.PSPath -Name 'PnPCapabilities' -Value 24 -ErrorAction SilentlyContinue } } }"
:: Desativa configuração de link state power management
powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
powercfg /setdcvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
powercfg /setactive SCHEME_CURRENT
exit

:revert
:: Reativa gestão de energia para dispositivos USB
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v "DisableSelectiveSuspend" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\usbhub\Parameters" /v "DisableSelectiveSuspend" /f 2>nul
:: Restaura power management nos adaptadores (remove PnPCapabilities = volta ao padrão)
powershell -NoProfile -Command "Get-NetAdapter | ForEach-Object { $path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}'; $adapters = Get-ChildItem $path -ErrorAction SilentlyContinue; foreach ($a in $adapters) { if ((Get-ItemProperty $a.PSPath -Name 'NetCfgInstanceId' -ErrorAction SilentlyContinue).NetCfgInstanceId -eq $_.InterfaceGuid) { Remove-ItemProperty $a.PSPath -Name 'PnPCapabilities' -ErrorAction SilentlyContinue } } }"
powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1
powercfg /setdcvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1
powercfg /setactive SCHEME_CURRENT
exit
