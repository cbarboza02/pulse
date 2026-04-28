#Requires -Version 5.1
#------------------------------------------------------------------------------
# VERIFICADOR DE ESTADO - PULSEOS / PAINEL PULSE
#------------------------------------------------------------------------------
# Atualiza Documents\Painel Pulse\PulseState.json antes da abertura do Painel.
# Booleanos: "id": true/false.
# Perfis: "id": "perfil" quando um perfil real estiver ativo.
# Perfis padrão/padrao/false: gravados como false.

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

$RepoBaseUrl = "https://raw.githubusercontent.com/cbarboza02/pulse/main/Painel%20Pulse"

$DocPath = [Environment]::GetFolderPath('MyDocuments')
$StateDir = Join-Path $DocPath 'Painel Pulse'
$StatePath = Join-Path $StateDir 'PulseState.json'

$TempPanelDir = Join-Path $env:TEMP 'Painel Pulse'
$JsonDir = Join-Path $TempPanelDir 'json'
$CmdDir = Join-Path $TempPanelDir 'comandos'

if (-not (Test-Path -LiteralPath $StateDir)) {
    New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $CmdDir)) {
    New-Item -ItemType Directory -Path $CmdDir -Force | Out-Null
}

function Import-PulseState {
    $State = [ordered]@{}

    try {
        if (Test-Path -LiteralPath $StatePath) {
            $Content = Get-Content -LiteralPath $StatePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($Content)) {
                $Json = $Content | ConvertFrom-Json -ErrorAction Stop
                foreach ($Prop in $Json.PSObject.Properties) {
                    if ($Prop.Name -notlike '*_Value') {
                        $State[$Prop.Name] = $Prop.Value
                    }
                }
            }
        }
    } catch {}

    return $State
}

function Save-PulseState {
    param([hashtable]$State)

    try {
        $ordered = [ordered]@{}
        foreach ($key in ($State.Keys | Sort-Object)) {
            if ($key -notlike '*_Value') {
                $value = $State[$key]
                if ($value -is [string]) {
                    $norm = $value.Trim().ToLowerInvariant()
                    if ($norm -eq 'padrao' -or $norm -eq 'padrão' -or $norm -eq 'false' -or $norm.Length -eq 0) {
                        $ordered[$key] = $false
                    } else {
                        $ordered[$key] = $value.Trim()
                    }
                } else {
                    $ordered[$key] = $value
                }
            }
        }

        $ordered | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $StatePath -Encoding UTF8 -Force
    } catch {}
}

function Test-PulseDefaultValue {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
    $n = $Value.Trim().ToLowerInvariant()
    return ($n -eq 'padrao' -or $n -eq 'padrão' -or $n -eq 'false')
}

function Convert-RegPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $Path }

    $p = $Path.Trim().Trim('"')
    $p = $p -replace '/', '\'

    if ($p -match '(?i)^HKLM\\(.+)$') { return "HKLM:\$($Matches[1])" }
    if ($p -match '(?i)^HKEY_LOCAL_MACHINE\\(.+)$') { return "HKLM:\$($Matches[1])" }
    if ($p -match '(?i)^HKCU\\(.+)$') { return "HKCU:\$($Matches[1])" }
    if ($p -match '(?i)^HKEY_CURRENT_USER\\(.+)$') { return "HKCU:\$($Matches[1])" }
    if ($p -match '(?i)^HKCR\\(.+)$') { return "Registry::HKEY_CLASSES_ROOT\$($Matches[1])" }
    if ($p -match '(?i)^HKEY_CLASSES_ROOT\\(.+)$') { return "Registry::HKEY_CLASSES_ROOT\$($Matches[1])" }
    if ($p -match '(?i)^HKU\\(.+)$') { return "Registry::HKEY_USERS\$($Matches[1])" }
    if ($p -match '(?i)^HKEY_USERS\\(.+)$') { return "Registry::HKEY_USERS\$($Matches[1])" }

    return $p
}

