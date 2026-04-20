@echo off
:: Verifica qual argumento foi enviado
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Bloqueia o Windows Insider via politica de grupo (GPO)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v AllowBuildPreview /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v EnableConfigFlighting /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v EnableExperimentation /t REG_DWORD /d 0 /f

:: Limpa / zera a inscricao ativa no Insider Program
reg add "HKLM\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /v UIBranch /t REG_SZ /d "" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /v ContentType /t REG_SZ /d "" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" /v UIRing /t REG_SZ /d "" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /v BranchName /t REG_SZ /d "" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /v Ring /t REG_SZ /d "" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /v IsFlight /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsSelfHost\Applicability" /v EnablePreviewBuilds /t REG_DWORD /d 0 /f >nul 2>&1

:: Desativa tarefas agendadas relacionadas ao Insider / Flighting
schtasks /change /tn "\Microsoft\Windows\WindowsUpdate\sihpostreboot" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\Flighting\OneSettings\RefreshCache" /disable >nul 2>&1
exit

:revert
:: Remove as politicas de bloqueio do Windows Insider
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v AllowBuildPreview /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v EnableConfigFlighting /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v EnableExperimentation /f >nul 2>&1

:: Reativa as tarefas agendadas desativadas
schtasks /change /tn "\Microsoft\Windows\WindowsUpdate\sihpostreboot" /enable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures" /enable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\Flighting\OneSettings\RefreshCache" /enable >nul 2>&1
exit
