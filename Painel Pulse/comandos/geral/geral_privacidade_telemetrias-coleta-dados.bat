@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: ============================================================
:: DESATIVAR TELEMETRIAS E COLETA DE DADOS
:: ============================================================

:: 1. NIVEL DE COLETA / TELEMETRIA
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"                /v "AllowTelemetry"                             /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry"                             /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "MaxTelemetryAllowed"                        /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"                /v "DoNotShowFeedbackNotifications"              /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"                /v "DisableTelemetryOptInChangeNotification"     /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"                /v "DisableTelemetryOptInSettingsUx"             /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"                /v "LimitEnhancedDiagnosticDataWindowsAnalytics" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"                /v "DisableFeedback"                             /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"                /v "AllowFeedback"                               /t REG_DWORD /d 0 /f

:: 2. SERVICOS DE TELEMETRIA E DIAGNOSTICO
:: CORRECAO: adicionados >nul 2>&1 em todos os sc config (imprimiam SUCCESS no console)
sc config "DiagTrack"                                start= disabled >nul 2>&1
sc stop   "DiagTrack"                                2>nul
sc config "dmwappushservice"                         start= demand   >nul 2>&1
sc stop   "dmwappushservice"                         2>nul
sc config "diagsvc"                                  start= demand   >nul 2>&1
sc stop   "diagsvc"                                  2>nul
sc config "diagnosticshub.standardcollector.service" start= disabled >nul 2>&1
sc stop   "diagnosticshub.standardcollector.service" 2>nul
sc config "WerSvc"                                   start= disabled >nul 2>&1
sc stop   "WerSvc"                                   2>nul
sc config "AeLookupSvc"                              start= disabled >nul 2>&1
sc stop   "AeLookupSvc"                              2>nul
sc config "PcaSvc"                                   start= demand   >nul 2>&1
sc stop   "PcaSvc"                                   2>nul
sc config "SpeechRuntime"                            start= disabled >nul 2>&1 2>nul
sc stop   "SpeechRuntime"                            2>nul
sc config "Ndu"                                      start= disabled >nul 2>&1 2>nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndu" /v "Start" /t REG_DWORD /d 4 /f

:: 3. TELEMETRIA DE COMPATIBILIDADE
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisablePCA"       /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR"       /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable"        /t REG_DWORD /d 0 /f
icacls "%SystemRoot%\System32\CompatTelRunner.exe" /inheritance:r /deny "Everyone:(OI)(CI)(F)" 2>nul
icacls "%SystemRoot%\System32\CompatTelRunner.exe" /deny "SYSTEM:(OI)(CI)(F)" 2>nul

:: 4. AUTOLOGGERS / WMI / CIMOM EVENTS
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener"  /v "Start" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DiagLog"                        /v "Start" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Diagtrack-Listener"             /v "Start" /t REG_DWORD /d 0 /f 2>nul
:: NOTA: Circular Kernel Context Logger e usado internamente pelo ETW e pelo profiler do Windows.
:: Desativa-lo pode afetar ferramentas de diagnostico e depuracao do sistema.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Circular Kernel Context Logger" /v "Start" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WMI\CIMOM" /v "AllowAnonymousCallback" /t REG_DWORD /d 0 /f
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-WMIObject -Namespace root/subscription -Class __EventFilter   2>$null | Where-Object { $_.Name -match 'telemetry|Diagtrack|diagnostic|ceip|sqm' } | Remove-WMIObject 2>$null"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-WMIObject -Namespace root/subscription -Class __EventConsumer 2>$null | Where-Object { $_.Name -match 'telemetry|Diagtrack|diagnostic|ceip|sqm' } | Remove-WMIObject 2>$null"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WDI\{9c5a40da-b965-4fc3-8781-88dd50a6299d}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f

:: 5. CENTRO DE FEEDBACK / SIUF
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "PeriodInNanoSeconds"  /t REG_DWORD /d 0 /f

:: 6. CEIP (Customer Experience Improvement Program)
reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows"     /v "CEIPEnable"                        /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows"              /v "CEIPEnable"                        /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\SQM" /v "DisableCustomerImprovementProgram" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Internet Explorer\SQM"          /v "CEIPEnable"                        /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Office\Common\QMEnable" /v "Enable"                           /t REG_DWORD /d 0 /f 2>nul

