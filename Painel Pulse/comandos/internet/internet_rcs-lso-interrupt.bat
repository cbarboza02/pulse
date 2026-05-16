@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa RSC (Receive Segment Coalescing)
powershell -NoProfile -Command "Get-NetAdapter -Physical | Disable-NetAdapterRsc -ErrorAction SilentlyContinue" >nul 2>&1
netsh int tcp set global rsc=disabled >nul 2>&1
:: Desativa LSO v1/v2 e RSC via registro
:: CORRECAO: reg query retorna "HKEY_LOCAL_MACHINE", nao "HKLM" - findstr ajustado
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}" 2^>nul ^| findstr /i "HKEY_LOCAL_MACHINE"') do (
    reg add "%%i" /v "*LsoV1IPv4" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "*LsoV2IPv4" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "*LsoV2IPv6" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "*RscIPv4" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "*RscIPv6" /t REG_SZ /d "0" /f >nul 2>&1
)
:: Desativa Interrupt Moderation
powershell -ExecutionPolicy Bypass -NoProfile -Command "Get-NetAdapter -Physical | ForEach-Object { $name = $_.Name; Try { Set-NetAdapterAdvancedProperty -Name $name -RegistryKeyword '*InterruptModeration' -RegistryValue 0 -ErrorAction Stop } Catch {} }"
powershell -ExecutionPolicy Bypass -NoProfile -Command "$nicClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $nicClass -ErrorAction SilentlyContinue | ForEach-Object { $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue; if ($props.'*InterruptModeration' -ne $null) { Set-ItemProperty $_.PSPath -Name '*InterruptModeration' -Value 0 -ErrorAction SilentlyContinue } }"
exit

:revert
:: Reativa RSC e LSO ao padrao do Windows
powershell -NoProfile -Command "Get-NetAdapter -Physical | Enable-NetAdapterRsc -ErrorAction SilentlyContinue" >nul 2>&1
netsh int tcp set global rsc=enabled >nul 2>&1
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}" 2^>nul ^| findstr /i "HKEY_LOCAL_MACHINE"') do (
    reg delete "%%i" /v "*LsoV1IPv4" /f >nul 2>&1
    reg delete "%%i" /v "*LsoV2IPv4" /f >nul 2>&1
    reg delete "%%i" /v "*LsoV2IPv6" /f >nul 2>&1
    reg delete "%%i" /v "*RscIPv4" /f >nul 2>&1
    reg delete "%%i" /v "*RscIPv6" /f >nul 2>&1
)
:: Reativa Interrupt Moderation
powershell -ExecutionPolicy Bypass -NoProfile -Command "Get-NetAdapter -Physical | ForEach-Object { $name = $_.Name; Try { Set-NetAdapterAdvancedProperty -Name $name -RegistryKeyword '*InterruptModeration' -RegistryValue 1 -ErrorAction Stop } Catch {} }"
powershell -ExecutionPolicy Bypass -NoProfile -Command "$nicClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $nicClass -ErrorAction SilentlyContinue | ForEach-Object { $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue; if ($props.'*InterruptModeration' -ne $null) { Set-ItemProperty $_.PSPath -Name '*InterruptModeration' -Value 1 -ErrorAction SilentlyContinue } }"
exit
