@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: ============================================================
:: DESATIVAR LINHA DO TEMPO (Activity Feed / Timeline)
:: ============================================================

:: Desativar via Política de Grupo
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed"    /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities"  /t REG_DWORD /d 0 /f

:: Desativar via registro do usuário
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ActivityFeed" /v "ActivityFeedEnabled" /t REG_DWORD /d 0 /f

:: Desativar coleta e upload de atividades
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f

exit

:revert
:: ============================================================
:: REATIVAR LINHA DO TEMPO
:: ============================================================

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed"    /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities"  /f 2>nul

reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ActivityFeed" /v "ActivityFeedEnabled" /f 2>nul

reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 1 /f

exit
