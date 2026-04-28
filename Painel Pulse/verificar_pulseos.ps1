#Requires -Version 5.1
#------------------------------------------------------------------------------
# VERIFICADOR DE ESTADO - PULSEOS / PAINEL PULSE
#------------------------------------------------------------------------------
# Atualiza Documents\Painel Pulse\PulseState.json antes da abertura do Painel.
# Este arquivo NAO baixa .bat: as verificacoes ficam incorporadas em $PulseChecks.
# Booleanos: "id": true/false.
# Perfis: "id": "perfil" quando um perfil real estiver ativo.
# Estados padrao/padrão/false/vazio sao gravados como false.

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

$DocPath = [Environment]::GetFolderPath('MyDocuments')
$StateDir = Join-Path $DocPath 'Painel Pulse'
$StatePath = Join-Path $StateDir 'PulseState.json'
if (-not (Test-Path -LiteralPath $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }

function Import-PulseState {
    $State = [ordered]@{}
    try {
        if (Test-Path -LiteralPath $StatePath) {
            $Content = Get-Content -LiteralPath $StatePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($Content)) {
                $Json = $Content | ConvertFrom-Json -ErrorAction Stop
                foreach ($Prop in $Json.PSObject.Properties) {
                    if ($Prop.Name -notlike '*_Value') { $State[$Prop.Name] = $Prop.Value }
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
                    if ($norm -eq 'padrao' -or $norm -eq 'padrão' -or $norm -eq 'false' -or $norm.Length -eq 0) { $ordered[$key] = $false }
                    else { $ordered[$key] = $value.Trim() }
                } else { $ordered[$key] = $value }
            }
        }
        $ordered | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $StatePath -Encoding UTF8 -Force
    } catch {}
}
function Test-PulseDefaultStateName {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
    $n = $Value.Trim().ToLowerInvariant()
    return ($n -eq 'padrao' -or $n -eq 'padrão' -or $n -eq 'false' -or $n -eq 'revert')
}
function Convert-RegPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $Path }
    $p = $Path.Trim().Trim('"') -replace '/', '\'
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
        if ($Name -eq '(Default)' -or [string]::IsNullOrWhiteSpace($Name)) { return (Get-Item -LiteralPath $psPath -ErrorAction Stop).GetValue('') }
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
            if ($expectedText -match '^(?i)0x[0-9a-f]+$') { $expectedNum = [Convert]::ToInt64($expectedText, 16) } else { $expectedNum = [int64]$expectedText }
            return ([int64]$Current -eq $expectedNum)
        } catch { return $false }
    }
    if ($Type -match 'BINARY') {
        try {
            $expectedHex = ([string]$Expected).ToLowerInvariant() -replace '[^0-9a-f]', ''
            if ($Current -is [byte[]]) { return ((($Current | ForEach-Object { $_.ToString('x2') }) -join '').ToLowerInvariant() -eq $expectedHex) }
            return ((([string]$Current).ToLowerInvariant() -replace '[^0-9a-f]', '') -eq $expectedHex)
        } catch { return $false }
    }
    return ([string]$Current -eq [string]$Expected)
}
function Test-RegMissing { param([string]$Path,[string]$Name) return ($null -eq (Get-RegValue -Path $Path -Name $Name)) }
function Test-RegKeyMissing { param([string]$Path) try { return (-not (Test-Path -LiteralPath (Convert-RegPath $Path))) } catch { return $false } }
function Test-ServiceStartType { param([string]$Name,[string]$Expected) try { $svc = Get-Service -Name $Name -ErrorAction Stop; return ($svc.StartType.ToString() -eq $Expected) } catch { return $false } }
function Test-ServiceNotDisabled { param([string]$Name) try { $svc = Get-Service -Name $Name -ErrorAction Stop; return ($svc.StartType.ToString() -ne 'Disabled') } catch { return $false } }
function Split-TaskFullName { param([string]$Task) $t = ($Task -replace '/', '\').Trim('\'); $idx = $t.LastIndexOf('\'); if ($idx -lt 0) { return @{ Path='\'; Name=$t } }; return @{ Path=('\' + $t.Substring(0,$idx) + '\'); Name=$t.Substring($idx+1) } }
function Test-TaskState { param([string]$Task,[string]$Expected) try { $parts = Split-TaskFullName $Task; $taskObj = Get-ScheduledTask -TaskPath $parts.Path -TaskName $parts.Name -ErrorAction Stop; if ($Expected -eq 'Disabled') { return ($taskObj.State.ToString() -eq 'Disabled') }; return ($taskObj.State.ToString() -ne 'Disabled') } catch { return $false } }
function Test-ScheduledTaskExists { param([string]$Task) try { $parts = Split-TaskFullName $Task; $taskObj = Get-ScheduledTask -TaskPath $parts.Path -TaskName $parts.Name -ErrorAction Stop; return ($null -ne $taskObj) } catch { return $false } }
function Get-BcdText { try { return (bcdedit /enum '{current}' 2>$null | Out-String) } catch { return '' } }
function Test-BcdSetting { param([string]$Name,[string]$Expected) $txt = Get-BcdText; if ([string]::IsNullOrWhiteSpace($txt)) { return $false }; $line = ($txt -split "`r?`n" | Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\s+" } | Select-Object -First 1); if (-not $line) { return $false }; $pat = [regex]::Escape([string]$Expected); if ($Expected -match '^(?i)yes|true$') { $pat='Yes|yes|true' } elseif ($Expected -match '^(?i)no|false$') { $pat='No|no|false' } elseif ($Expected -match '^(?i)auto$') { $pat='Auto|auto' }; return ($line -match $pat) }
function Test-BcdSettingMissing { param([string]$Name) $txt = Get-BcdText; if ([string]::IsNullOrWhiteSpace($txt)) { return $true }; return (-not (($txt -split "`r?`n") | Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\s+" } | Select-Object -First 1)) }
function Test-MMAgentFlag { param([string]$Name,[bool]$Expected) try { $agent = Get-MMAgent; return ([bool]$agent.$Name -eq $Expected) } catch { return $false } }
function Get-AmdGpuClassKeys { $base = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'; try { return @(Get-ChildItem -Path $base -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' -and ((Get-ItemProperty $_.PSPath -Name 'ProviderName' -ErrorAction SilentlyContinue).ProviderName -match 'AMD|ATI') }) } catch { return @() } }
function Test-AmdGpuRegValue { param([string]$Name,$Expected) $keys = @(Get-AmdGpuClassKeys); if ($keys.Count -eq 0) { return $false }; foreach ($key in $keys) { try { $cur = (Get-ItemProperty -Path $key.PSPath -Name $Name -ErrorAction Stop).$Name; if ([int64]$cur -eq [int64]$Expected) { return $true } } catch {} }; return $false }
function Test-AmdGpuRegMissing { param([string]$Name) $keys = @(Get-AmdGpuClassKeys); if ($keys.Count -eq 0) { return $false }; foreach ($key in $keys) { try { $cur = (Get-ItemProperty -Path $key.PSPath -Name $Name -ErrorAction SilentlyContinue).$Name; if ($null -eq $cur) { return $true } } catch { return $true } }; return $false }
function Get-NicClassKeys { $base = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}'; try { return @(Get-ChildItem -Path $base -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' }) } catch { return @() } }
function Test-NicClassRegValue { param([string]$Name,$Expected) $keys = @(Get-NicClassKeys); if ($keys.Count -eq 0) { return $false }; foreach ($key in $keys) { try { $cur = (Get-ItemProperty -Path $key.PSPath -Name $Name -ErrorAction Stop).$Name; if ([string]$cur -eq [string]$Expected) { return $true }; try { if ([int64]$cur -eq [int64]$Expected) { return $true } } catch {} } catch {} }; return $false }
function Test-PnpRegValue { param([string]$Class,[string]$PathSuffix,[string]$Name,$Expected) try { $devices = @(Get-PnpDevice -Class $Class -Status OK -ErrorAction SilentlyContinue); if ($devices.Count -eq 0) { return $false }; foreach ($dev in $devices) { if ($Class -eq 'USB' -and $dev.InstanceId -notmatch '^PCI') { continue }; $path = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\$PathSuffix"; if (Test-Path -LiteralPath $path) { $cur = (Get-ItemProperty -LiteralPath $path -Name $Name -ErrorAction SilentlyContinue).$Name; if ($null -ne $cur -and [int64]$cur -eq [int64]$Expected) { return $true } } } } catch {}; return $false }
function Test-PowerCfgCurrentValue { param([string]$Subgroup,[string]$Setting,[int64]$Expected,[string]$Mode) try { $txt = powercfg /query SCHEME_CURRENT $Subgroup $Setting 2>$null | Out-String; if ([string]::IsNullOrWhiteSpace($txt)) { return $false }; $label = if ($Mode -eq 'DC') { 'Current DC Power Setting Index' } else { 'Current AC Power Setting Index' }; $line = ($txt -split "`r?`n" | Where-Object { $_ -match [regex]::Escape($label) } | Select-Object -First 1); if (-not $line) { return $false }; if ($line -match '0x([0-9a-fA-F]+)') { return ([Convert]::ToInt64($Matches[1], 16) -eq $Expected) } } catch {}; return $false }
function Test-ActivePowerPlanName { param([string]$Pattern) try { $txt = powercfg /getactivescheme 2>$null | Out-String; return ($txt -match $Pattern) } catch { return $false } }
function Test-HibernationState { param([string]$Expected) try { $enabled = (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'HibernateEnabled' -ErrorAction SilentlyContinue).HibernateEnabled; if ($Expected -eq 'Off') { return ([int64]$enabled -eq 0) }; if ($Expected -eq 'On') { return ([int64]$enabled -ne 0) } } catch {}; return $false }
function Test-FsutilBehavior { param([string]$Name,$Expected) try { $txt = fsutil behavior query $Name 2>$null | Out-String; if ($txt -match '=\s*([0-9]+)') { return ([int64]$Matches[1] -eq [int64]$Expected) } } catch {}; return $false }
function Test-PulseCheck {
    param([hashtable]$Check)
    switch ([string]$Check.Type) {
        'RegValue' { return (Test-RegValue -Path $Check.Path -Name $Check.Name -Expected $Check.Expected -Type $Check.RegType) }
        'RegMissing' { return (Test-RegMissing -Path $Check.Path -Name $Check.Name) }
        'RegKeyMissing' { return (Test-RegKeyMissing -Path $Check.Path) }
        'ServiceStartType' { return (Test-ServiceStartType -Name $Check.Name -Expected $Check.Expected) }
        'ServiceNotDisabled' { return (Test-ServiceNotDisabled -Name $Check.Name) }
        'TaskState' { return (Test-TaskState -Task $Check.Task -Expected $Check.Expected) }
        'ScheduledTaskExists' { return (Test-ScheduledTaskExists -Task $Check.Task) }
        'BcdValue' { return (Test-BcdSetting -Name $Check.Name -Expected $Check.Expected) }
        'BcdMissing' { return (Test-BcdSettingMissing -Name $Check.Name) }
        'MMAgentFlag' { return (Test-MMAgentFlag -Name $Check.Name -Expected ([bool]$Check.Expected)) }
        'AmdGpuRegValue' { return (Test-AmdGpuRegValue -Name $Check.Name -Expected $Check.Expected) }
        'AmdGpuRegMissing' { return (Test-AmdGpuRegMissing -Name $Check.Name) }
        'NicClassRegValue' { return (Test-NicClassRegValue -Name $Check.Name -Expected $Check.Expected) }
        'PnpRegValue' { return (Test-PnpRegValue -Class $Check.Class -PathSuffix $Check.PathSuffix -Name $Check.Name -Expected $Check.Expected) }
        'PowerCfgValue' { return (Test-PowerCfgCurrentValue -Subgroup $Check.Subgroup -Setting $Check.Setting -Expected ([int64]$Check.Expected) -Mode $Check.Mode) }
        'ActivePowerPlan' { return (Test-ActivePowerPlanName -Pattern $Check.Pattern) }
        'Hibernation' { return (Test-HibernationState -Expected $Check.Expected) }
        'FsutilBehavior' { return (Test-FsutilBehavior -Name $Check.Name -Expected $Check.Expected) }
        default { return $false }
    }
}
function Test-PulseCheckList { param([object[]]$Checks) if ($null -eq $Checks -or $Checks.Count -eq 0) { return $false }; foreach ($Check in @($Checks)) { try { if (-not (Test-PulseCheck -Check $Check)) { return $false } } catch { return $false } }; return $true }

$PulseChecks = [ordered]@{
    'geral.apps-segundo-plano' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Name = 'GlobalUserDisabled'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'BackgroundAppGlobalToggle'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'; Name = 'LetAppsRunInBackground'; Expected = '2'; RegType = 'REG_DWORD' }
        )
    }
    'geral.manutencao-automatica' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance'; Name = 'MaintenanceDisabled'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'TaskState'; Task = 'Microsoft\Windows\TaskScheduler\Regular Maintenance'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'Microsoft\Windows\TaskScheduler\Maintenance Configurator'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'Microsoft\Windows\Diagnosis\Scheduled'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'Microsoft\Windows\DiskFootprint\Diagnostics'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'Microsoft\Windows\WDI\ResolutionHost'; Expected = 'Disabled' }
        )
    }
    'geral.plano-energia' = [ordered]@{
        'apply' = @(
            @{ Type = 'ActivePowerPlan'; Pattern = 'Ultimate|Desempenho\s+Maximo|Desempenho\s+Máximo' }
        )
    }
    'geral.sleep-timeout' = [ordered]@{
        'apply' = @(
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_SLEEP'; Setting = 'STANDBYIDLE'; Expected = 0; Mode = 'AC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_SLEEP'; Setting = 'STANDBYIDLE'; Expected = 0; Mode = 'DC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_SLEEP'; Setting = 'HIBERNATEIDLE'; Expected = 0; Mode = 'AC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_SLEEP'; Setting = 'HIBERNATEIDLE'; Expected = 0; Mode = 'DC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_VIDEO'; Setting = 'VIDEOIDLE'; Expected = 0; Mode = 'AC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_VIDEO'; Setting = 'VIDEOIDLE'; Expected = 0; Mode = 'DC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_DISK'; Setting = 'DISKIDLE'; Expected = 0; Mode = 'AC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_DISK'; Setting = 'DISKIDLE'; Expected = 0; Mode = 'DC' }
        )
    }
    'geral.hibernacao' = [ordered]@{
        'apply' = @(
            @{ Type = 'Hibernation'; Expected = 'Off' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_SLEEP'; Setting = 'HYBRIDSLEEP'; Expected = 0; Mode = 'AC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_SLEEP'; Setting = 'HYBRIDSLEEP'; Expected = 0; Mode = 'DC' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name = 'HiberbootEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power'; Name = 'HibernateEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power'; Name = 'HibernateEnabledDefault'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'geral.economia-energia' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\USB'; Name = 'DisableSelectiveSuspend'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\usbhub\Parameters'; Name = 'DisableSelectiveSuspend'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = '501a4d13-42af-4429-9fd1-a8218c268e20'; Setting = 'ee12f906-d277-404b-b6da-e5fa1a576df5'; Expected = 0; Mode = 'AC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = '501a4d13-42af-4429-9fd1-a8218c268e20'; Setting = 'ee12f906-d277-404b-b6da-e5fa1a576df5'; Expected = 0; Mode = 'DC' }
        )
    }
    'geral.estimativa-energia' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power'; Name = 'EnergyEstimationEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power'; Name = 'EnergyEstimationDisabled'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power'; Name = 'UserBatteryDischargeEstimator'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power'; Name = 'EEEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power'; Name = 'SleepStudyEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Power\PowerSettings'; Name = 'EnergyEstimationEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Power\PowerSettings'; Name = 'EventProcessingEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'TaskState'; Task = 'Microsoft\Windows\Power Efficiency Diagnostics\SleepStudy'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'Microsoft\Windows\Power Efficiency Diagnostics\Calibration'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'Microsoft\Windows\Power Efficiency Diagnostics\BackgroundEnergyDiagnostics'; Expected = 'Disabled' }
            @{ Type = 'ServiceStartType'; Name = 'SensrSvc'; Expected = 'Disabled' }
        )
    }
    'geral.atraso-windows' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'WaitToKillAppTimeout'; Expected = '2000'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'HungAppTimeout'; Expected = '2000'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'AutoEndTasks'; Expected = '1'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control'; Name = 'WaitToKillAppTimeout'; Expected = '2000'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control'; Name = 'WaitToKillServiceTimeout'; Expected = '2000'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control'; Name = 'FastShutdown'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability'; Name = 'ShutdownReasonOn'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability'; Name = 'ShutdownReasonUI'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize'; Name = 'StartupDelayInMSec'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize'; Name = 'StartupDelayInMSec'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'MenuShowDelay'; Expected = '0'; RegType = 'REG_SZ' }
        )
    }
    'geral.apps-travados' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'AutoEndTasks'; Expected = '1'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows'; Name = 'AutoEndTasks'; Expected = '1'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'HungAppTimeout'; Expected = '2000'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control'; Name = 'WaitToKillAppTimeout'; Expected = '2000'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'WaitToKillAppTimeout'; Expected = '2000'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control'; Name = 'WaitToKillServiceTimeout'; Expected = '2000'; RegType = 'REG_SZ' }
        )
    }
    'geral.efeitos-visuais' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'; Name = 'VisualFXSetting'; Expected = '3'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name = 'EnableTransparency'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop\WindowMetrics'; Name = 'MinAnimate'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarAnimations'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'DragFullWindows'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ListviewShadow'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\DWM'; Name = 'EnableAeroPeek'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\DWM'; Name = 'AlwaysHibernateThumbnails'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'IconsOnly'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ListviewAlphaSelect'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'FontSmoothing'; Expected = '2'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'FontSmoothingType'; Expected = '2'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'FontSmoothingGamma'; Expected = '1000'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'FontSmoothingOrientation'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'UserPreferencesMask'; Expected = '9012038010000000'; RegType = 'REG_BINARY' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ExtendedUIHoverTime'; Expected = '30000'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'; Name = 'EnableFirstLogonAnimation'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'geral.prefetch-superfetch' = [ordered]@{
        'apply' = @(
            @{ Type = 'ServiceStartType'; Name = 'SysMain'; Expected = 'Disabled' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name = 'EnablePrefetcher'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name = 'EnableSuperfetch'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name = 'EnableBootTrace'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'geral.mover-copiar-para' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\Copy To'; Name = '(Default)'; Expected = '{C2FBB630-2971-11D1-A18C-00C04FD75D13}'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\Move To'; Name = '(Default)'; Expected = '{C2FBB631-2971-11D1-A18C-00C04FD75D13}'; RegType = 'REG_SZ' }
        )
    }
    'geral.preenchimento-automatico' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete'; Name = 'AutoSuggest'; Expected = 'no'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete'; Name = 'Append Completion'; Expected = 'no'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions'; Expected = '1'; RegType = 'REG_DWORD' }
        )
    }
    'geral.acesso-rapido' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowRecent'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowFrequent'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackDocs'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackProgs'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'JumpListItems_Maximum'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'geral.barra-tarefas' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarAl'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'geral.area-transferencia' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Clipboard'; Name = 'EnableClipboardHistory'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Clipboard'; Name = 'EnableCloudClipboard'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Clipboard'; Name = 'CloudClipboardAutomaticUpload'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'AllowClipboardHistory'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'AllowCrossDeviceClipboard'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'geral.assistente-foco' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings'; Name = 'NOC_GLOBAL_SETTING_QUIETHOURS_ENABLED'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\QuietHours'; Name = 'WhenPlayingGameEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\QuietHours'; Name = 'WhenRunningFullscreenEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\QuietHours'; Name = 'WhenPresentationModeEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings'; Name = 'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'geral.central-acoes' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'DisableNotificationCenter'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'DisableNotificationCenter'; Expected = '1'; RegType = 'REG_DWORD' }
        )
    }
    'geral.foto-classico' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations'; Name = '.bmp'; Expected = 'PhotoViewer.FileAssoc.Tiff'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations'; Name = '.dib'; Expected = 'PhotoViewer.FileAssoc.Tiff'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations'; Name = '.gif'; Expected = 'PhotoViewer.FileAssoc.Tiff'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations'; Name = '.jfif'; Expected = 'PhotoViewer.FileAssoc.Jpeg'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations'; Name = '.jpe'; Expected = 'PhotoViewer.FileAssoc.Jpeg'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations'; Name = '.jpeg'; Expected = 'PhotoViewer.FileAssoc.Jpeg'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations'; Name = '.jpg'; Expected = 'PhotoViewer.FileAssoc.Jpeg'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations'; Name = '.png'; Expected = 'PhotoViewer.FileAssoc.Tiff'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations'; Name = '.tif'; Expected = 'PhotoViewer.FileAssoc.Tiff'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations'; Name = '.tiff'; Expected = 'PhotoViewer.FileAssoc.Tiff'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations'; Name = '.wdp'; Expected = 'PhotoViewer.FileAssoc.Wdp'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\RegisteredApplications'; Name = 'Windows Photo Viewer'; Expected = 'SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Classes\.jpg'; Name = '(Default)'; Expected = 'PhotoViewer.FileAssoc.Jpeg'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Classes\.jpeg'; Name = '(Default)'; Expected = 'PhotoViewer.FileAssoc.Jpeg'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Classes\.jpe'; Name = '(Default)'; Expected = 'PhotoViewer.FileAssoc.Jpeg'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Classes\.jfif'; Name = '(Default)'; Expected = 'PhotoViewer.FileAssoc.Jpeg'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Classes\.png'; Name = '(Default)'; Expected = 'PhotoViewer.FileAssoc.Tiff'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Classes\.bmp'; Name = '(Default)'; Expected = 'PhotoViewer.FileAssoc.Tiff'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Classes\.dib'; Name = '(Default)'; Expected = 'PhotoViewer.FileAssoc.Tiff'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Classes\.gif'; Name = '(Default)'; Expected = 'PhotoViewer.FileAssoc.Tiff'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Classes\.tif'; Name = '(Default)'; Expected = 'PhotoViewer.FileAssoc.Tiff'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Classes\.tiff'; Name = '(Default)'; Expected = 'PhotoViewer.FileAssoc.Tiff'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Classes\.wdp'; Name = '(Default)'; Expected = 'PhotoViewer.FileAssoc.Wdp'; RegType = 'REG_SZ' }
        )
    }
    'geral.notificacoes' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications'; Name = 'ToastEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'; Name = 'NoToastApplicationNotification'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings'; Name = 'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings'; Name = 'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'geral.indexacao-pesquisa' = [ordered]@{
        'apply' = @(
            @{ Type = 'ServiceStartType'; Name = 'WSearch'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'Microsoft\Windows\Shell\IndexerAutomaticMaintenance'; Expected = 'Disabled' }
        )
    }
    'geral.teclas-acessibilidade' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Accessibility\StickyKeys'; Name = 'Flags'; Expected = '506'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Accessibility\Keyboard Response'; Name = 'Flags'; Expected = '122'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Accessibility\ToggleKeys'; Name = 'Flags'; Expected = '58'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Accessibility\Keyboard Response'; Name = 'DelayBeforeAcceptance'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Accessibility\Keyboard Response'; Name = 'AutoRepeatDelay'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Accessibility\Keyboard Response'; Name = 'AutoRepeatRate'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Accessibility\Keyboard Response'; Name = 'BounceTime'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Accessibility\Keyboard Response'; Name = 'Confirmation'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Accessibility\Keyboard Response'; Name = 'HotkeyActive'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Accessibility\StickyKeys'; Name = 'Confirmation'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Accessibility\StickyKeys'; Name = 'HotkeyActive'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Accessibility\ToggleKeys'; Name = 'Confirmation'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Accessibility\ToggleKeys'; Name = 'HotkeyActive'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\Control Panel\Accessibility\StickyKeys'; Name = 'Flags'; Expected = '506'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\Control Panel\Accessibility\Keyboard Response'; Name = 'Flags'; Expected = '122'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\Control Panel\Accessibility\ToggleKeys'; Name = 'Flags'; Expected = '58'; RegType = 'REG_SZ' }
        )
    }
    'geral.itens-ocultos' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Hidden'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowSuperHidden'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'geral.icone-atalho' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates'; Name = 'ShortcutNameTemplate'; Expected = '%s.lnk'; RegType = 'REG_SZ' }
        )
    }
    'geral.extensoes-arquivos' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'HideFileExt'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'HideFileExt'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'geral.segundos-relogio' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowSecondsInSystemClock'; Expected = '1'; RegType = 'REG_DWORD' }
        )
    }
    'geral.menu-contexto-classico' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'; Name = '(Default)'; Expected = ''; RegType = '' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'; Name = '(Default)'; Expected = ''; RegType = '' }
        )
    }
    'geral.privacidade-amd' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\AMD\CN\UserExperienceProgram'; Name = 'Participation'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\AMD\CN\UserExperienceProgram'; Name = 'Participation'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\AMD\InstallDir'; Name = 'UEPEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'ServiceStartType'; Name = 'AMD Crash Defender Service'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'AMD\AMD Install\AMD Installer Launcher'; Expected = 'Disabled' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\AMD\CN\Telemetry'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\AMD\CN\Telemetry'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\AMD\CN\CN'; Name = 'TelemetryEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\AMD\CN\CN'; Name = 'TelemetryEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'ServiceStartType'; Name = 'AMD External Events Utility'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'AMD\AMD Radeon Software'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'AMD\AMD CCC-AEMUpdater'; Expected = 'Disabled' }
        )
    }
    'hardware.mpo' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows\Dwm'; Name = 'OverlayTestMode'; Expected = '5'; RegType = 'REG_DWORD' }
        )
    }
    'hardware.recursos-desnecessarios' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\AMD\CN\Link'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\AMD\CN\Link'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\AMD\CN\Link'; Name = 'AMDLinkEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'ServiceStartType'; Name = 'AMD Link Server'; Expected = 'Disabled' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Connect'; Name = 'AllowProjectionToPC'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Connect'; Name = 'AllowProjectionToPCOverInfrastructure'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\WirelessDisplay'; Name = 'MiracastEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'ServiceStartType'; Name = 'WFDSConMgrSvc'; Expected = 'Disabled' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\WirelessDisplay\Settings'; Name = 'EnableInjectorService'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\AMD\CN\InstantReplay'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\AMD\CN\InstantReplay'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\AMD\CN\DVR'; Name = 'InstantReplayEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'ServiceStartType'; Name = 'AMDRSLinuxAgent'; Expected = 'Disabled' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\AMD\CN\NoiseSuppression'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\AMD\CN\NoiseSuppression'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\AMD\CN\Audio'; Name = 'NoiseSuppressionEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'ServiceStartType'; Name = 'AMDAudioService'; Expected = 'Disabled' }
        )
    }
    'hardware.fso' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\System\GameConfigStore'; Name = 'GameDVR_DXGIHonorFSEWindowsCompatible'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\System\GameConfigStore'; Name = 'GameDVR_FSEBehavior'; Expected = '2'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\System\GameConfigStore'; Name = 'GameDVR_FSEBehaviorMode'; Expected = '2'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\System\GameConfigStore'; Name = 'GameDVR_HonorUserFSEBehaviorMode'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'GameDVR_FSEBehaviorMode'; Expected = '2'; RegType = 'REG_DWORD' }
        )
    }
    'hardware.max-desempenho' = [ordered]@{
        'apply' = @(
            @{ Type = 'AmdGpuRegValue'; Name = 'EnableULPS'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'EnableULPS_NA'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'PP_ThermalAutoThrottlingEnable'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'PP_SclkDeepSleepEnable'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'PP_ThermalController'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'KMD_EnableComputePreemption'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'PP_DisablePowerContainment'; Expected = 1 }
            @{ Type = 'AmdGpuRegValue'; Name = 'PP_PowerContainment'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'PP_GpuPowerBoostEnable'; Expected = 1 }
            @{ Type = 'AmdGpuRegValue'; Name = 'PP_Force3DPerformanceMode'; Expected = 1 }
            @{ Type = 'AmdGpuRegValue'; Name = 'ACE'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'PP_PhmUseDummyBackEnd'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'PP_GFXPowerGating'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'PP_UVDPowerGating'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'PP_VCEPowerGating'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'PP_SAMUPowerGating'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'PP_ACP_PowerGating'; Expected = 0 }
        )
    }
    'hardware.buffer-triplo' = [ordered]@{
        'apply' = @(
            @{ Type = 'AmdGpuRegValue'; Name = 'TF'; Expected = 0 }
        )
    }
    'hardware.formato-superficie' = [ordered]@{
        'apply' = @(
            @{ Type = 'AmdGpuRegValue'; Name = 'SurfaceFormatOpt'; Expected = 1 }
            @{ Type = 'AmdGpuRegValue'; Name = 'DalEnableSFO'; Expected = 1 }
        )
    }
    'hardware.shader-cache' = [ordered]@{
        'apply' = @(
            @{ Type = 'AmdGpuRegValue'; Name = 'ShaderCache'; Expected = 1 }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Direct3D'; Name = 'ShaderCacheEnabled'; Expected = '1'; RegType = 'REG_DWORD' }
        )
    }
    'hardware.vsync' = [ordered]@{
        'apply' = @(
            @{ Type = 'AmdGpuRegValue'; Name = 'IsVSyncEnabled'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'VSyncEnabled'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'Wait4VBlank'; Expected = 0 }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Direct3D'; Name = 'DisableVSync'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'AmdGpuRegMissing'; Name = 'VSyncIdleTimeout' }
        )
    }
    'hardware.mosaicos' = [ordered]@{
        'padrao' = @(
            @{ Type = 'AmdGpuRegValue'; Name = 'TessellationMode'; Expected = 0 }
            @{ Type = 'AmdGpuRegValue'; Name = 'MaxTessFactor'; Expected = 0 }
        )
        'off' = @(
            @{ Type = 'AmdGpuRegValue'; Name = 'TessellationMode'; Expected = 2 }
            @{ Type = 'AmdGpuRegValue'; Name = 'MaxTessFactor'; Expected = 1 }
        )
        '16x' = @(
            @{ Type = 'AmdGpuRegValue'; Name = 'TessellationMode'; Expected = 1 }
            @{ Type = 'AmdGpuRegValue'; Name = 'MaxTessFactor'; Expected = 16 }
        )
        '32x' = @(
            @{ Type = 'AmdGpuRegValue'; Name = 'TessellationMode'; Expected = 1 }
            @{ Type = 'AmdGpuRegValue'; Name = 'MaxTessFactor'; Expected = 32 }
        )
    }
    'hardware.atualizacao-automatica' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\AMD\CN\AutoUpdate'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\AMD\CN\AutoUpdate'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\AMD\CN\AutoUpdate'; Name = 'AutoDownload'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\AMD\CN\AutoUpdate'; Name = 'AutoInstall'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'ServiceStartType'; Name = 'AMD Update'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'AMD\AMD Install\AMD Installer'; Expected = 'Disabled' }
            @{ Type = 'TaskState'; Task = 'AMD\AMD Install\AMD Installer Launcher'; Expected = 'Disabled' }
        )
    }
    'hardware.crash-defender' = [ordered]@{
        'apply' = @(
            @{ Type = 'ServiceStartType'; Name = 'AMD Crash Defender Service'; Expected = 'Disabled' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\AMD\CN\CrashDefender'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\AMD\CN\CrashDefender'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'hardware.estacionamento-nucleos' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'; Name = 'ValueMax'; Expected = '100'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'; Name = 'ValueMin'; Expected = '100'; RegType = 'REG_DWORD' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = '54533251-82be-4824-96c1-47b60b740d00'; Setting = '0cc5b647-c1df-4637-891a-dec35c318583'; Expected = 100; Mode = 'AC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = '54533251-82be-4824-96c1-47b60b740d00'; Setting = '0cc5b647-c1df-4637-891a-dec35c318583'; Expected = 100; Mode = 'DC' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\ea062031-0e34-4ff1-9b6d-eb1059334028'; Name = 'ValueMax'; Expected = '100'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\ea062031-0e34-4ff1-9b6d-eb1059334028'; Name = 'ValueMin'; Expected = '100'; RegType = 'REG_DWORD' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = '54533251-82be-4824-96c1-47b60b740d00'; Setting = 'ea062031-0e34-4ff1-9b6d-eb1059334028'; Expected = 100; Mode = 'AC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = '54533251-82be-4824-96c1-47b60b740d00'; Setting = 'ea062031-0e34-4ff1-9b6d-eb1059334028'; Expected = 100; Mode = 'DC' }
        )
    }
    'hardware.power-throttling' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling'; Name = 'PowerThrottlingOff'; Expected = '1'; RegType = 'REG_DWORD' }
        )
    }
    'hardware.modern-standby' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\System\CurrentControlSet\Control\Power'; Name = 'PlatformAoAcOverride'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\System\CurrentControlSet\Control\Power'; Name = 'EnforceDisconnectedStandby'; Expected = '1'; RegType = 'REG_DWORD' }
        )
    }
    'hardware.cpu-max-desempenho' = [ordered]@{
        'apply' = @(
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_PROCESSOR'; Setting = 'PROCTHROTTLEMIN'; Expected = 100; Mode = 'AC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_PROCESSOR'; Setting = 'PROCTHROTTLEMAX'; Expected = 100; Mode = 'AC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_PROCESSOR'; Setting = 'PROCTHROTTLEMIN'; Expected = 100; Mode = 'DC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_PROCESSOR'; Setting = 'PROCTHROTTLEMAX'; Expected = 100; Mode = 'DC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_PROCESSOR'; Setting = 'PERFBOOSTMODE'; Expected = 2; Mode = 'AC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = 'SUB_PROCESSOR'; Setting = 'PERFBOOSTMODE'; Expected = 2; Mode = 'DC' }
        )
    }
    'hardware.compressao-memoria' = [ordered]@{
        'apply' = @(
            @{ Type = 'MMAgentFlag'; Name = 'MemoryCompression'; Expected = $false }
        )
    }
    'hardware.paginacao-kernel' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'DisablePagingExecutive'; Expected = '1'; RegType = 'REG_DWORD' }
        )
    }
    'hardware.page-combining' = [ordered]@{
        'apply' = @(
            @{ Type = 'MMAgentFlag'; Name = 'PageCombining'; Expected = $false }
        )
    }
    'hardware.mouse-escala' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Mouse'; Name = 'MouseSpeed'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Mouse'; Name = 'MouseThreshold1'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Mouse'; Name = 'MouseThreshold2'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Mouse'; Name = 'MouseSensitivity'; Expected = '10'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Mouse'; Name = 'SmoothMouseXCurve'; Expected = '0000000000000000C0CC0C0000000000809919000000000040662600000000000099330000000000'; RegType = 'REG_BINARY' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Mouse'; Name = 'SmoothMouseYCurve'; Expected = '0000000000000000000038000000000000007000000000000000A800000000000000E00000000000'; RegType = 'REG_BINARY' }
        )
    }
    'hardware.repeticao-teclado' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Keyboard'; Name = 'KeyboardDelay'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Keyboard'; Name = 'KeyboardSpeed'; Expected = '31'; RegType = 'REG_SZ' }
        )
    }
    'hardware.energia-usb' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\HidUsb\Parameters'; Name = 'EnhancedPowerManagementEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\USBXHCI\Parameters'; Name = 'SelectiveSuspendEnabledMask'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\USBXHCI\Parameters'; Name = 'AllowIdleIrpInD3'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = '2a737441-1930-4402-8d77-b2bebba308a3'; Setting = '48e6b7a6-50f5-4782-a5d4-53bb8f07e226'; Expected = 0; Mode = 'AC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = '2a737441-1930-4402-8d77-b2bebba308a3'; Setting = '48e6b7a6-50f5-4782-a5d4-53bb8f07e226'; Expected = 0; Mode = 'DC' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\USB'; Name = 'DisableSelectiveSuspend'; Expected = '1'; RegType = 'REG_DWORD' }
        )
    }
    'hardware.disk-timeout' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\Disk'; Name = 'TimeOutValue'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device'; Name = 'RequestTimeout'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device'; Name = 'RequestTimeout'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'hardware.io-latency-cap' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device'; Name = 'IoLatencyCap'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device'; Name = 'IoLatencyCap'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\I/O System'; Name = 'IoTransferThreshold'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'hardware.nvme-power-state' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device'; Name = 'IdlePowerState'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device'; Name = 'EnableDevicePowerManagement'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device'; Name = 'EnableHIPM'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device'; Name = 'EnableDIPM'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = '0012ee47-9041-4b5d-9b77-535fba8b1442'; Setting = 'd639518a-e56d-4345-8af2-b9f32fb26109'; Expected = 0; Mode = 'AC' }
        )
    }
    'internet.teredo' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'; Name = 'DisabledComponents'; Expected = '8'; RegType = 'REG_DWORD' }
        )
    }
    'internet.nagle-algorithm' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\MSMQ\Parameters'; Name = 'TCPNoDelay'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'; Name = 'TcpAckFrequency'; Expected = '1'; RegType = 'REG_DWORD' }
        )
    }
    'internet.network-throttling' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'NetworkThrottlingIndex'; Expected = '4294967295'; RegType = 'REG_DWORD' }
        )
    }
    'internet.energia-nic' = [ordered]@{
        'apply' = @(
            @{ Type = 'NicClassRegValue'; Name = 'PnPCapabilities'; Expected = 24 }
            @{ Type = 'NicClassRegValue'; Name = '*EEE'; Expected = '0' }
            @{ Type = 'NicClassRegValue'; Name = 'EEE'; Expected = '0' }
            @{ Type = 'NicClassRegValue'; Name = 'GreenEthernet'; Expected = '0' }
            @{ Type = 'NicClassRegValue'; Name = 'PowerSavingMode'; Expected = '0' }
        )
    }
    'internet.rsc-lso-interrupt' = [ordered]@{
        'apply' = @(
            @{ Type = 'NicClassRegValue'; Name = '*LsoV1IPv4'; Expected = '0' }
            @{ Type = 'NicClassRegValue'; Name = '*LsoV2IPv4'; Expected = '0' }
            @{ Type = 'NicClassRegValue'; Name = '*LsoV2IPv6'; Expected = '0' }
            @{ Type = 'NicClassRegValue'; Name = '*RscIPv4'; Expected = '0' }
            @{ Type = 'NicClassRegValue'; Name = '*RscIPv6'; Expected = '0' }
            @{ Type = 'NicClassRegValue'; Name = '*InterruptModeration'; Expected = '0' }
        )
    }
    'internet.tcp-connection' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'; Name = 'GlobalMaxTcpWindowSize'; Expected = '1048576'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'; Name = 'TcpWindowSize'; Expected = '1048576'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'; Name = 'TcpMaxDataRetransmissions'; Expected = '3'; RegType = 'REG_DWORD' }
        )
    }
    'pulsemode.dwm' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\DWM'; Name = 'EnableAeroPeek'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\Windows\DWM'; Name = 'AlwaysHibernateThumbnails'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Control Panel\Desktop'; Name = 'DragFullWindows'; Expected = '0'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'NetworkThrottlingIndex'; Expected = '4294967295'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'SystemResponsiveness'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'GPU Priority'; Expected = '8'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Priority'; Expected = '6'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Scheduling Category'; Expected = 'High'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'SFIO Priority'; Expected = 'High'; RegType = 'REG_SZ' }
        )
    }
    'pulsemode.usb-msi' = [ordered]@{
        'apply' = @(
            @{ Type = 'PnpRegValue'; Class = 'USB'; PathSuffix = 'Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; Name = 'MSISupported'; Expected = 1 }
            @{ Type = 'PnpRegValue'; Class = 'USB'; PathSuffix = 'Device Parameters\Interrupt Management\Affinity Policy'; Name = 'DevicePriority'; Expected = 3 }
        )
    }
    'pulsemode.gpu-msi' = [ordered]@{
        'apply' = @(
            @{ Type = 'PnpRegValue'; Class = 'Display'; PathSuffix = 'Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; Name = 'MSISupported'; Expected = 1 }
            @{ Type = 'PnpRegValue'; Class = 'Display'; PathSuffix = 'Device Parameters\Interrupt Management\Affinity Policy'; Name = 'DevicePriority'; Expected = 3 }
        )
    }
    'pulsemode.interrupt' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; Name = 'DpcWatchdogPeriod'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; Name = 'DpcTimeout'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; Name = 'MaximumDpcQueueDepth'; Expected = '1'; RegType = 'REG_DWORD' }
        )
    }
    'pulsemode.queue-size' = [ordered]@{
        'padrao' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters'; Name = 'MouseDataQueueSize'; Expected = '50'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters'; Name = 'KeyboardDataQueueSize'; Expected = '50'; RegType = 'REG_DWORD' }
        )
        'gaming' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters'; Name = 'MouseDataQueueSize'; Expected = '25'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters'; Name = 'KeyboardDataQueueSize'; Expected = '25'; RegType = 'REG_DWORD' }
        )
        'competitivo' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters'; Name = 'MouseDataQueueSize'; Expected = '16'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters'; Name = 'KeyboardDataQueueSize'; Expected = '16'; RegType = 'REG_DWORD' }
        )
    }
    'pulsemode.dynamic-tick' = [ordered]@{
        'apply' = @(
            @{ Type = 'BcdValue'; Name = 'disabledynamictick'; Expected = 'yes' }
            @{ Type = 'BcdValue'; Name = 'tscsyncpolicy'; Expected = 'Enhanced' }
        )
    }
    'pulsemode.iopagelimit' = [ordered]@{
        'padrao' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'IoPageLockLimit'; Expected = '134217728'; RegType = 'REG_DWORD' }
        )
        'competitivo' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'IoPageLockLimit'; Expected = '268435456'; RegType = 'REG_DWORD' }
        )
        'ultra' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'IoPageLockLimit'; Expected = '536870912'; RegType = 'REG_DWORD' }
        )
    }
    'pulsemode.timer-coalescing' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; Name = 'CoalescingTimerInterval'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'pulsemode.amd-flip-queue-size' = [ordered]@{
        'padrao' = @(
            @{ Type = 'AmdGpuRegMissing'; Name = 'TFQ' }
        )
        'equilibrado' = @(
            @{ Type = 'AmdGpuRegValue'; Name = 'TFQ'; Expected = 2 }
        )
        'competitivo' = @(
            @{ Type = 'AmdGpuRegValue'; Name = 'TFQ'; Expected = 1 }
        )
    }
    'pulsemode.prioridade-agendamento-cpu' = [ordered]@{
        'padrao' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions'; Name = 'CpuPriorityClass'; Expected = '3'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions'; Name = 'IoPriority'; Expected = '3'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name = 'Win32PrioritySeparation'; Expected = '18'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'SystemResponsiveness'; Expected = '10'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'NoLazyMode'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'GPU Priority'; Expected = '8'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Priority'; Expected = '4'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Scheduling Category'; Expected = 'Medium'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'SFIO Priority'; Expected = 'Normal'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Background Only'; Expected = 'False'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Clock Rate'; Expected = '10000'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Affinity'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Affinity'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Background Only'; Expected = 'False'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Clock Rate'; Expected = '10000'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'GPU Priority'; Expected = '8'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Priority'; Expected = '4'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Scheduling Category'; Expected = 'Medium'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'SFIO Priority'; Expected = 'Normal'; RegType = 'REG_SZ' }
        )
        'gaming' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions'; Name = 'CpuPriorityClass'; Expected = '3'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions'; Name = 'IoPriority'; Expected = '3'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name = 'Win32PrioritySeparation'; Expected = '26'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'SystemResponsiveness'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'NoLazyMode'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'GPU Priority'; Expected = '8'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Priority'; Expected = '6'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Scheduling Category'; Expected = 'High'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'SFIO Priority'; Expected = 'High'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Background Only'; Expected = 'False'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Clock Rate'; Expected = '10000'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Affinity'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Affinity'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Background Only'; Expected = 'False'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Clock Rate'; Expected = '10000'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'GPU Priority'; Expected = '8'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Priority'; Expected = '6'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Scheduling Category'; Expected = 'High'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'SFIO Priority'; Expected = 'High'; RegType = 'REG_SZ' }
        )
        'competitivo' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions'; Name = 'CpuPriorityClass'; Expected = '3'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions'; Name = 'IoPriority'; Expected = '3'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name = 'Win32PrioritySeparation'; Expected = '24'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'SystemResponsiveness'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'NoLazyMode'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'GPU Priority'; Expected = '8'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Priority'; Expected = '8'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Scheduling Category'; Expected = 'High'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'SFIO Priority'; Expected = 'High'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Background Only'; Expected = 'False'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Clock Rate'; Expected = '10000'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Affinity'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Affinity'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Background Only'; Expected = 'False'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Clock Rate'; Expected = '10000'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'GPU Priority'; Expected = '8'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Priority'; Expected = '8'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'Scheduling Category'; Expected = 'High'; RegType = 'REG_SZ' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency'; Name = 'SFIO Priority'; Expected = 'High'; RegType = 'REG_SZ' }
        )
    }
    'pulsemode.modo-jogo' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\GameBar'; Name = 'AutoGameModeEnabled'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\GameBar'; Name = 'AllowAutoGameMode'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\System\GameConfigStore'; Name = 'GameDVR_FSEBehaviorMode'; Expected = '2'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\System\GameConfigStore'; Name = 'GameDVR_HonorUserFSEBehaviorMode'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\System\GameConfigStore'; Name = 'GameDVR_DXGIHonorFSEWindowsCompatible'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\System\GameConfigStore'; Name = 'GameDVR_EFSEBehaviorMode'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\System\GameConfigStore'; Name = 'GameDVR_DSEBehavior'; Expected = '2'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Name = 'AllowGameDVR'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\GameBar'; Name = 'ShowStartupPanel'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\GameBar'; Name = 'GamePanelStartupTipIndex'; Expected = '3'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\Software\Microsoft\GameBar'; Name = 'UseNexusForGameBarEnabled'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'pulsemode.cfg' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; Name = 'MitigationOptions'; Expected = '0'; RegType = 'REG_QWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; Name = 'MitigationAuditOptions'; Expected = '0'; RegType = 'REG_QWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\*'; Name = 'MitigationOptions'; Expected = '0'; RegType = 'REG_QWORD' }
        )
    }
    'pulsemode.synthetic-timers' = [ordered]@{
        'apply' = @(
            @{ Type = 'BcdValue'; Name = 'useplatformclock'; Expected = 'false' }
            @{ Type = 'BcdValue'; Name = 'disabledynamictick'; Expected = 'yes' }
            @{ Type = 'BcdValue'; Name = 'tscsyncpolicy'; Expected = 'enhanced' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'; Name = 'GlobalTimerResolutionRequests'; Expected = '1'; RegType = 'REG_DWORD' }
        )
    }
    'pulsemode.windows-update' = [ordered]@{
        'apply' = @(
            @{ Type = 'ScheduledTaskExists'; Task = 'PulseOS\Pulse Mode - Otimizar Windows Update' }
            @{ Type = 'ServiceStartType'; Name = 'UsoSvc'; Expected = 'Disabled' }
            @{ Type = 'ServiceStartType'; Name = 'bits'; Expected = 'Disabled' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc'; Name = 'Start'; Expected = 4; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'NoAutoUpdate'; Expected = 1; RegType = 'REG_DWORD' }
        )
    }
    'pulsemode.svchostsplit' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control'; Name = 'SvcHostSplitThresholdInKB'; Expected = '4294967295'; RegType = 'REG_DWORD' }
        )
    }
    'pulsemode.spectre-meltdown' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'FeatureSettingsOverride'; Expected = '3'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'FeatureSettingsOverrideMask'; Expected = '3'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'MoveImages'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'pulsemode.vbs' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard'; Name = 'EnableVirtualizationBasedSecurity'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard'; Name = 'RequirePlatformSecurityFeatures'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard'; Name = 'Locked'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Lsa'; Name = 'LsaCfgFlags'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'BcdValue'; Name = 'hypervisorlaunchtype'; Expected = 'off' }
        )
    }
    'pulsemode.latency-tolerance' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters'; Name = 'PciLatencyTimer'; Expected = '32'; RegType = 'REG_DWORD' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = '501a4d13-42af-4429-9fd1-a8218c268e20'; Setting = 'ee12f906-d277-404b-b6da-e5fa1a576df5'; Expected = 0; Mode = 'AC' }
            @{ Type = 'PowerCfgValue'; Scheme = 'SCHEME_CURRENT'; Subgroup = '501a4d13-42af-4429-9fd1-a8218c268e20'; Setting = 'ee12f906-d277-404b-b6da-e5fa1a576df5'; Expected = 0; Mode = 'DC' }
            @{ Type = 'RegValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters'; Name = 'PciDisablePowerManagement'; Expected = '1'; RegType = 'REG_DWORD' }
        )
    }
    'pulsemode.fth' = [ordered]@{
        'apply' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\FTH'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\WOW6432Node\Microsoft\FTH'; Name = 'Enabled'; Expected = '0'; RegType = 'REG_DWORD' }
        )
    }
    'restaurar.impressao' = [ordered]@{
        'restaurar' = @(
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers'; Name = 'DisableHTTPPrinting' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers'; Name = 'DisableWebPnPDownload' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers'; Name = 'DisableWebPnPPrinting' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers'; Name = 'RegisterSpoolerRemoteRpcEndPoint' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint'; Name = 'RestrictDriverInstallationToAdministrators' }
            @{ Type = 'ServiceStartType'; Name = 'Spooler'; Expected = 'Automatic' }
            @{ Type = 'ServiceStartType'; Name = 'PrintNotify'; Expected = 'Manual' }
            @{ Type = 'ServiceStartType'; Name = 'Fax'; Expected = 'Manual' }
            @{ Type = 'ServiceStartType'; Name = 'stisvc'; Expected = 'Manual' }
            @{ Type = 'ServiceStartType'; Name = 'fdPHost'; Expected = 'Manual' }
            @{ Type = 'ServiceStartType'; Name = 'FDResPub'; Expected = 'Manual' }
            @{ Type = 'ServiceNotDisabled'; Name = 'Spooler' }
            @{ Type = 'ServiceNotDisabled'; Name = 'stisvc' }
        )
    }
    'restaurar.virtualizacao-hyper-v' = [ordered]@{
        'restaurar' = @(
            @{ Type = 'BcdValue'; Name = 'hypervisorlaunchtype'; Expected = 'auto' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard'; Name = 'EnableVirtualizationBasedSecurity' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard'; Name = 'RequirePlatformSecurityFeatures' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard'; Name = 'Locked' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'; Name = 'Enabled' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard'; Name = 'Enabled' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard'; Name = 'EnableVirtualizationBasedSecurity' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard'; Name = 'RequirePlatformSecurityFeatures' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard'; Name = 'HypervisorEnforcedCodeIntegrity' }
            @{ Type = 'BcdValue'; Name = 'hypervisorlaunchtype'; Expected = 'Auto' }
        )
    }
    'restaurar.configuracoes-inicio' = [ordered]@{
        'restaurar' = @(
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'SettingsPageVisibility' }
            @{ Type = 'RegMissing'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'SettingsPageVisibility' }
            @{ Type = 'RegMissing'; Path = 'HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'SettingsPageVisibility' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Settings'; Name = 'SettingsPageVisibility' }
            @{ Type = 'RegMissing'; Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\Settings'; Name = 'SettingsPageVisibility' }
            @{ Type = 'RegMissing'; Path = 'HKU\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\Settings'; Name = 'SettingsPageVisibility' }
        )
    }
    'restaurar.explorer-inicio-acesso-rapido' = [ordered]@{
        'restaurar' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowRecent'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowFrequent'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}'; Name = 'System.IsPinnedToNameSpaceTree'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowRecent'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowFrequent'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\Software\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}'; Name = 'System.IsPinnedToNameSpaceTree'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecentlyAddedApps' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecommendedSection' }
            @{ Type = 'RegMissing'; Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecentlyAddedApps' }
            @{ Type = 'RegMissing'; Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecommendedSection' }
            @{ Type = 'RegMissing'; Path = 'HKU\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecentlyAddedApps' }
            @{ Type = 'RegMissing'; Path = 'HKU\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecommendedSection' }
            @{ Type = 'RegMissing'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_IrisRecommendations' }
            @{ Type = 'RegMissing'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Start'; Name = 'ShowRecentList' }
            @{ Type = 'RegMissing'; Path = 'HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_IrisRecommendations' }
            @{ Type = 'RegMissing'; Path = 'HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Start'; Name = 'ShowRecentList' }
        )
    }
    'restaurar.som-de-inicializacao' = [ordered]@{
        'restaurar' = @(
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation'; Name = 'DisableStartupSound'; Expected = '0'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'; Name = 'EnableSIHostIntegration'; Expected = '1'; RegType = 'REG_DWORD' }
        )
    }
    'restaurar.jump-lists' = [ordered]@{
        'restaurar' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackProgs'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackDocs'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegMissing'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'JumpListItems_Maximum' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackProgs'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackDocs'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegMissing'; Path = 'HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'JumpListItems_Maximum' }
        )
    }
    'restaurar.widgets' = [ordered]@{
        'restaurar' = @(
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'AllowNewsAndInterests' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests'; Name = 'value' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'; Name = 'EnableFeeds' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'HideTaskbarFeeds' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarDa'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegMissing'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds'; Name = 'ShellFeedsTaskbarViewMode' }
            @{ Type = 'RegMissing'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds'; Name = 'ShellFeedsTaskbarOpenOnHover' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarDa'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegMissing'; Path = 'HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Feeds'; Name = 'ShellFeedsTaskbarViewMode' }
            @{ Type = 'RegMissing'; Path = 'HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Feeds'; Name = 'ShellFeedsTaskbarOpenOnHover' }
        )
    }
    'restaurar.recursos-servicos-xbox' = [ordered]@{
        'restaurar' = @(
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'AppCaptureEnabled'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Microsoft\GameBar'; Name = 'ShowStartupPanel'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKCU\SOFTWARE\Microsoft\GameBar'; Name = 'UseNexusForGameBarEnabled'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegMissing'; Path = 'HKCU\SOFTWARE\Microsoft\GameBar'; Name = 'AutoGameModeEnabled' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'AppCaptureEnabled'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\SOFTWARE\Microsoft\GameBar'; Name = 'ShowStartupPanel'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegValue'; Path = 'HKU\.DEFAULT\SOFTWARE\Microsoft\GameBar'; Name = 'UseNexusForGameBarEnabled'; Expected = '1'; RegType = 'REG_DWORD' }
            @{ Type = 'RegMissing'; Path = 'HKU\.DEFAULT\SOFTWARE\Microsoft\GameBar'; Name = 'AutoGameModeEnabled' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Name = 'AllowGameDVR' }
            @{ Type = 'RegMissing'; Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Name = 'AllowGameDVR' }
            @{ Type = 'RegMissing'; Path = 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR'; Name = 'value' }
            @{ Type = 'ServiceStartType'; Name = 'XblAuthManager'; Expected = 'Manual' }
            @{ Type = 'ServiceStartType'; Name = 'XblGameSave'; Expected = 'Manual' }
            @{ Type = 'ServiceStartType'; Name = 'XboxNetApiSvc'; Expected = 'Manual' }
            @{ Type = 'ServiceStartType'; Name = 'XboxGipSvc'; Expected = 'Manual' }
            @{ Type = 'ServiceStartType'; Name = 'xbgm'; Expected = 'Manual' }
            @{ Type = 'ServiceStartType'; Name = 'GamingServices'; Expected = 'Manual' }
            @{ Type = 'ServiceStartType'; Name = 'GamingServicesNet'; Expected = 'Manual' }
        )
    }
}

$State = Import-PulseState
foreach ($id in $PulseChecks.Keys) {
    $states = $PulseChecks[$id]
    $detected = $false
    foreach ($stateName in $states.Keys) {
        if (Test-PulseDefaultStateName -Value $stateName) { continue }
        if (Test-PulseCheckList -Checks @($states[$stateName])) {
            if ($stateName -eq 'apply' -or $stateName -eq 'restaurar') { $State[$id] = $true }
            else { $State[$id] = [string]$stateName }
            $detected = $true
            break
        }
    }
    if (-not $detected) { $State[$id] = $false }
}
foreach ($key in @($State.Keys)) { if ($key -like '*_Value') { $State.Remove($key) } }
Save-PulseState -State $State
exit 0
