@echo off
:: AMD Tessellation (Mosaicos)
:: amdoptm    = AMD Otimizado (driver decide o nível ideal)
:: off        = Desativado
:: 16x        = Forçar limite de 16x
:: 32x        = Forçar limite de 32x
:: revert     = Remove overrides e restaura ao padrão do driver
if /i "%~1"=="amdoptm" goto amdoptm
if /i "%~1"=="off"     goto off
if /i "%~1"=="16x"     goto 16x
if /i "%~1"=="32x"     goto 32x
if /i "%~1"=="revert"  goto revert
exit

:amdoptm
:: Tessellation - AMD Otimizado (driver gerencia automaticamente)
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Set-ItemProperty $_.PSPath -Name 'TessellationMode' -Value 0 -Type DWord -EA SilentlyContinue; Set-ItemProperty $_.PSPath -Name 'MaxTessFactor' -Value 0 -Type DWord -EA SilentlyContinue } }"
exit

:off
:: Tessellation - Desativado (sem processamento de mosaicos, MaxTessFactor 1 = 1x = nenhuma subdivisao)
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Set-ItemProperty $_.PSPath -Name 'TessellationMode' -Value 2 -Type DWord -EA SilentlyContinue; Set-ItemProperty $_.PSPath -Name 'MaxTessFactor' -Value 1 -Type DWord -EA SilentlyContinue } }"
exit

:16x
:: Tessellation - Limitar a 16x (melhora desempenho vs qualidade visual minima)
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Set-ItemProperty $_.PSPath -Name 'TessellationMode' -Value 1 -Type DWord -EA SilentlyContinue; Set-ItemProperty $_.PSPath -Name 'MaxTessFactor' -Value 16 -Type DWord -EA SilentlyContinue } }"
exit

:32x
:: Tessellation - Limitar a 32x
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Set-ItemProperty $_.PSPath -Name 'TessellationMode' -Value 1 -Type DWord -EA SilentlyContinue; Set-ItemProperty $_.PSPath -Name 'MaxTessFactor' -Value 32 -Type DWord -EA SilentlyContinue } }"
exit

:revert
:: Remove overrides — driver volta ao comportamento padrão
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Remove-ItemProperty $_.PSPath -Name 'TessellationMode' -EA SilentlyContinue; Remove-ItemProperty $_.PSPath -Name 'MaxTessFactor' -EA SilentlyContinue } }"
exit
