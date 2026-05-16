@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o Assistente de Foco / Nao Perturbe (Win10 + Win11)
:: Win11: Desativa o Nao Perturbe global
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v NOC_GLOBAL_SETTING_QUIETHOURS_ENABLED /t REG_DWORD /d 0 /f
:: Win10 CloudStore - desativa via binario
powershell -NoProfile -Command "try { $p='HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\??windows.data.notifications.quiethourssettings\Current'; if(Test-Path $p){ $d=(Get-ItemProperty -Path $p -Name Data -EA Stop).Data; $backup=[Convert]::ToBase64String($d); Set-ItemProperty -Path $p -Name DataBackup -Value $backup -Type String -Force; $d[18]=0; Set-ItemProperty -Path $p -Name Data -Value $d -Type Binary -Force } } catch {}" >nul 2>&1
:: Desativa regras automaticas
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\QuietHours" /v WhenPlayingGameEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\QuietHours" /v WhenRunningFullscreenEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\QuietHours" /v WhenPresentationModeEnabled /t REG_DWORD /d 0 /f
:: Desativa alertas criticos na tela de bloqueio
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK /t REG_DWORD /d 0 /f
exit

:revert
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v NOC_GLOBAL_SETTING_QUIETHOURS_ENABLED /f >nul 2>&1
:: Restaura binario CloudStore a partir do backup
powershell -NoProfile -Command "try { $p='HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\??windows.data.notifications.quiethourssettings\Current'; if(Test-Path $p){ $b64=(Get-ItemProperty -Path $p -Name DataBackup -EA Stop).DataBackup; $orig=[Convert]::FromBase64String($b64); Set-ItemProperty -Path $p -Name Data -Value $orig -Type Binary -Force; Remove-ItemProperty -Path $p -Name DataBackup -EA SilentlyContinue } } catch {}" >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\QuietHours" /v WhenPlayingGameEnabled /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\QuietHours" /v WhenRunningFullscreenEnabled /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\QuietHours" /v WhenPresentationModeEnabled /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK /t REG_DWORD /d 1 /f
exit
