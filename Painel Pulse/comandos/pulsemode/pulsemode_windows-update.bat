@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
schtasks /Delete /TN "Pulse Mode - Otimizar Windows Update" /F 2>nul

if not exist "C:\Painel Pulse\tarefas" md "C:\Painel Pulse\tarefas"
if not exist "%USERPROFILE%\Documents\Painel Pulse\Logs" md "%USERPROFILE%\Documents\Painel Pulse\Logs"

(
echo # Pulse Mode - Otimizar Windows Update
echo # Executado pela tarefa agendada a cada logon.
echo $ErrorActionPreference = 'SilentlyContinue'
echo.
echo # 1. Parar e desativar servicos do Windows Update
echo $servicos = @^('UsoSvc', 'bits', 'WpnService'^)
echo foreach ^($svc in $servicos^) {
echo     try {
echo         Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
echo         Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
echo     } catch {}
echo }
echo try { Stop-Service -Name 'WaaSMedicSvc' -Force -ErrorAction SilentlyContinue } catch {}
echo $medicPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc'
echo if ^(Test-Path $medicPath^) {
echo     try { Set-ItemProperty -Path $medicPath -Name 'Start' -Value 4 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
echo }
echo Set-Service -Name 'wuauserv' -StartupType Manual -ErrorAction SilentlyContinue
echo Set-Service -Name 'dosvc' -StartupType Manual -ErrorAction SilentlyContinue
echo.
echo # 2. Bloquear Upload P2P - Otimizacao de Entrega
echo $doPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
echo if ^(-not ^(Test-Path $doPath^)^) { New-Item -Path $doPath -Force ^| Out-Null }
echo Set-ItemProperty -Path $doPath -Name 'DOUploadMode' -Value 0 -Type DWord -Force
echo Set-ItemProperty -Path $doPath -Name 'DOMaxUploadRate' -Value 0 -Type DWord -Force
echo Set-ItemProperty -Path $doPath -Name 'DOMaxBackgroundUploadBandwidth' -Value 0 -Type DWord -Force
echo Set-ItemProperty -Path $doPath -Name 'DOMaxForegroundUploadBandwidth' -Value 0 -Type DWord -Force
echo.
echo # 3. Desativar atualizacao de drivers via Windows Update
echo $wuPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
echo if ^(-not ^(Test-Path $wuPath^)^) { New-Item -Path $wuPath -Force ^| Out-Null }
echo Set-ItemProperty -Path $wuPath -Name 'ExcludeWUDriversInQualityUpdate' -Value 1 -Type DWord -Force
echo $auPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
echo if ^(-not ^(Test-Path $auPath^)^) { New-Item -Path $auPath -Force ^| Out-Null }
echo Set-ItemProperty -Path $auPath -Name 'NoAutoUpdate' -Value 1 -Type DWord -Force
echo Set-ItemProperty -Path $auPath -Name 'AUOptions' -Value 1 -Type DWord -Force
echo Set-ItemProperty -Path $auPath -Name 'NoAutoRebootWithLoggedOnUsers' -Value 1 -Type DWord -Force
echo.
echo # 4. Pausar Windows Update por 7 dias
echo $inicio = ^(Get-Date^).ToUniversalTime^(^).ToString^('yyyy-MM-ddTHH:mm:ssZ'^)
echo $fim = ^(Get-Date^).AddDays^(7^).ToUniversalTime^(^).ToString^('yyyy-MM-ddTHH:mm:ssZ'^)
echo $uxPath = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
echo if ^(-not ^(Test-Path $uxPath^)^) { New-Item -Path $uxPath -Force ^| Out-Null }
echo Set-ItemProperty -Path $uxPath -Name 'PauseUpdatesStartTime' -Value $inicio -Type String -Force
echo Set-ItemProperty -Path $uxPath -Name 'PauseUpdatesExpiryTime' -Value $fim -Type String -Force
echo Set-ItemProperty -Path $uxPath -Name 'PauseFeatureUpdatesStartTime' -Value $inicio -Type String -Force
echo Set-ItemProperty -Path $uxPath -Name 'PauseFeatureUpdatesEndTime' -Value $fim -Type String -Force
echo Set-ItemProperty -Path $uxPath -Name 'PauseQualityUpdatesStartTime' -Value $inicio -Type String -Force
echo Set-ItemProperty -Path $uxPath -Name 'PauseQualityUpdatesEndTime' -Value $fim -Type String -Force
echo Set-ItemProperty -Path $uxPath -Name 'FlightSettingsMaxPauseDays' -Value 35 -Type DWord -Force
echo.
echo # 5. Log de execucao da tarefa
echo Add-Content -Path '%USERPROFILE%\Documents\Painel Pulse\Logs\PulseLog_otimizar-windows-update.txt' -Value ^('[TAREFA] Executada em: ' + ^(Get-Date^)^)
) > "C:\Painel Pulse\tarefas\pulsemode_otimizar-windows-update.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='C:\Painel Pulse\tarefas\pulsemode_otimizar-windows-update.ps1'; $arg='-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File '+[char]34+$f+[char]34; $a=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arg; $t=New-ScheduledTaskTrigger -AtLogOn; $t.Delay='PT20S'; $p=New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest; $s=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; Register-ScheduledTask -TaskName 'Pulse Mode - Otimizar Windows Update' -Action $a -Trigger $t -Principal $p -Settings $s -Force"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Content -Path '%USERPROFILE%\Documents\Painel Pulse\Logs\PulseLog_otimizar-windows-update.txt' -Value ('[PAINEL PULSE] Arquivo e tarefa criados com sucesso em: ' + (Get-Date))"

powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Painel Pulse\tarefas\pulsemode_otimizar-windows-update.ps1"
exit

:revert
schtasks /Delete /TN "Pulse Mode - Otimizar Windows Update" /F 2>nul

if exist "C:\Painel Pulse\tarefas\pulsemode_otimizar-windows-update.ps1" (
    del /f /q "C:\Painel Pulse\tarefas\pulsemode_otimizar-windows-update.ps1"
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "if ((Test-Path 'C:\Painel Pulse\tarefas') -and ((Get-ChildItem 'C:\Painel Pulse\tarefas' -ErrorAction SilentlyContinue).Count -eq 0)) { Remove-Item 'C:\Painel Pulse\tarefas' -Force -ErrorAction SilentlyContinue }"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-Service -Name 'wuauserv' -StartupType Manual -ErrorAction SilentlyContinue; Start-Service -Name 'wuauserv' -ErrorAction SilentlyContinue; Set-Service -Name 'UsoSvc' -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service -Name 'UsoSvc' -ErrorAction SilentlyContinue; Set-Service -Name 'bits' -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service -Name 'bits' -ErrorAction SilentlyContinue; Set-Service -Name 'WpnService' -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service -Name 'WpnService' -ErrorAction SilentlyContinue; Set-Service -Name 'dosvc' -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service -Name 'dosvc' -ErrorAction SilentlyContinue; Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc' -Name 'Start' -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue; Start-Service -Name 'WaaSMedicSvc' -ErrorAction SilentlyContinue"

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DOUploadMode"                       /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DOMaxUploadRate"                    /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DOMaxBackgroundUploadBandwidth"     /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DOMaxForegroundUploadBandwidth"     /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"        /v "ExcludeWUDriversInQualityUpdate"    /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"     /v "NoAutoUpdate"                       /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"     /v "AUOptions"                          /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"     /v "NoAutoRebootWithLoggedOnUsers"       /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"             /v "PauseUpdatesStartTime"              /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"             /v "PauseUpdatesExpiryTime"             /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"             /v "PauseFeatureUpdatesStartTime"       /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"             /v "PauseFeatureUpdatesEndTime"         /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"             /v "PauseQualityUpdatesStartTime"       /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"             /v "PauseQualityUpdatesEndTime"         /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"             /v "FlightSettingsMaxPauseDays"         /f 2>nul
exit
