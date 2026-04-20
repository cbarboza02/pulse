@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa Suspensão Híbrida (Hybrid Sleep) no plano de energia atual
:: AC (plugado na tomada)
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
:: DC (na bateria)
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
:: Aplica as configurações
powercfg /setactive SCHEME_CURRENT
:: Desativa via registro
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\238C9FA8-0AAD-41ED-83F4-97BE242C8F20\94ac6d29-73ce-41a6-809f-6363ba21b47e" /v "ACSettingIndex" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\238C9FA8-0AAD-41ED-83F4-97BE242C8F20\94ac6d29-73ce-41a6-809f-6363ba21b47e" /v "DCSettingIndex" /t REG_DWORD /d 0 /f
exit

:revert
:: Reativa Suspensão Híbrida
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 1
powercfg /setactive SCHEME_CURRENT
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\238C9FA8-0AAD-41ED-83F4-97BE242C8F20\94ac6d29-73ce-41a6-809f-6363ba21b47e" /v "ACSettingIndex" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\238C9FA8-0AAD-41ED-83F4-97BE242C8F20\94ac6d29-73ce-41a6-809f-6363ba21b47e" /v "DCSettingIndex" /t REG_DWORD /d 1 /f
exit
