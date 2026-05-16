@echo off
:: AMD Flip Queue Size (TFQ)
:: auto      = Automático (padrão AMD)
:: equilibrado = 2 frames
:: competitivo = 1 frame
if /i "%~1"=="auto"        goto auto
if /i "%~1"=="equilibrado" goto equilibrado
if /i "%~1"=="competitivo" goto competitivo
exit

:auto
:: Flip Queue Size - Automático (deixa o AMD decidir)
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Remove-ItemProperty $_.PSPath -Name 'TFQ' -EA SilentlyContinue } }"
exit

:equilibrado
:: Flip Queue Size = 2 (Equilibrado - balanceia latência e suavidade)
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Set-ItemProperty $_.PSPath -Name 'TFQ' -Value 2 -Type DWord -EA SilentlyContinue } }"
exit

:competitivo
:: Flip Queue Size = 1 (Competitivo - menor latência possível)
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Set-ItemProperty $_.PSPath -Name 'TFQ' -Value 1 -Type DWord -EA SilentlyContinue } }"
exit