:: 7. RELATORIOS DE ERROS / CRASH DUMP
:: NOTA IMPORTANTE: CrashDumpEnabled = 0 desativa COMPLETAMENTE a geracao de dumps.
:: Sem dumps, e impossivel diagnosticar BSODs. O Windows padrao usa 7 (automatic memory dump).
:: Valor 0 e adequado para sistemas de producao estavel, mas dificulta muito o troubleshooting.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "CrashDumpEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "LogEvent"         /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "SendAlert"        /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "AutoReboot"       /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "NMICrashDump"     /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "MinidumpsCount"   /t REG_DWORD /d 0 /f

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "DontShowUI"             /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled"               /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "DontSendAdditionalData" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "LoggingDisabled"        /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "BypassDataThrottling"   /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "DontShowUI"              /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "DontShowUI"              /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled"               /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "DontSendAdditionalData" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "LoggingDisabled"        /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "AutoApproveOSDumps"     /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultConsent"          /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultOverrideBehavior" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\WMR"     /v "Disable"                 /t REG_DWORD /d 1 /f

:: 8. FALA E ENTRADA DE TEXTO
reg add "HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"                          /v "HasAccepted"                         /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Speech"                                                      /v "AllowSpeechModelUpdate"              /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Speech_OneCore\Preferences"                                           /v "VoiceActivationOn"                   /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Speech_OneCore\Preferences"                                           /v "VoiceActivationEnableAboveLockscreen" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps"    /v "AgentActivationEnabled"              /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps"    /v "AgentActivationLastUsed"             /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsActivateWithVoice"           /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsActivateWithVoiceAboveLock"  /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana"          /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortanaAboveLock" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableSpellchecking"  /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableAutoCorrection" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableTextPrediction" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableDoubleTapSpace" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete" /v "Append Completion" /t REG_SZ /d "no" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete" /v "AutoSuggest"        /t REG_SZ /d "no" /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Internet Explorer\AutoComplete"      /v "Enabled"            /t REG_SZ /d "no" /f
reg add "HKCU\SOFTWARE\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d 0 /f

:: 9. PERSONALIZACAO E EXPERIENCIAS
reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization"                  /v "RestrictImplicitInkCollection"                /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization"                  /v "RestrictImplicitTextCollection"               /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Personalization\Settings"              /v "AcceptedPrivacyPolicy"                        /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization"         /v "AllowInputPersonalization"                    /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestContacts"                              /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"        /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Help"                 /v "DisableOnlineSupport"  /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Assistance\Client\1.0"       /v "NoExplicitFeedback"    /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Assistance\Client\1.0"       /v "NoImplicitFeedback"    /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Assistance\Client\1.0"       /v "NoOnlineAssist"        /t REG_DWORD /d 1 /f 2>nul

:: 10. COLETA DE ATIVIDADES DO USUARIO
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed"    /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities"  /t REG_DWORD /d 0 /f

:: 11. TELEMETRIA DE ENERGIA
reg add "HKLM\SOFTWARE\Policies\Microsoft\Power\PowerSettings" /v "EnergyEstimationEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Power\PowerSettings" /v "EventProcessingEnabled"  /t REG_DWORD /d 0 /f

:: 12. TAREFAS AGENDADAS
schtasks /change /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Application Experience\ProgramDataUpdater"               /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Application Experience\StartupAppTask"                   /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Application Experience\AitAgent"                         /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Application Experience\MareBackup"                       /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Application Experience\PcaPatchDbTask"                   /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"    /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask"  /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"         /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\BthSQM"          /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\NetCfg\InternetSharingConfigUpdaterTask"                 /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Feedback\Siuf\DmClient"                   /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Diagnosis\Scheduled"                                          /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Windows Error Reporting\QueueReporting"                       /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\DiskFootprint\Diagnostics"                                    /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Maintenance\WinSAT"                                           /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\WMI\BVTScan"                                                  /disable 2>nul
schtasks /change /tn "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem"                   /disable 2>nul

