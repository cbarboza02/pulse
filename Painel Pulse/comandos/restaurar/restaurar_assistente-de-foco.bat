@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar Assistente de Foco / Nao Perturbe ao padrao do Windows 11

:: Remove as configuracoes de sessao de foco (Win10 CloudExperienceHost)
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent\FocusSession" /v "FocusSessionMinutes" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent" /v "QuietHoursFeatureEnabled" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent" /v "PlayingGameWithFocusMode" /f 2>nul

:: Restaura notificacoes criticas acima da tela de bloqueio
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" /t REG_DWORD /d 1 /f

:: CORRECAO: Remove tambem o override do Nao Perturbe global (Win11 22H2+)
:: O script PS1 de usuario define NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK = 0.
:: Remover a chave do Nao Perturbe garante que o modo nao esteja ativo apos a restauracao.
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_QUIETHOURS_ENABLED" /f 2>nul

:: Restaura o mesmo para o perfil DEFAULT (novos usuarios)
reg delete "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent\FocusSession" /v "FocusSessionMinutes" /f 2>nul
reg delete "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent" /v "QuietHoursFeatureEnabled" /f 2>nul
reg add    "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" /t REG_DWORD /d 1 /f
reg delete "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_QUIETHOURS_ENABLED" /f 2>nul

:: Reativa o Sleep Study (desabilitado pelo script de maquina junto com o Focus Assist)
schtasks /Change /TN "\Microsoft\Windows\Power Efficiency Diagnostics\SleepStudy" /Enable 2>nul
exit /b

:padrao
:: Re-aplicar desativacao do Assistente de Foco / Nao Perturbe

reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent\FocusSession" /v "FocusSessionMinutes" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent" /v "QuietHoursFeatureEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent" /v "PlayingGameWithFocusMode" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" /t REG_DWORD /d 0 /f

reg add "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent\FocusSession" /v "FocusSessionMinutes" /t REG_DWORD /d 0 /f
reg add "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudExperienceHost\Intent" /v "QuietHoursFeatureEnabled" /t REG_DWORD /d 0 /f
reg add "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" /t REG_DWORD /d 0 /f

schtasks /Change /TN "\Microsoft\Windows\Power Efficiency Diagnostics\SleepStudy" /Disable 2>nul
exit /b
