@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Ativa Surface Format Optimization (SFO) da AMD
:: Permite que o driver selecione o formato de superfície mais eficiente para cada textura
:: Reduz uso de VRAM e melhora throughput de texturização
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Set-ItemProperty $_.PSPath -Name 'SurfaceFormatOpt' -Value 1 -Type DWord -EA SilentlyContinue; Set-ItemProperty $_.PSPath -Name 'DalEnableSFO' -Value 1 -Type DWord -EA SilentlyContinue } }"
exit

:revert
:: Remove otimização de formato de superfície AMD (volta ao padrão)
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Remove-ItemProperty $_.PSPath -Name 'SurfaceFormatOpt' -EA SilentlyContinue; Remove-ItemProperty $_.PSPath -Name 'DalEnableSFO' -EA SilentlyContinue } }"
exit
