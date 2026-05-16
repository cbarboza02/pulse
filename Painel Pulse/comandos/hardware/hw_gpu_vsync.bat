@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa VSync globalmente no driver AMD
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Set-ItemProperty $_.PSPath -Name 'IsVSyncEnabled' -Value 0 -Type DWord -EA SilentlyContinue; Set-ItemProperty $_.PSPath -Name 'VSyncEnabled' -Value 0 -Type DWord -EA SilentlyContinue; Set-ItemProperty $_.PSPath -Name 'Wait4VBlank' -Value 0 -Type DWord -EA SilentlyContinue } }"
:: Desativa VSync via Direct3D (para aplicações D3D)
reg add "HKCU\Software\Microsoft\Direct3D" /v "DisableVSync" /t REG_DWORD /d 1 /f
:: Restaura o VSync Idle Timeout padrão do driver AMD
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Remove-ItemProperty $_.PSPath -Name 'VSyncIdleTimeout' -EA SilentlyContinue } }"
exit

:revert
:: Restaura VSync para o padrão do driver AMD
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Remove-ItemProperty $_.PSPath -Name 'IsVSyncEnabled' -EA SilentlyContinue; Remove-ItemProperty $_.PSPath -Name 'VSyncEnabled' -EA SilentlyContinue; Remove-ItemProperty $_.PSPath -Name 'Wait4VBlank' -EA SilentlyContinue } }"
reg delete "HKCU\Software\Microsoft\Direct3D" /v "DisableVSync" /f 2>nul
:: Desativa o VSync Idle Timeout da AMD
:: Esse timeout faz a GPU reduzir clocks quando o frame rate fica abaixo de um limiar com VSync ativo
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Set-ItemProperty $_.PSPath -Name 'VSyncIdleTimeout' -Value 0 -Type DWord -EA SilentlyContinue } }"
exit
