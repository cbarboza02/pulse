@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa Triple Buffering no driver AMD (TF = Triple Buffering flag)
:: Triple Buffering pode aumentar o consumo de VRAM e adicionar latência de input
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Set-ItemProperty $_.PSPath -Name 'TF' -Value 0 -Type DWord -EA SilentlyContinue } }"
exit

:revert
:: Reativa Triple Buffering (padrão do driver AMD)
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Remove-ItemProperty $_.PSPath -Name 'TF' -EA SilentlyContinue } }"
exit
