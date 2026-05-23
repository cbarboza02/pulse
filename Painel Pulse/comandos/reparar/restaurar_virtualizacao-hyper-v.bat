@echo off
setlocal EnableExtensions
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b 1
:restaurar
:: Restaurar virtualizacao, Hyper-V, WSL e plataformas de VM.
dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /NoRestart >nul 2>&1
dism /online /enable-feature /featurename:VirtualMachinePlatform /all /NoRestart >nul 2>&1
dism /online /enable-feature /featurename:HypervisorPlatform /all /NoRestart >nul 2>&1
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /NoRestart >nul 2>&1
sc config vmms start= demand >nul 2>&1
sc config vmcompute start= demand >nul 2>&1
sc config HvHost start= demand >nul 2>&1
sc config vmicguestinterface start= demand >nul 2>&1
sc config vmicheartbeat start= demand >nul 2>&1
sc config vmickvpexchange start= demand >nul 2>&1
sc config vmicrdv start= demand >nul 2>&1
sc config vmicshutdown start= demand >nul 2>&1
sc config vmictimesync start= demand >nul 2>&1
sc config vmicvmsession start= demand >nul 2>&1
sc config vmicvss start= demand >nul 2>&1
bcdedit /set hypervisorlaunchtype auto >nul 2>&1
exit /b 0
:padrao
:: Reaplicar padrao PulseOS: virtualizacao desativada.
dism /online /disable-feature /featurename:Microsoft-Hyper-V-All /NoRestart >nul 2>&1
dism /online /disable-feature /featurename:VirtualMachinePlatform /NoRestart >nul 2>&1
dism /online /disable-feature /featurename:HypervisorPlatform /NoRestart >nul 2>&1
dism /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /NoRestart >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "$svcs=@('vmms','vmcompute','HvHost','vmicguestinterface','vmicheartbeat','vmickvpexchange','vmicrdv','vmicshutdown','vmictimesync','vmicvmsession','vmicvss');foreach($s in $svcs){if(Get-Service -Name $s -ErrorAction SilentlyContinue){Stop-Service -Name $s -Force -ErrorAction SilentlyContinue;Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue}}" >nul 2>&1
bcdedit /set hypervisorlaunchtype off >nul 2>&1
exit /b 0
