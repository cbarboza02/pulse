@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o gerenciamento avancado de energia USB (EnhancedPowerManagementEnabled)
:: para todos os dispositivos USB registrados no sistema
:: Percorre Enum\USB para desativar em cada instancia de dispositivo
for /f "tokens=*" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\USB" /s /k 2^>nul ^| findstr "HKLM"') do (
    reg add "%%k\Device Parameters" /v EnhancedPowerManagementEnabled /t REG_DWORD /d 0 /f >nul 2>&1
)
:: Desativa ACPI USB wake via registro
reg add "HKLM\SYSTEM\CurrentControlSet\Services\HidUsb\Parameters" /v EnhancedPowerManagementEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Desativa USB D3 cold (estado de energia profunda para USB)
for /f "tokens=*" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\USB" /s /k 2^>nul ^| findstr "HKLM"') do (
    reg add "%%k\Device Parameters" /v D3ColdSupported /t REG_DWORD /d 0 /f >nul 2>&1
)
:: Desativa o Link Power Management (LPM) para controladores USB 3.0
:: Impede que o link USB entre em estados U1/U2 de baixo consumo, eliminando latencias de reconexao
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBXHCI\Parameters" /v SelectiveSuspendEnabledMask /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBXHCI\Parameters" /v AllowIdleIrpInD3 /t REG_DWORD /d 0 /f
:: Desativa LPM para todos os dispositivos USB 3.0 registrados
for /f "tokens=*" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\USB" /s /k 2^>nul ^| findstr "HKLM"') do (
    reg add "%%k\Device Parameters" /v SelectiveSuspendEnabled /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "%%k\Device Parameters" /v EnableSelectiveSuspend /t REG_DWORD /d 0 /f >nul 2>&1
)
:: Desativa Suspensao Seletiva do USB no plano de energia ativo
powercfg -setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg -setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setactive SCHEME_CURRENT
:: Desativa o Estado de Suspensao Seletiva via registro
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f
:: Desativa Hub Root USB (suspensao seletiva via devmgmt)
:: Percorre todos os controladores USB e desativa suspensao seletiva
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | Where-Object { $_.InstanceName -match 'USB' } | ForEach-Object { $_.Enable = $false; $_.Put() }"
:: Desativa suspensao seletiva para todos os hubs USB via registro
for /f "tokens=*" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "EnhancedPowerManagementEnabled" /k 2^>nul ^| findstr "HKLM"') do (
    reg add "%%k" /v EnhancedPowerManagementEnabled /t REG_DWORD /d 0 /f >nul 2>&1
)
:: Desativa suspensao para controladores USB via DeviceParameters
for /f "tokens=*" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "SelectiveSuspendEnabled" /k 2^>nul ^| findstr "HKLM"') do (
    reg add "%%k\Device Parameters" /v SelectiveSuspendEnabled /t REG_DWORD /d 0 /f >nul 2>&1
)
exit

:revert
:: Restaura o gerenciamento avancado de energia para dispositivos USB
for /f "tokens=*" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\USB" /s /k 2^>nul ^| findstr "HKLM"') do (
    reg delete "%%k\Device Parameters" /v EnhancedPowerManagementEnabled /f >nul 2>&1
    reg delete "%%k\Device Parameters" /v D3ColdSupported /f >nul 2>&1
)
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\HidUsb\Parameters" /v EnhancedPowerManagementEnabled /f >nul 2>&1
:: Restaura o LPM para controladores USB 3.0
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USBXHCI\Parameters" /v SelectiveSuspendEnabledMask /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USBXHCI\Parameters" /v AllowIdleIrpInD3 /f 2>nul
for /f "tokens=*" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\USB" /s /k 2^>nul ^| findstr "HKLM"') do (
    reg delete "%%k\Device Parameters" /v SelectiveSuspendEnabled /f >nul 2>&1
    reg delete "%%k\Device Parameters" /v EnableSelectiveSuspend /f >nul 2>&1
)
:: Restaura Suspensao Seletiva USB no plano de energia
powercfg -setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1
powercfg -setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1
powercfg /setactive SCHEME_CURRENT
:: Remove override de suspensao seletiva via registro
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /f 2>nul
:: Reativa a suspensao seletiva para hubs USB
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | Where-Object { $_.InstanceName -match 'USB' } | ForEach-Object { $_.Enable = $true; $_.Put() }"
::. Restaura EnhancedPowerManagement nos dispositivos USB
for /f "tokens=*" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "EnhancedPowerManagementEnabled" /k 2^>nul ^| findstr "HKLM"') do (
    reg add "%%k" /v EnhancedPowerManagementEnabled /t REG_DWORD /d 1 /f >nul 2>&1
)
:: Restaura SelectiveSuspendEnabled nos controladores USB
for /f "tokens=*" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "SelectiveSuspendEnabled" /k 2^>nul ^| findstr "HKLM"') do (
    reg add "%%k\Device Parameters" /v SelectiveSuspendEnabled /t REG_DWORD /d 1 /f >nul 2>&1
)
exit
