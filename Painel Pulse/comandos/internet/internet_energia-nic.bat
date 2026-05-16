@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa Economia de Energia da Placa de Rede
powershell -NoProfile -Command "Get-NetAdapter | ForEach-Object { Disable-NetAdapterPowerManagement -Name $_.Name -ErrorAction SilentlyContinue }" >nul 2>&1
powershell -NoProfile -Command "Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | Where-Object { $_.InstanceName -match 'NET' } | ForEach-Object { $_.Enable = $false; $_.Put() }" >nul 2>&1
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}" 2^>nul ^| findstr /i "HKEY_LOCAL_MACHINE"') do (
    reg add "%%i" /v "PnPCapabilities" /t REG_DWORD /d 24 /f >nul 2>&1
    reg add "%%i" /v "*EEE" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "EEE" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "EnablePME" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "GreenEthernet" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "ULPMode" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "AdvancedEEE" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "EnableGreenEthernet" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "EnableSavePowerNow" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "bLocalPower" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "PowerSavingMode" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "S5WakeOnLan" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "WakeOnLink" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "WakeOnMagicPacket" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "WakeOnPattern" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "%%i" /v "DeviceSleepOnDisconnect" /t REG_SZ /d "0" /f >nul 2>&1
)
exit

:revert
:: Restaura o gerenciamento de energia das NICs ao padrao do Windows
powershell -NoProfile -Command "Get-NetAdapter | ForEach-Object { Enable-NetAdapterPowerManagement -Name $_.Name -ErrorAction SilentlyContinue }" >nul 2>&1
:: CORRECAO: re-ativa via WMI, espelhando o que o apply desativou
powershell -NoProfile -Command "Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | Where-Object { $_.InstanceName -match 'NET' } | ForEach-Object { $_.Enable = $true; $_.Put() }" >nul 2>&1
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}" 2^>nul ^| findstr /i "HKEY_LOCAL_MACHINE"') do (
    reg delete "%%i" /v "PnPCapabilities" /f >nul 2>&1
    reg delete "%%i" /v "*EEE" /f >nul 2>&1
    reg delete "%%i" /v "EEE" /f >nul 2>&1
    reg delete "%%i" /v "EnablePME" /f >nul 2>&1
    reg delete "%%i" /v "GreenEthernet" /f >nul 2>&1
    reg delete "%%i" /v "ULPMode" /f >nul 2>&1
    reg delete "%%i" /v "AdvancedEEE" /f >nul 2>&1
    reg delete "%%i" /v "EnableGreenEthernet" /f >nul 2>&1
    reg delete "%%i" /v "EnableSavePowerNow" /f >nul 2>&1
    reg delete "%%i" /v "bLocalPower" /f >nul 2>&1
    reg delete "%%i" /v "PowerSavingMode" /f >nul 2>&1
    reg delete "%%i" /v "S5WakeOnLan" /f >nul 2>&1
    reg delete "%%i" /v "WakeOnLink" /f >nul 2>&1
    reg delete "%%i" /v "WakeOnMagicPacket" /f >nul 2>&1
    reg delete "%%i" /v "WakeOnPattern" /f >nul 2>&1
    reg delete "%%i" /v "DeviceSleepOnDisconnect" /f >nul 2>&1
)
exit
