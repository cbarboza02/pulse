#------------------------------------------------------------------------------
# VERIFICADOR DE ESTADO - PULSEOS / PAINEL PULSE
#------------------------------------------------------------------------------
# Gera ou atualiza PulseState.json com o estado atual de cada opcao importante.
# Para otimizacoes redundantes com o PulseOS, true = padrao PulseOS aplicado.
# Para restauracoes, true = recurso restaurado; false = padrao PulseOS aplicado.

$ErrorActionPreference = 'SilentlyContinue'

$DocPath = [Environment]::GetFolderPath('MyDocuments')
$StateDir = Join-Path $DocPath 'Painel Pulse'
$StatePath = Join-Path $StateDir 'PulseState.json'

if (-not (Test-Path -LiteralPath $StateDir)) {
    New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
}

function Import-PulseState {
    $State = [ordered]@{}

    try {
        if (Test-Path -LiteralPath $StatePath) {
            $Content = Get-Content -LiteralPath $StatePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($Content)) {
                $Json = $Content | ConvertFrom-Json -ErrorAction Stop
                foreach ($Prop in $Json.PSObject.Properties) {
                    $State[$Prop.Name] = $Prop.Value
                }
            }
        }
    } catch {}

    return $State
}


function Get-RegValue {
    param([string]$Path,[string]$Name)
    try {
        if ($Name -eq '(Default)' -or [string]::IsNullOrEmpty($Name)) {
            return (Get-Item -LiteralPath $Path -ErrorAction Stop).GetValue('')
        }
        return (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name
    } catch { return $null }
}
function Test-RegValue {
    param([string]$Path,[string]$Name,$Expected)
    $Current = Get-RegValue -Path $Path -Name $Name
    if ($Expected -is [int] -or $Expected -is [long]) {
        try { return ([int64]$Current -eq [int64]$Expected) } catch { return $false }
    }
    return ([string]$Current -eq [string]$Expected)
}
function Test-ServiceStartType {
    param([string]$Name,[string]$Expected)
    try { return ((Get-Service -Name $Name -ErrorAction Stop).StartType.ToString() -eq $Expected) } catch { return $false }
}
function Test-AnyServiceStartType {
    param([string[]]$Names,[string]$Expected)
    foreach ($Name in $Names) { if (Test-ServiceStartType $Name $Expected) { return $true } }
    return $false
}
function Test-TaskDisabled {
    param([string]$TaskPath,[string]$TaskName)
    try { return ((Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop).State.ToString() -eq 'Disabled') } catch { return $true }
}
function Test-All {
    param([scriptblock[]]$Checks)
    foreach ($Check in $Checks) { if (-not (& $Check)) { return $false } }
    return $true
}

$Checks = [ordered]@{
    'geral.hibernacao' = @(
        { Test-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'HibernateEnabled' 0 },
        { Test-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'HibernateEnabledDefault' 0 },
        { Test-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 0 }
    )
    'geral.manutencao-automatica' = @(
        { Test-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance' 'MaintenanceDisabled' 1 },
        { Test-TaskDisabled '\Microsoft\Windows\TaskScheduler\' 'Regular Maintenance' },
        { Test-TaskDisabled '\Microsoft\Windows\TaskScheduler\' 'Maintenance Configurator' }
    )
    'geral.estimativa-energia' = @(
        { Test-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'EnergyEstimationEnabled' 0 },
        { Test-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'EnergyEstimationDisabled' 1 },
        { Test-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'UserBatteryDischargeEstimator' 0 },
        { Test-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'EEEnabled' 0 },
        { Test-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'SleepStudyEnabled' 0 }
    )
    'geral.acesso-rapido' = @(
        { Test-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'ShowRecent' 0 },
        { Test-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'ShowFrequent' 0 },
        { Test-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackDocs' 0 },
        { Test-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProgs' 0 }
    )
    'geral.extensoes-arquivos' = @({ Test-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0 })
    'geral.segundos-relogio' = @({ Test-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSecondsInSystemClock' 1 })
    'geral.teclas-acessibilidade' = @(
        { Test-RegValue 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '506' },
        { Test-RegValue 'HKCU:\Control Panel\Accessibility\Keyboard Response' 'Flags' '122' },
        { Test-RegValue 'HKCU:\Control Panel\Accessibility\ToggleKeys' 'Flags' '58' }
    )
    'geral.mover-copiar-para' = @(
        { Test-RegValue 'HKLM:\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\Copy To' '(Default)' '{C2FBB630-2971-11D1-A18C-00C04FD75D13}' },
        { Test-RegValue 'HKLM:\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\Move To' '(Default)' '{C2FBB631-2971-11D1-A18C-00C04FD75D13}' }
    )
    'geral.foto-classico' = @(
        { Test-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations' '.jpg' 'PhotoViewer.FileAssoc.Jpeg' },
        { Test-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations' '.jpeg' 'PhotoViewer.FileAssoc.Jpeg' },
        { Test-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations' '.wdp' 'PhotoViewer.FileAssoc.Wdp' },
        { Test-RegValue 'HKLM:\SOFTWARE\RegisteredApplications' 'Windows Photo Viewer' 'SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities' }
    )
    'geral.indexacao-pesquisa' = @({ Test-ServiceStartType 'WSearch' 'Disabled' })
    'pulsemode.xbox-servicos' = @(
        { Test-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0 },
        { Test-RegValue 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0 },
        { Test-RegValue 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0 },
        { Test-RegValue 'HKCU:\SOFTWARE\Microsoft\GameBar' 'ShowStartupPanel' 0 },
        { Test-AnyServiceStartType @('XblAuthManager','XblGameSave','XboxNetApiSvc','XboxGipSvc','GamingServices','GamingServicesNet') 'Manual' }
    )
    'restaurar.recursos-servicos-xbox' = @(
        { -not (Test-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0) },
        { Test-RegValue 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 1 }
    )
    'restaurar.explorer-inicio-acesso-rapido' = @(
        { Test-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'ShowRecent' 1 },
        { Test-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'ShowFrequent' 1 }
    )
    'restaurar.jump-lists' = @(
        { Test-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackDocs' 1 },
        { Test-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProgs' 1 }
    )
    'restaurar.widgets' = @(
        { Test-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarDa' 1 }
    )
    'restaurar.configuracoes-inicio' = @(
        { -not (Test-RegValue 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'SettingsPageVisibility' 'hide:home') }
    )
    'restaurar.som-de-inicializacao' = @(
        { Test-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation' 'DisableStartupSound' 0 }
    )
    'restaurar.impressao' = @(
        { -not (Test-ServiceStartType 'Spooler' 'Disabled') }
    )
    'restaurar.virtualizacao-hyper-v' = @(
        { $v=(bcdedit /enum '{current}' 2>$null | Select-String -Pattern 'hypervisorlaunchtype'); if ($v) { $v.ToString() -notmatch 'Off' } else { $false } }
    )
}

$State = Import-PulseState

foreach ($Id in $Checks.Keys) {
    $State[$Id] = [bool](Test-All $Checks[$Id])
}

$Json = $State | ConvertTo-Json -Depth 8
Set-Content -LiteralPath $StatePath -Value $Json -Encoding UTF8 -Force
exit 0