:: 13. BLOCO DE HOSTS - TELEMETRIA MICROSOFT
set HOSTS=%SystemRoot%\System32\drivers\etc\hosts
findstr /c:"TELEMETRIA_BLOCK_START" "%HOSTS%" >nul 2>&1
if errorlevel 1 (
    echo.                                                          >> "%HOSTS%"
    echo # [TELEMETRIA_BLOCK_START]                               >> "%HOSTS%"
    echo 0.0.0.0 vortex.data.microsoft.com                        >> "%HOSTS%"
    echo 0.0.0.0 vortex-win.data.microsoft.com                    >> "%HOSTS%"
    echo 0.0.0.0 telecommand.telemetry.microsoft.com              >> "%HOSTS%"
    echo 0.0.0.0 oca.telemetry.microsoft.com                      >> "%HOSTS%"
    echo 0.0.0.0 sqm.telemetry.microsoft.com                      >> "%HOSTS%"
    echo 0.0.0.0 watson.telemetry.microsoft.com                   >> "%HOSTS%"
    echo 0.0.0.0 df.telemetry.microsoft.com                       >> "%HOSTS%"
    echo 0.0.0.0 reports.wes.df.telemetry.microsoft.com           >> "%HOSTS%"
    echo 0.0.0.0 wes.df.telemetry.microsoft.com                   >> "%HOSTS%"
    echo 0.0.0.0 services.wes.df.telemetry.microsoft.com          >> "%HOSTS%"
    echo 0.0.0.0 sqm.df.telemetry.microsoft.com                   >> "%HOSTS%"
    echo 0.0.0.0 telemetry.microsoft.com                          >> "%HOSTS%"
    echo 0.0.0.0 watson.ppe.telemetry.microsoft.com               >> "%HOSTS%"
    echo 0.0.0.0 telemetry.appex.bing.net                         >> "%HOSTS%"
    echo 0.0.0.0 telemetry.urs.microsoft.com                      >> "%HOSTS%"
    echo 0.0.0.0 settings-sandbox.data.microsoft.com              >> "%HOSTS%"
    echo 0.0.0.0 vortex-sandbox.data.microsoft.com                >> "%HOSTS%"
    echo 0.0.0.0 statsfe2.ws.microsoft.com                        >> "%HOSTS%"
    echo 0.0.0.0 compattelemetry.microsoft.com                    >> "%HOSTS%"
    echo 0.0.0.0 legacytelemetry.microsoft.com                    >> "%HOSTS%"
    echo 0.0.0.0 functional.events.data.microsoft.com             >> "%HOSTS%"
    echo 0.0.0.0 browser.events.data.microsoft.com                >> "%HOSTS%"
    echo 0.0.0.0 watson.live.com                                   >> "%HOSTS%"
    echo 0.0.0.0 watson.microsoft.com                              >> "%HOSTS%"
    echo 0.0.0.0 corpext.msitadfs.glbdns2.microsoft.com           >> "%HOSTS%"
    echo 0.0.0.0 settings.data.microsoft.com                      >> "%HOSTS%"
    echo 0.0.0.0 watson.events.data.microsoft.com                 >> "%HOSTS%"
    echo 0.0.0.0 v10.events.data.microsoft.com                    >> "%HOSTS%"
    echo 0.0.0.0 v20.events.data.microsoft.com                    >> "%HOSTS%"
    echo 0.0.0.0 v10.vortex-win.data.microsoft.com                >> "%HOSTS%"
    echo 0.0.0.0 v20.vortex-win.data.microsoft.com                >> "%HOSTS%"
    echo 0.0.0.0 oca.microsoft.com                                 >> "%HOSTS%"
    echo 0.0.0.0 kmwatsonc.events.data.microsoft.com              >> "%HOSTS%"
    echo # [TELEMETRIA_BLOCK_END]                                  >> "%HOSTS%"
)
exit

:revert
:: Reativar servicos
sc config "DiagTrack"                                start= auto   >nul 2>&1
sc start  "DiagTrack"                                2>nul
sc config "dmwappushservice"                         start= demand >nul 2>&1
sc start  "dmwappushservice"                         2>nul
sc config "diagsvc"                                  start= demand >nul 2>&1
sc start  "diagsvc"                                  2>nul
sc config "diagnosticshub.standardcollector.service" start= demand >nul 2>&1
sc config "WerSvc"                                   start= demand >nul 2>&1
sc start  "WerSvc"                                   2>nul
sc config "AeLookupSvc"                              start= demand >nul 2>&1
sc start  "AeLookupSvc"                              2>nul
sc config "PcaSvc"                                   start= auto   >nul 2>&1
sc start  "PcaSvc"                                   2>nul
sc config "SpeechRuntime"                            start= demand >nul 2>&1 2>nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndu" /v "Start" /t REG_DWORD /d 2 /f

:: Remover politicas de coleta de dados
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry"                             /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications"             /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DisableTelemetryOptInChangeNotification"    /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DisableTelemetryOptInSettingsUx"            /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "LimitEnhancedDiagnosticDataWindowsAnalytics" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DisableFeedback"                            /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowFeedback"                              /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry"              /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "MaxTelemetryAllowed"          /f 2>nul

:: Restaurar AppCompat
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisablePCA"       /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR"       /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable"        /f 2>nul
icacls "%SystemRoot%\System32\CompatTelRunner.exe" /reset 2>nul

:: Restaurar autologgers
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener"  /v "Start" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DiagLog"                        /v "Start" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Circular Kernel Context Logger" /v "Start" /t REG_DWORD /d 1 /f 2>nul
:: CORRECAO: EventLog-Application era restaurado no revert original mas NUNCA foi alterado no apply
:: — linha removida por ser assimetrica e desnecessaria
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WMI\CIMOM" /v "AllowAnonymousCallback" /f 2>nul