function Get-RegValue {
    param([string]$Path,[string]$Name)
    try {
        $psPath = Convert-RegPath $Path
        if ($Name -eq '(Default)' -or [string]::IsNullOrWhiteSpace($Name)) {
            return (Get-Item -LiteralPath $psPath -ErrorAction Stop).GetValue('')
        }
        return (Get-ItemProperty -LiteralPath $psPath -Name $Name -ErrorAction Stop).$Name
    } catch { return $null }
}

function Test-RegValue {
    param([string]$Path,[string]$Name,$Expected,[string]$Type)

    $Current = Get-RegValue -Path $Path -Name $Name
    if ($null -eq $Current) { return $false }

    if ($Type -match 'DWORD|QWORD') {
        try {
            $expectedText = [string]$Expected
            if ($expectedText -match '^(?i)0x[0-9a-f]+$') {
                $expectedNum = [Convert]::ToInt64($expectedText, 16)
            } else {
                $expectedNum = [int64]$expectedText
            }
            return ([int64]$Current -eq $expectedNum)
        } catch { return $false }
    }

    return ([string]$Current -eq [string]$Expected)
}

function Test-RegMissing {
    param([string]$Path,[string]$Name)

    $Current = Get-RegValue -Path $Path -Name $Name
    return ($null -eq $Current)
}

function Test-All {
    param([scriptblock[]]$Checks)
    if ($null -eq $Checks -or $Checks.Count -eq 0) { return $false }
    foreach ($Check in $Checks) {
        try {
            if (-not (& $Check)) { return $false }
        } catch { return $false }
    }
    return $true
}

function Test-ServiceStartType {
    param([string]$Name,[string]$Expected)
    try {
        $svc = Get-Service -Name $Name -ErrorAction Stop
        return ($svc.StartType.ToString() -eq $Expected)
    } catch { return $false }
}

function Test-ServiceNotDisabled {
    param([string]$Name)
    try {
        $svc = Get-Service -Name $Name -ErrorAction Stop
        return ($svc.StartType.ToString() -ne 'Disabled')
    } catch { return $false }
}

function Test-TaskDisabled {
    param([string]$TaskPath,[string]$TaskName)
    try {
        $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop
        return ($task.State.ToString() -eq 'Disabled')
    } catch { return $false }
}

function Test-TaskEnabled {
    param([string]$TaskPath,[string]$TaskName)
    try {
        $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop
        return ($task.State.ToString() -ne 'Disabled')
    } catch { return $false }
}

function Test-ScheduledTaskExists {
    param([string]$TaskName)
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        return ($null -ne $task)
    } catch { return $false }
}

function Get-BcdText {
    try { return (bcdedit /enum '{current}' 2>$null | Out-String) } catch { return '' }
}

