@echo off
if /i "%~1"=="apply" goto pulseos
if /i "%~1"=="revert" goto pulseos
exit /b

:pulseos
:: Reaplica completamente o padrao PulseOS para estimativa/diagnosticos de energia.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EnergyEstimationEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EnergyEstimationDisabled" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "UserBatteryDischargeEstimator" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EEEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "SleepStudyEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Power\PowerSettings" /v "EnergyEstimationEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Power\PowerSettings" /v "EventProcessingEnabled" /t REG_DWORD /d 0 /f
schtasks /Change /TN "Microsoft\Windows\Power Efficiency Diagnostics\SleepStudy" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Power Efficiency Diagnostics\Calibration" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Power Efficiency Diagnostics\BackgroundEnergyDiagnostics" /Disable >nul 2>&1
sc stop "SensrSvc" >nul 2>&1
sc config "SensrSvc" start= disabled >nul 2>&1
exit /b