:: Restaurar Centro de Feedback
reg delete "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "PeriodInNanoSeconds"  /f 2>nul

:: Restaurar CEIP
reg delete "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows"     /v "CEIPEnable"                        /f 2>nul
reg add    "HKLM\SOFTWARE\Microsoft\SQMClient\Windows"              /v "CEIPEnable" /t REG_DWORD /d 1 /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\SQM" /v "DisableCustomerImprovementProgram" /f 2>nul
reg add    "HKLM\SOFTWARE\Microsoft\Internet Explorer\SQM"          /v "CEIPEnable" /t REG_DWORD /d 1 /f

:: Restaurar Crash Dump (7 = automatic memory dump, padrao Windows)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "CrashDumpEnabled" /t REG_DWORD /d 7 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "LogEvent"         /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "SendAlert"        /t REG_DWORD /d 0 /f

:: Remover politicas WER
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "DontShowUI"             /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled"               /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "DontSendAdditionalData" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "LoggingDisabled"        /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "BypassDataThrottling"   /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled"               /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "DontSendAdditionalData" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "LoggingDisabled"        /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "DontShowUI"             /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "AutoApproveOSDumps"     /f 2>nul
reg add    "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultConsent" /t REG_DWORD /d 1 /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultOverrideBehavior" /f 2>nul

:: Restaurar fala e entrada
reg add    "HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" /v "HasAccepted"           /t REG_DWORD /d 1 /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Speech"                              /v "AllowSpeechModelUpdate" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"   /v "LetAppsActivateWithVoice"          /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"   /v "LetAppsActivateWithVoiceAboveLock" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana"          /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortanaAboveLock" /f 2>nul
reg add    "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableSpellchecking"  /t REG_DWORD /d 1 /f
reg add    "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableAutoCorrection" /t REG_DWORD /d 1 /f
reg add    "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableTextPrediction" /t REG_DWORD /d 1 /f
reg add    "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableDoubleTapSpace" /t REG_DWORD /d 1 /f
reg add    "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete" /v "Append Completion" /t REG_SZ /d "yes" /f
reg add    "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete" /v "AutoSuggest"        /t REG_SZ /d "yes" /f
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Internet Explorer\AutoComplete"      /v "Enabled"            /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Input\TIPC" /v "Enabled" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Input\TIPC" /v "Enabled" /f 2>nul

:: Restaurar personalizacao
reg delete "HKCU\SOFTWARE\Microsoft\InputPersonalization"          /v "RestrictImplicitInkCollection"                /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\InputPersonalization"          /v "RestrictImplicitTextCollection"               /f 2>nul
reg add    "HKCU\SOFTWARE\Microsoft\Personalization\Settings"      /v "AcceptedPrivacyPolicy" /t REG_DWORD /d 1 /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" /v "AllowInputPersonalization"                    /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestContacts"                      /f 2>nul
reg add    "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 1 /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Help"              /v "DisableOnlineSupport" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Assistance\Client\1.0"    /v "NoExplicitFeedback"   /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Assistance\Client\1.0"    /v "NoImplicitFeedback"   /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Assistance\Client\1.0"    /v "NoOnlineAssist"       /f 2>nul

:: Restaurar atividades
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed"    /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities"  /f 2>nul

:: Restaurar telemetria de energia
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Power\PowerSettings" /v "EnergyEstimationEnabled" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Power\PowerSettings" /v "EventProcessingEnabled"  /f 2>nul

:: Reativar tarefas agendadas
schtasks /change /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\Application Experience\ProgramDataUpdater"               /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\Application Experience\StartupAppTask"                   /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\Application Experience\AitAgent"                         /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"    /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask"  /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"         /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\BthSQM"          /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\Feedback\Siuf\DmClient"                   /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\Diagnosis\Scheduled"                                          /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\Windows Error Reporting\QueueReporting"                       /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\WMI\BVTScan"                                                  /enable 2>nul
schtasks /change /tn "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem"                   /enable 2>nul

:: Remover blocos do arquivo hosts
powershell -NoProfile -ExecutionPolicy Bypass -Command "$skip=$false; $out=@(); Get-Content '%SystemRoot%\System32\drivers\etc\hosts' | ForEach-Object { if ($_ -match 'TELEMETRIA_BLOCK_START') { $skip=$true }; if (-not $skip) { $out+=$_ }; if ($_ -match 'TELEMETRIA_BLOCK_END') { $skip=$false } }; $out | Set-Content '%SystemRoot%\System32\drivers\etc\hosts'"
exit
