@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa a Manutencao Automatica do Windows (diagnostico, desfrag, atualizacoes em background)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /t REG_DWORD /d 1 /f
:: Desativa tarefas agendadas de manutencao automatica
schtasks /Change /TN "Microsoft\Windows\TaskScheduler\Regular Maintenance" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\TaskScheduler\Maintenance Configurator" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\Diagnosis\Scheduled" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\DiskFootprint\Diagnostics" /Disable 2>nul
schtasks /Change /TN "Microsoft\Windows\WDI\ResolutionHost" /Disable 2>nul
exit

:revert
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /f 2>nul
schtasks /Change /TN "Microsoft\Windows\TaskScheduler\Regular Maintenance" /Enable 2>nul
schtasks /Change /TN "Microsoft\Windows\TaskScheduler\Maintenance Configurator" /Enable 2>nul
schtasks /Change /TN "Microsoft\Windows\Diagnosis\Scheduled" /Enable 2>nul
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Enable 2>nul
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" /Enable 2>nul
schtasks /Change /TN "Microsoft\Windows\DiskFootprint\Diagnostics" /Enable 2>nul
schtasks /Change /TN "Microsoft\Windows\WDI\ResolutionHost" /Enable 2>nul
exit
