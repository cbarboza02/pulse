@echo off
if /i "%~1"=="apply" goto pulseos
if /i "%~1"=="revert" goto pulseos
exit /b

:pulseos
:: Reaplica o padrao PulseOS: hibernacao e inicializacao rapida desativadas.
powercfg /hibernate off >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0 >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HibernateEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HibernateEnabledDefault" /t REG_DWORD /d 0 /f
exit /b
