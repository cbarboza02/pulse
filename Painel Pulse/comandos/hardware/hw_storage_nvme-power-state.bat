@echo off
:: Verifica qual argumento foi enviado
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Mantém o NVMe no estado de máximo desempenho (PS0) sem transições de energia
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IdlePowerState" /t REG_DWORD /d 0 /f
:: Desativa o gerenciamento de energia do driver NVMe
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "EnableDevicePowerManagement" /t REG_DWORD /d 0 /f
:: Desativa HIPM (Host-Initiated Power Management) e DIPM (Device-Initiated)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "EnableHIPM" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "EnableDIPM" /t REG_DWORD /d 0 /f
:: Desativa APST (Autonomous Power State Transitions) via plano de energia
powercfg /setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 0
powercfg /setactive SCHEME_CURRENT
exit

:revert
:: Restaura gerenciamento de energia do NVMe ao padrão
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IdlePowerState" /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "EnableDevicePowerManagement" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "EnableHIPM" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "EnableDIPM" /t REG_DWORD /d 1 /f
powercfg /setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 1
powercfg /setactive SCHEME_CURRENT
exit
