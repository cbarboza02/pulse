@echo off
:: AMD Shader Cache
:: amdoptm  = AMD Otimizado (driver decide quando usar cache)
:: alwayson = Sempre Ligado (cache sempre ativo)
if /i "%~1"=="amdoptm"  goto amdoptm
if /i "%~1"=="alwayson" goto alwayson
exit

:amdoptm
:: Shader Cache - AMD Otimizado (comportamento gerenciado pelo driver)
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Set-ItemProperty $_.PSPath -Name 'ShaderCache' -Value 2 -Type DWord -EA SilentlyContinue } }"
:: Shader Cache via Direct3D
reg add "HKLM\SOFTWARE\Microsoft\Direct3D" /v "ShaderCacheEnabled" /t REG_DWORD /d 1 /f
exit

:alwayson
:: Shader Cache - Sempre Ligado (cache nunca é descartado)
powershell -NoProfile -Command "$gpuClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $gpuClass -EA SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $pv = (Get-ItemProperty $_.PSPath -Name 'ProviderName' -EA SilentlyContinue).ProviderName; if ($pv -match 'AMD|ATI') { Set-ItemProperty $_.PSPath -Name 'ShaderCache' -Value 1 -Type DWord -EA SilentlyContinue } }"
:: Shader Cache via Direct3D
reg add "HKLM\SOFTWARE\Microsoft\Direct3D" /v "ShaderCacheEnabled" /t REG_DWORD /d 1 /f
exit
