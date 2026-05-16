@echo off
:: Verifica qual argumento foi enviado
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Ativa MSI (Message Signaled Interrupts) e define prioridade High para controladores USB
powershell -ExecutionPolicy Bypass -NoProfile -Command ^
"$devices = Get-PnpDevice -Class 'USB' -Status 'OK' | Where-Object { $_.InstanceId -match '^PCI' }; foreach ($dev in $devices) { $msiPath = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $dev.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; $affPath = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $dev.InstanceId + '\Device Parameters\Interrupt Management\Affinity Policy'; try { New-Item -Path $msiPath -Force -ErrorAction Stop | Out-Null; Set-ItemProperty -Path $msiPath -Name 'MSISupported' -Value 1 -Type DWord -Force; New-Item -Path $affPath -Force -ErrorAction Stop | Out-Null; Set-ItemProperty -Path $affPath -Name 'DevicePriority' -Value 3 -Type DWord -Force } catch {} }"
exit

:revert
:: Remove MSI e prioridade customizada dos controladores USB (volta ao padrão)
powershell -ExecutionPolicy Bypass -NoProfile -Command ^
"$devices = Get-PnpDevice -Class 'USB' -Status 'OK' | Where-Object { $_.InstanceId -match '^PCI' }; foreach ($dev in $devices) { $msiPath = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $dev.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; $affPath = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $dev.InstanceId + '\Device Parameters\Interrupt Management\Affinity Policy'; try { if (Test-Path $msiPath) { Remove-ItemProperty -Path $msiPath -Name 'MSISupported' -ErrorAction SilentlyContinue }; if (Test-Path $affPath) { Remove-ItemProperty -Path $affPath -Name 'DevicePriority' -ErrorAction SilentlyContinue } } catch {} }"
exit