function Test-BcdSetting {
    param([string]$Name,[string]$ExpectedPattern)

    $txt = Get-BcdText
    if ([string]::IsNullOrWhiteSpace($txt)) { return $false }
    $line = ($txt -split "`r?`n" | Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\s+" } | Select-Object -First 1)
    if (-not $line) { return $false }
    return ($line -match $ExpectedPattern)
}

function Test-BcdSettingMissing {
    param([string]$Name)

    $txt = Get-BcdText
    if ([string]::IsNullOrWhiteSpace($txt)) { return $true }
    return (-not (($txt -split "`r?`n") | Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\s+" } | Select-Object -First 1))
}

function Test-MMAgentFlag {
    param([string]$Name,[bool]$Expected)

    try {
        $agent = Get-MMAgent
        return ([bool]$agent.$Name -eq $Expected)
    } catch { return $false }
}

function Get-AmdGpuClassKeys {
    $base = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
    try {
        return @(Get-ChildItem -Path $base -ErrorAction SilentlyContinue | Where-Object {
            $_.PSChildName -match '^\d{4}$' -and ((Get-ItemProperty $_.PSPath -Name 'ProviderName' -ErrorAction SilentlyContinue).ProviderName -match 'AMD|ATI')
        })
    } catch { return @() }
}

function Test-AmdGpuRegValue {
    param([string]$Name,$Expected)

    $keys = @(Get-AmdGpuClassKeys)
    if ($keys.Count -eq 0) { return $false }

    foreach ($key in $keys) {
        try {
            $cur = (Get-ItemProperty -Path $key.PSPath -Name $Name -ErrorAction Stop).$Name
            if ([int64]$cur -eq [int64]$Expected) { return $true }
        } catch {}
    }

    return $false
}

function Test-AmdGpuRegMissing {
    param([string]$Name)

    $keys = @(Get-AmdGpuClassKeys)
    if ($keys.Count -eq 0) { return $false }

    foreach ($key in $keys) {
        try {
            $cur = (Get-ItemProperty -Path $key.PSPath -Name $Name -ErrorAction SilentlyContinue).$Name
            if ($null -eq $cur) { return $true }
        } catch { return $true }
    }

    return $false
}

function Test-PnpRegValue {
    param([string]$Class,[string]$PathSuffix,[string]$Name,$Expected)

    try {
        $devices = @(Get-PnpDevice -Class $Class -Status OK -ErrorAction SilentlyContinue)
        if ($devices.Count -eq 0) { return $false }

        foreach ($dev in $devices) {
            if ($Class -eq 'USB' -and $dev.InstanceId -notmatch '^PCI') { continue }
            $path = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\$PathSuffix"
            if (Test-Path -LiteralPath $path) {
                $cur = (Get-ItemProperty -LiteralPath $path -Name $Name -ErrorAction SilentlyContinue).$Name
                if ($null -ne $cur -and [int64]$cur -eq [int64]$Expected) { return $true }
            }
        }
    } catch {}

    return $false
}

function Test-PowerCfgCurrentValue {
    param([string]$Subgroup,[string]$Setting,[int64]$Expected,[string]$Mode)

    try {
        $txt = powercfg /query SCHEME_CURRENT $Subgroup $Setting 2>$null | Out-String
        if ([string]::IsNullOrWhiteSpace($txt)) { return $false }

        $label = if ($Mode -eq 'DC') { 'Current DC Power Setting Index' } else { 'Current AC Power Setting Index' }
        $line = ($txt -split "`r?`n" | Where-Object { $_ -match [regex]::Escape($label) } | Select-Object -First 1)
        if (-not $line) { return $false }

        if ($line -match '0x([0-9a-fA-F]+)') {
            return ([Convert]::ToInt64($Matches[1], 16) -eq $Expected)
        }
    } catch {}

    return $false
}

function Test-ActivePowerPlanName {
    param([string]$Pattern)

    try {
        $txt = powercfg /getactivescheme 2>$null | Out-String
        return ($txt -match $Pattern)
    } catch { return $false }
}

function Get-BatSubfolder {
    param([string]$FileName)

    switch -Regex ($FileName) {
        '^geral_'     { return 'geral' }
        '^hw_'        { return 'hardware' }
        '^internet_'  { return 'internet' }
        '^restaurar_' { return 'restaurar' }
        '^reparar_'   { return 'reparar' }
        '^pulsemode_' { return 'pulsemode' }
        default       { return '' }
    }
}

$script:BatTextCache = @{}

function Get-PulseBatText {
    param([string]$FileName)

    if ([string]::IsNullOrWhiteSpace($FileName)) { return '' }
    if ($script:BatTextCache.ContainsKey($FileName)) { return $script:BatTextCache[$FileName] }

    $candidates = @(
        (Join-Path $CmdDir $FileName),
        (Join-Path $CmdDir (Join-Path (Get-BatSubfolder $FileName) $FileName))
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            $txt = Get-Content -LiteralPath $candidate -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            $script:BatTextCache[$FileName] = $txt
            return $txt
        }
    }

    $sub = Get-BatSubfolder $FileName
    if (-not [string]::IsNullOrWhiteSpace($sub)) {
        $url = "$RepoBaseUrl/comandos/$sub/$FileName"
        $dest = Join-Path $CmdDir $FileName
        try {
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop | Out-Null
            $txt = Get-Content -LiteralPath $dest -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            $script:BatTextCache[$FileName] = $txt
            return $txt
        } catch {}
    }

    $script:BatTextCache[$FileName] = ''
    return ''
}

function Split-PulseCommand {
    param([string]$Command)

    $result = [ordered]@{ FileName = ''; Param = '' }
    if ([string]::IsNullOrWhiteSpace($Command)) { return $result }

    $cmd = $Command.Trim()
    $lastSpace = $cmd.LastIndexOf(' ')
    if ($lastSpace -ge 0) {
        $path = $cmd.Substring(0, $lastSpace).Trim()
        $result.Param = $cmd.Substring($lastSpace + 1).Trim()
    } else {
        $path = $cmd
    }

    $path = $path.Replace('/','\')
    $result.FileName = Split-Path -Leaf $path
    return $result
}

function Get-BatBranchLines {
    param([string]$BatText,[string]$Param)

    if ([string]::IsNullOrWhiteSpace($BatText)) { return @() }

    $label = $Param
    foreach ($line in ($BatText -split "`r?`n")) {
        $m = [regex]::Match($line, 'if\s+/i\s+"%~1"=="([^"]+)"\s+goto\s+([A-Za-z0-9_\-]+)', 'IgnoreCase')
        if ($m.Success -and $m.Groups[1].Value.ToLowerInvariant() -eq $Param.ToLowerInvariant()) {
            $label = $m.Groups[2].Value
            break
        }
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $inside = $false

    foreach ($line in ($BatText -split "`r?`n")) {
        $labelMatch = [regex]::Match($line, '^\s*:([A-Za-z0-9_\-]+)\s*$')
        if ($labelMatch.Success) {
            if ($inside) { break }
            if ($labelMatch.Groups[1].Value.ToLowerInvariant() -eq $label.ToLowerInvariant()) {
                $inside = $true
            }
            continue
        }

        if ($inside) { $lines.Add($line) }
    }

    return @($lines)
}

function Get-RegChecksFromBatCommand {
    param([string]$Command)

    $split = Split-PulseCommand $Command
    if ([string]::IsNullOrWhiteSpace($split.FileName) -or [string]::IsNullOrWhiteSpace($split.Param)) { return @() }

    $batText = Get-PulseBatText -FileName $split.FileName
    $branchLines = Get-BatBranchLines -BatText $batText -Param $split.Param

    $checks = New-Object System.Collections.Generic.List[scriptblock]

    foreach ($line in $branchLines) {
        $trim = $line.Trim()
        if ($trim -notmatch '^(?i)reg\s+add\s+') { continue }

        $m = [regex]::Match($trim, '^reg\s+add\s+"([^"]+)"\s+(.+)$', 'IgnoreCase')
        if (-not $m.Success) { continue }

        $regPath = $m.Groups[1].Value
        $rest = $m.Groups[2].Value

        if ($rest -match '(?i)(%[A-Za-z0-9_]+%|\![A-Za-z0-9_]+\!)') { continue }

        $name = ''
        if ($rest -match '(?i)\s/ve(\s|$)') {
            $name = '(Default)'
        } else {
            $nameMatch = [regex]::Match($rest, '(?i)/v\s+(?:"([^"]+)"|([^/\s][^/]*?))\s+/(?:t|d|f)')
            if (-not $nameMatch.Success) { continue }
            if ($nameMatch.Groups[1].Success) { $name = $nameMatch.Groups[1].Value.Trim() }
            else { $name = $nameMatch.Groups[2].Value.Trim().Trim('"') }
        }

        $type = ''
        $typeMatch = [regex]::Match($rest, '(?i)/t\s+([A-Za-z0-9_]+)')
        if ($typeMatch.Success) { $type = $typeMatch.Groups[1].Value.Trim() }

        $data = ''
        $dataMatch = [regex]::Match($rest, '(?i)/d\s+("[^"]*"|[^/]\S*)')
        if ($dataMatch.Success) {
            $data = $dataMatch.Groups[1].Value.Trim()
            if ($data.StartsWith('"') -and $data.EndsWith('"')) {
                $data = $data.Substring(1, $data.Length - 2)
            }
        }

        $pathCopy = $regPath
        $nameCopy = $name
        $dataCopy = $data
        $typeCopy = $type

        $checks.Add({ Test-RegValue -Path $pathCopy -Name $nameCopy -Expected $dataCopy -Type $typeCopy }.GetNewClosure())
    }

    return @($checks)
}

function Test-CommandRegState {
    param([string]$Command)

    $checks = @(Get-RegChecksFromBatCommand -Command $Command)
    if ($checks.Count -eq 0) { return $null }
    return [bool](Test-All $checks)
}

function Get-ManualProfileState {
    param([string]$Id)

    switch ($Id) {
        'hardware.mosaicos' {
            if ((Test-AmdGpuRegValue 'TessellationMode' 2) -and (Test-AmdGpuRegValue 'MaxTessFactor' 1)) { return 'off' }
            if ((Test-AmdGpuRegValue 'TessellationMode' 1) -and (Test-AmdGpuRegValue 'MaxTessFactor' 16)) { return '16x' }
            if ((Test-AmdGpuRegValue 'TessellationMode' 1) -and (Test-AmdGpuRegValue 'MaxTessFactor' 32)) { return '32x' }
            return $false
        }
        'pulsemode.amd-flip-queue-size' {
            if (Test-AmdGpuRegValue 'TFQ' 1) { return 'competitivo' }
            if (Test-AmdGpuRegValue 'TFQ' 2) { return 'equilibrado' }
            return $false
        }
    }

    return $null
}

function Test-ManualBooleanState {
    param([string]$Id)

    switch ($Id) {
        'geral.sleep-timeout' {
            return (
                (Test-PowerCfgCurrentValue 'SUB_SLEEP' 'STANDBYIDLE' 0 'AC') -and
                (Test-PowerCfgCurrentValue 'SUB_SLEEP' 'STANDBYIDLE' 0 'DC') -and
                (Test-PowerCfgCurrentValue 'SUB_SLEEP' 'HIBERNATEIDLE' 0 'AC') -and
                (Test-PowerCfgCurrentValue 'SUB_SLEEP' 'HIBERNATEIDLE' 0 'DC') -and
                (Test-PowerCfgCurrentValue 'SUB_VIDEO' 'VIDEOIDLE' 0 'AC') -and
                (Test-PowerCfgCurrentValue 'SUB_VIDEO' 'VIDEOIDLE' 0 'DC') -and
                (Test-PowerCfgCurrentValue 'SUB_DISK' 'DISKIDLE' 0 'AC') -and
                (Test-PowerCfgCurrentValue 'SUB_DISK' 'DISKIDLE' 0 'DC')
            )
        }
        'geral.indexacao-pesquisa' {
            return ((Test-ServiceStartType 'WSearch' 'Disabled') -and (Test-TaskDisabled '\Microsoft\Windows\Shell\' 'IndexerAutomaticMaintenance'))
        }
        'geral.plano-energia' {
            return (Test-ActivePowerPlanName 'Ultimate|Desempenho\s+Maximo|Desempenho\s+Máximo')
        }
        'hardware.max-desempenho' {
            return ((Test-AmdGpuRegValue 'EnableULPS' 0) -and (Test-AmdGpuRegValue 'PP_DisablePowerContainment' 1) -and (Test-AmdGpuRegValue 'PP_Force3DPerformanceMode' 1))
        }
        'hardware.buffer-triplo' {
            return (Test-AmdGpuRegValue 'TF' 0)
        }
        'hardware.formato-superficie' {
            return ((Test-AmdGpuRegValue 'SurfaceFormatOpt' 1) -and (Test-AmdGpuRegValue 'DalEnableSFO' 1))
        }
        'hardware.cpu-max-desempenho' {
            return (
                (Test-PowerCfgCurrentValue 'SUB_PROCESSOR' 'PROCTHROTTLEMIN' 100 'AC') -and
                (Test-PowerCfgCurrentValue 'SUB_PROCESSOR' 'PROCTHROTTLEMAX' 100 'AC') -and
                (Test-PowerCfgCurrentValue 'SUB_PROCESSOR' 'PROCTHROTTLEMIN' 100 'DC') -and
                (Test-PowerCfgCurrentValue 'SUB_PROCESSOR' 'PROCTHROTTLEMAX' 100 'DC') -and
                (Test-PowerCfgCurrentValue 'SUB_PROCESSOR' 'PERFBOOSTMODE' 2 'AC') -and
                (Test-PowerCfgCurrentValue 'SUB_PROCESSOR' 'PERFBOOSTMODE' 2 'DC')
            )
        }
        'hardware.compressao-memoria' {
            return (Test-MMAgentFlag 'MemoryCompression' $false)
        }
        'hardware.page-combining' {
            return (Test-MMAgentFlag 'PageCombining' $false)
        }
        'pulsemode.usb-msi' {
            return ((Test-PnpRegValue 'USB' 'Device Parameters\Interrupt Management\MessageSignaledInterruptProperties' 'MSISupported' 1) -and (Test-PnpRegValue 'USB' 'Device Parameters\Interrupt Management\Affinity Policy' 'DevicePriority' 3))
        }
        'pulsemode.gpu-msi' {
            return ((Test-PnpRegValue 'Display' 'Device Parameters\Interrupt Management\MessageSignaledInterruptProperties' 'MSISupported' 1) -and (Test-PnpRegValue 'Display' 'Device Parameters\Interrupt Management\Affinity Policy' 'DevicePriority' 3))
        }
        'pulsemode.dynamic-tick' {
            return ((Test-BcdSetting 'disabledynamictick' 'Yes|yes|true') -and (Test-BcdSetting 'tscsyncpolicy' 'Enhanced'))
        }
        'pulsemode.windows-update' {
            return ((Test-ServiceStartType 'UsoSvc' 'Disabled') -or (Test-RegValue 'HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc' 'Start' 4 'REG_DWORD') -or (Test-ScheduledTaskExists 'Pulse Mode - Otimizar Windows Update'))
        }
        'restaurar.impressao' {
            return ((Test-ServiceNotDisabled 'Spooler') -and (Test-ServiceNotDisabled 'stisvc'))
        }
        'restaurar.virtualizacao-hyper-v' {
            return (Test-BcdSetting 'hypervisorlaunchtype' 'Auto|auto')
        }
        'restaurar.configuracoes-inicio' {
            return (
                (Test-RegMissing 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'SettingsPageVisibility') -and
                (Test-RegMissing 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'SettingsPageVisibility')
            )
        }
    }

    return $null
}

function Get-JsonItems {
    $items = New-Object System.Collections.Generic.List[object]

    try {
        if (-not (Test-Path -LiteralPath $JsonDir)) { return @() }

        foreach ($file in Get-ChildItem -LiteralPath $JsonDir -Filter 'pulse_*.json' -File -ErrorAction SilentlyContinue) {
            $raw = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ([string]::IsNullOrWhiteSpace($raw)) { continue }

            try {
                $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
                foreach ($item in @($parsed)) {
                    if ($null -ne $item.Id -and -not [string]::IsNullOrWhiteSpace([string]$item.Id)) {
                        $items.Add($item)
                    }
                }
            } catch {}
        }
    } catch {}

    return @($items)
}

$State = Import-PulseState
$Items = @(Get-JsonItems)

foreach ($Item in $Items) {
    $id = [string]$Item.Id
    if ([string]::IsNullOrWhiteSpace($id)) { continue }

    $hasValues = ($null -ne $Item.Values -and @($Item.Values).Count -gt 0)

    if ($hasValues) {
        $manualProfile = Get-ManualProfileState -Id $id
        if ($null -ne $manualProfile) {
            $State[$id] = $manualProfile
            continue
        }

        $detectedProfile = $false

        foreach ($value in @($Item.Values)) {
            $param = [string]$value.Param
            if (Test-PulseDefaultValue -Value $param) { continue }

            $cmd = [string]$value.Command
            $dynamic = Test-CommandRegState -Command $cmd
            if ($null -ne $dynamic -and [bool]$dynamic) {
                $detectedProfile = $param
                break
            }
        }

        $State[$id] = $detectedProfile
        continue
    }

    $manual = Test-ManualBooleanState -Id $id
    if ($null -ne $manual) {
        $State[$id] = [bool]$manual
        continue
    }

    $applyCmd = [string]$Item.Apply
    $dynamicState = Test-CommandRegState -Command $applyCmd

    if ($null -ne $dynamicState) {
        $State[$id] = [bool]$dynamicState
    } else {
        # Sem verificação confiável disponível: não marca como ativo por segurança.
        $State[$id] = $false
    }
}

Save-PulseState -State $State
exit 0
