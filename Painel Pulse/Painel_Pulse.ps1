#Requires -Version 5.1
<#
.SYNOPSIS
  Painel Pulse - Base Limpa e Definitiva
.DESCRIPTION
  Ferramenta exclusiva (PulseOS). Dimensões fixas (970x750), barra lateral (185px).
  Aba "Disco" renomeada e abas com borda fina quando selecionadas.
  Otimizações carregadas dinamicamente a partir de arquivos .json.
#>

# ==========================================
# TRAVA DE EXCLUSIVIDADE (PULSE OS)
# ==========================================
$RegPath = "HKLM:\SOFTWARE\PulseOS"
$RegName = "SystemID"
$ExpectedID = "PULSE-CORE"

$isExclusive = $false
try {
    $val = (Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction Stop).$RegName
    if ($val -eq $ExpectedID) { $isExclusive = $true }
} catch {}

if (-not $isExclusive) {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        "Ferramenta não autorizada. Este utilitário é exclusivo do PulseOS.", 
        "Painel Pulse", 
        'OK', 'Error'
    ) | Out-Null
    exit
}

# ==========================================
# CAMINHO BASE DO SCRIPT
# ==========================================
$script:BaseDir = if ($PSScriptRoot -and $PSScriptRoot -ne '') {
    $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path -and $MyInvocation.MyCommand.Path -ne '') {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} elseif ($MyInvocation.MyCommand.Definition -and $MyInvocation.MyCommand.Definition -ne '') {
    Split-Path -Parent $MyInvocation.MyCommand.Definition
} else {
    Join-Path $env:TEMP "Painel Pulse"
}

$script:RepoBaseUrl = "https://raw.githubusercontent.com/cbarboza02/pulse/main/Painel%20Pulse"

# ==========================================
# GESTÃO DE DIRETÓRIOS E LOG DIÁRIO
# ==========================================
$DocPath = [Environment]::GetFolderPath('MyDocuments')
$script:LogDir = Join-Path $DocPath "Painel Pulse\Logs"
$script:BackupDir = Join-Path $DocPath "Painel Pulse\Backups"

if (-not (Test-Path $script:LogDir)) { New-Item -ItemType Directory -Path $script:LogDir | Out-Null }
if (-not (Test-Path $script:BackupDir)) { New-Item -ItemType Directory -Path $script:BackupDir | Out-Null }

$script:LogFile = Join-Path $script:LogDir "PulseLog_$(Get-Date -Format 'yyyy-MM-dd').txt"
if (-not (Test-Path $script:LogFile)) {
    Set-Content -Path $script:LogFile -Value "=== LOG DIÁRIO DO PAINEL PULSE ($(Get-Date -Format 'dd/MM/yyyy')) ===" -Encoding UTF8
}

function Write-PulseLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Add-Content -Path $script:LogFile -Value "[$timestamp] $Message" -Encoding UTF8
}
Write-PulseLog "Painel Pulse iniciado."

# ==========================================
# SISTEMA DE MEMÓRIA DE ESTADO (PULSESTATE)
# ==========================================
$global:StateFile = Join-Path $DocPath "Painel Pulse\PulseState.json"
$global:PulseState = @{}

# Carrega a memória anterior se o arquivo existir
if (Test-Path $global:StateFile) {
    try {
        $content = Get-Content -Path $global:StateFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not [string]::IsNullOrWhiteSpace($content)) {
            $jsonObj = $content | ConvertFrom-Json
            foreach ($prop in $jsonObj.psobject.properties) {
                # Permite ler tanto verdadeiro/falso quanto o texto das configurações
                $global:PulseState[$prop.Name] = $prop.Value
            }
        }
    } catch { Write-PulseLog "Aviso: Falha ao ler PulseState.json anterior." }
}

# Função para gravar a memória no disco de forma segura
function Save-PulseState {
    try {
        # CORREÇÃO: Usar a variável global correta
        if ($global:PulseState.Keys.Count -gt 0) {
            ConvertTo-Json -InputObject $global:PulseState -Depth 2 | Set-Content -Path $global:StateFile -Encoding UTF8
        }
    } catch { Write-PulseLog "Erro ao salvar PulseState.json: $($_.Exception.Message)" }
}

# ==========================================
# LÓGICA DE DETEÇÃO DE HARDWARE
# ==========================================
function Detect-PulseHardware {
    $hw = [ordered]@{
        DeviceType = "Desktop"
        OS = "Windows"
        CPU = "Desconhecido"
        GPU = "Desconhecido"
        RAM = "Desconhecido"
        Storage = "Desconhecido"
    }

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($os) {
        $hw.OS = ($os.Caption -replace '^Microsoft\s+','').Trim()
    }
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) { $hw.DeviceType = "Notebook" }

    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cpu) { $hw.CPU = $cpu.Name.Trim() }

    $mem = Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue
    if ($mem) {
        $totalBytes = 0
        $speeds = @()
        foreach ($m in $mem) {
            $totalBytes += [int64]$m.Capacity
            if ($m.Speed) { $speeds += [int]$m.Speed }
        }
        $gb = [math]::Round($totalBytes / 1GB)
        $mhz = if ($speeds.Count -gt 0) { ($speeds | Measure-Object -Maximum).Maximum } else { "" }
        $hw.RAM = if ($mhz) { "$gb GB $mhz MHz" } else { "$gb GB" }
    }

    $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($gpu) {
        $gName = $gpu.Name.Trim()
        if ($gName -match "Adaptador de Vídeo Básico da Microsoft|Microsoft Basic Display Adapter") {
            $gName = "Vídeo Básico da Microsoft"
        } else {
            $gName = $gName -replace '(?i)^AMD\s+Radeon\s+(RX\s+)?', 'RX '
            $gName = $gName -replace '(?i)^AMD\s+', 'AMD'
            $gName = $gName -replace '(?i)^NVIDIA\s+GeForce\s+', ''
            $gName = $gName -replace '(?i)^NVIDIA\s+', 'NVIDIA'
            $gName = $gName -replace '(?i)^Intel\(R\)\s+', ''
            $gName = $gName -replace '(?i)^Intel\s+', 'Intel'
        }
        $hw.GPU = $gName.Trim()
    }

    try {
        $sysDrive = $env:SystemDrive
        
        $logicalDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$sysDrive'" | Select-Object -First 1
        $partition = Get-CimAssociatedInstance -InputObject $logicalDisk -Association Win32_LogicalDiskToPartition | Select-Object -First 1
        $diskDrive = Get-CimAssociatedInstance -InputObject $partition -Association Win32_DiskDriveToDiskPartition | Select-Object -First 1

        if ($diskDrive) {
            $diskModel = $diskDrive.Model.Trim()
            $diskSize = [math]::Round($diskDrive.Size / 1GB)
            $diskNumber = $diskDrive.Index
            
            $diskType = "HD"
            $physDisk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $diskNumber } | Select-Object -First 1
            
            if ($physDisk) {
                if ($physDisk.BusType -match 'NVMe') {
                    $diskType = "NVMe"
                } elseif ($physDisk.MediaType -match 'SSD') {
                    $diskType = "SSD"
                }
            } else {
                if ($diskDrive.InterfaceType -match 'NVMe' -or $diskModel -match '(?i)NVMe') {
                    $diskType = "NVMe"
                } elseif ($diskModel -match '(?i)SSD') {
                    $diskType = "SSD"
                }
            }

            $hw.Storage = "$diskModel ${diskSize}GB $diskType"
        } else {
            $hw.Storage = "Desconhecido"
        }
    } catch {
        $hw.Storage = "Desconhecido"
    }

    return $hw
}

# ==========================================
# DETECÇÃO GLOBAL DE HARDWARE PARA FILTROS
# ==========================================
$global:PulseDetectedBrand = "Desconhecida"
try {
    # Lê todas as GPUs e busca uma marca conhecida (Cobre PCs com 2 placas, ex: Intel e NVIDIA)
    $gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
    if ($gpus) {
        foreach ($gpuObj in $gpus) {
            $gName = $gpuObj.Name
            if ($gName -match "(?i)AMD|Radeon|RX") { $global:PulseDetectedBrand = "AMD"; break }
            elseif ($gName -match "(?i)NVIDIA|GeForce|Quadro") { $global:PulseDetectedBrand = "NVIDIA"; break }
            elseif ($gName -match "(?i)Intel|Arc|HD|UHD|Iris") { $global:PulseDetectedBrand = "Intel"; break }
        }
    }
} catch {}

# ==========================================
# CARREGAMENTO DE OTIMIZAÇÕES A PARTIR DE JSON
# ==========================================
function Load-PageOptimizations {
    param([string]$PageName)

    $jsonPath = Join-Path $script:BaseDir "arquivos\pulse_$PageName.json"
    if (-not (Test-Path $jsonPath)) { $jsonPath = Join-Path $script:BaseDir "json\pulse_$PageName.json" }
    if (-not (Test-Path $jsonPath)) { return @() }

    $raw = Get-Content -Path $jsonPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }

    try { $items = $raw | ConvertFrom-Json } catch { return @() }
    if ($null -eq $items -or @($items).Count -eq 0) { return @() }

    $result = @()
    foreach ($item in @($items)) {
        
        # === FILTRO RAIZ DE HARDWARE (BARREIRA IMPENETRÁVEL) ===
        # Resgata de forma limpa, ignorando o case-sensitive do PowerShell
        $reqGpu = [string]$item.gpu
        $reqGpu = $reqGpu.Trim()
        
        # Se a otimização pede uma GPU específica e não é a detectada, O ITEM É DESTRUÍDO
        if (-not [string]::IsNullOrWhiteSpace($reqGpu) -and $reqGpu -notmatch "^(?i)Todas?$") {
            if ($reqGpu -notmatch "(?i)$global:PulseDetectedBrand") {
                continue # Pula o item. Ele NUNCA entrará no painel.
            }
        }
        # =======================================================

        $applyBatAbs  = ""
        $applyParam   = ""
        $revertBatAbs = ""
        $revertParam  = ""

        $ttText = ""
        if (-not [string]::IsNullOrWhiteSpace($item.Description)) { $ttText += $item.Description }

        if ($null -ne $item.Tooltip) {
            if ($item.Tooltip.Pros -and $item.Tooltip.Pros.Count -gt 0) {
                $ttText += "`n `nVANTAGENS:`n" + ($item.Tooltip.Pros | ForEach-Object { "• $_" } | Out-String).Trim()
            }
            if ($item.Tooltip.Cons -and $item.Tooltip.Cons.Count -gt 0) {
                if ($ttText.Length -gt 0) { $ttText += "`n`n" }
                $ttText += "DESVANTAGENS:`n" + ($item.Tooltip.Cons | ForEach-Object { "• $_" } | Out-String).Trim()
            }
            if ($item.Tooltip.Unavailable -and $item.Tooltip.Unavailable.Count -gt 0) {
                if ($ttText.Length -gt 0) { $ttText += "`n`n" }
                $ttText += "FICARÁ INDISPONÍVEL:`n" + ($item.Tooltip.Unavailable | ForEach-Object { "• $_" } | Out-String).Trim()
            }
        }

        if ($null -ne $item.Apply -and -not [string]::IsNullOrWhiteSpace($item.Apply)) {
            $applyFull = $item.Apply.Trim()
            $applyLastSpace = $applyFull.LastIndexOf(' ')
            if ($applyLastSpace -ge 0) {
                $applyBatRel = $applyFull.Substring(0, $applyLastSpace).TrimStart('.').TrimStart('\').TrimStart('/')
                $applyParam  = $applyFull.Substring($applyLastSpace + 1)
            } else {
                $applyBatRel = $applyFull.TrimStart('.').TrimStart('\').TrimStart('/')
            }
            $applyBatAbs = Join-Path $script:BaseDir $applyBatRel
        }

        if ($null -ne $item.Revert -and -not [string]::IsNullOrWhiteSpace($item.Revert)) {
            $revertFull = $item.Revert.Trim()
            $revertLastSpace = $revertFull.LastIndexOf(' ')
            if ($revertLastSpace -ge 0) {
                $revertBatRel = $revertFull.Substring(0, $revertLastSpace).TrimStart('.').TrimStart('\').TrimStart('/')
                $revertParam  = $revertFull.Substring($revertLastSpace + 1)
            } else {
                $revertBatRel = $revertFull.TrimStart('.').TrimStart('\').TrimStart('/')
            }
            $revertBatAbs = Join-Path $script:BaseDir $revertBatRel
        }

        $idStr = [string]$item.Id
        $memoriaAtiva = $false
        $valorSalvo = ""
        
        if ($null -ne $global:PulseState[$idStr]) {
            $memoriaAtiva = [bool]$global:PulseState[$idStr]
        }
        
        # Lê a configuração que foi salva para esse item específico
        if ($null -ne $global:PulseState["$idStr`_Value"]) {
            $valorSalvo = [string]$global:PulseState["$idStr`_Value"]
        }

        $result += [PSCustomObject]@{
            Id          = $item.Id
            TabKey      = $item.TabKey
            gpu         = $item.gpu
            limpeza     = $item.limpeza
            pulsemode   = $item.pulsemode
            Name        = $item.Name
            Description = $item.Description
            TooltipText = $ttText
            IsChecked   = $memoriaAtiva
            ApplyBat    = $applyBatAbs
            ApplyParam  = $applyParam
            RevertBat   = $revertBatAbs
            RevertParam = $revertParam
            Values      = $item.Values
            SavedValue  = $valorSalvo
            Favorito    = [string]$item.Favorito
            Foco        = [string]$item.Foco
        }
    }
    return $result
}

# ==========================================
# INICIALIZAÇÃO WPF E DADOS (JSON)
# ==========================================
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# ==========================================
# FILA DE EXECUÇÃO DE OTIMIZAÇÕES (CONVEYOR BELT)
# ==========================================
$global:PulseQueue = [System.Collections.Generic.Queue[psobject]]::new()
$global:PulseCurrentProc = $null
$global:PulseCurrentJob = $null

$global:PulseQueueTimer = New-Object System.Windows.Threading.DispatcherTimer
$global:PulseQueueTimer.Interval = [TimeSpan]::FromMilliseconds(150)
$global:PulseQueueTimer.Add_Tick({
    # Se há um processo rodando, verifica se ele acabou
    if ($null -ne $global:PulseCurrentProc) {
        try {
            if (-not $global:PulseCurrentProc.HasExited) { return }
            
            # O PROCESSO ACABOU! O PowerShell registra no Log sem precisar alterar o .bat
            $status = if ($global:PulseCurrentJob.Action -eq "Aplicar") { "Aplicada" } else { "Revertida" }
            Write-PulseLog "$status - $($global:PulseCurrentJob.Name)"
        } catch {}
        
        $global:PulseCurrentProc = $null
        # Deleta o .bat após execução
        if (-not [string]::IsNullOrWhiteSpace($global:PulseCurrentJob.BatPath)) {
            try { Remove-Item -Path $global:PulseCurrentJob.BatPath -Force -ErrorAction SilentlyContinue } catch {}
        }
        $global:PulseCurrentJob = $null
    }

    # Se a esteira está livre e há itens na fila, puxa o próximo
    if ($global:PulseQueue.Count -gt 0) {
        $job = $global:PulseQueue.Dequeue()
        $global:PulseCurrentJob = $job
        try {
            $global:PulseCurrentProc = Start-Process -FilePath $job.File -ArgumentList $job.Args -WorkingDirectory $job.Dir -WindowStyle Hidden -Verb RunAs -PassThru
        } catch {
            Write-PulseLog "Erro na fila de execução: $($_.Exception.Message)"
            $global:PulseCurrentProc = $null
        }
    }
})
$global:PulseQueueTimer.Start()

function Get-PulseBat {
    param([string]$BatAbsPath)
    
    # Calcula o caminho relativo ao BaseDir para montar a URL
    $relPath = $BatAbsPath.Substring($script:BaseDir.Length).TrimStart('\', '/')
    $urlPath = $relPath -replace '\\', '/'
    $url = "$script:RepoBaseUrl/$urlPath"
    
    # Cria a pasta de destino se não existir
    $destDir = Split-Path $BatAbsPath
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $BatAbsPath -UseBasicParsing -ErrorAction Stop
        Write-PulseLog "Baixado: $urlPath"
        return $true
    } catch {
        Write-PulseLog "ERRO ao baixar $urlPath`: $($_.Exception.Message)"
        return $false
    }
}

function Add-PulseJob {
    param([string]$BatPath, [string]$Param, [string]$OptName, [string]$Action)
    if ([string]::IsNullOrWhiteSpace($BatPath)) { return }
    
    # Baixa o .bat do repositório se ele não existir localmente
    if (-not (Test-Path $BatPath)) {
        $ok = Get-PulseBat -BatAbsPath $BatPath
        if (-not $ok -or -not (Test-Path $BatPath)) {
            Write-PulseLog "ERRO: Não foi possível obter o arquivo para '$OptName'."
            return
        }
    }
    
    $job = [PSCustomObject]@{
        File      = 'cmd.exe'
        Args      = @('/c', "`"$BatPath`"", $Param)
        Dir       = (Split-Path $BatPath)
        Name      = $OptName
        Action    = $Action
        BatPath   = $BatPath   # <-- guardado para deletar depois
    }
    $global:PulseQueue.Enqueue($job)
    
    $pos = $global:PulseQueue.Count
    Write-PulseLog "Fila: Posição $pos | $OptName - $Action"
}

$script:Opts_Geral       = Load-PageOptimizations -PageName 'geral'
$script:Opts_Hardware    = Load-PageOptimizations -PageName 'hardware'
$script:Opts_Internet    = Load-PageOptimizations -PageName 'internet'
$script:Opts_Limpeza     = Load-PageOptimizations -PageName 'limpeza'
$script:Opts_PulseMode   = Load-PageOptimizations -PageName 'pulsemode'
$script:Opts_Restaurar   = Load-PageOptimizations -PageName 'restaurar'

# ==========================================
# XAML (INTERFACE VISUAL)
# ==========================================
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Painel Pulse"
        Width="940" Height="750"
        MinWidth="940" MinHeight="750"
        MaxWidth="940" MaxHeight="750"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#0A0A0F"
        FontFamily="Segoe UI"
        Foreground="#F4F4F4">
    
    <Window.Resources>
        <SolidColorBrush x:Key="ColorAccent" Color="#F52C42"/>
        <SolidColorBrush x:Key="SecondaryColor" Color="#181825"/>
        <SolidColorBrush x:Key="ButtonBorderColor" Color="#232334"/>
        <SolidColorBrush x:Key="SidebarColor" Color="#0F0F18"/>
        <SolidColorBrush x:Key="PanelColor" Color="#101019"/>
        <SolidColorBrush x:Key="PanelPrimaryText" Color="#F4F4F4"/>

        <Style x:Key="AccentButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource ColorAccent}"/>
            <Setter Property="Foreground" Value="#F4F4F4"/>
            <Setter Property="Padding" Value="18,8"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="BtnBorder" Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="BtnBorder" Property="Opacity" Value="0.9"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="BtnBorder" Property="Opacity" Value="0.8"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="BtnBorder" Property="Opacity" Value="0.4"/>
                                <Setter Property="Cursor" Value="Arrow"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="AppTokenToggleStyle" TargetType="ToggleButton">
            <Setter Property="Foreground" Value="#F4F4F4"/>
            <Setter Property="Background" Value="{StaticResource SecondaryColor}"/>
            <Setter Property="BorderBrush" Value="{StaticResource ButtonBorderColor}"/>
            <Setter Property="BorderThickness" Value="1.5"/>
            <Setter Property="Padding" Value="12,8"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ToggleButton">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Bd" Property="BorderBrush" Value="{StaticResource ColorAccent}"/>
                                <Setter TargetName="Bd" Property="BorderThickness" Value="1.5"/>
                                <Setter TargetName="Bd" Property="Background" Value="#1F151B"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#222235"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="NavMenuItemStyle" TargetType="ListBoxItem">
            <Setter Property="Foreground" Value="#67687B"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="14,10"/>
            <Setter Property="Margin" Value="0,0,0,6"/>
            <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ListBoxItem">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                CornerRadius="8" 
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter Property="Background" Value="#191923"/>
                                <Setter Property="BorderBrush" Value="#242436"/>
                                <Setter Property="Foreground" Value="#F4F4F4"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#12121B"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="TopTabItemStyle" TargetType="TabItem">
            <Setter Property="Foreground" Value="#515662"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="Padding" Value="14,9"/>
            <Setter Property="Margin" Value="0,0,10,0"/>
            <Setter Property="MinWidth" Value="100"/>
            <Setter Property="MinHeight" Value="30"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter Property="Background" Value="#14141D"/>
                                <Setter Property="Foreground" Value="#F4F4F4"/>
                                <Setter Property="BorderThickness" Value="1"/>
                                <Setter Property="BorderBrush" Value="#242436"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#12121B"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="TopTabsStyle" TargetType="TabControl">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Margin" Value="0,0,0,-7"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabControl">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="0"/>
                            </Grid.RowDefinitions>
                            <ScrollViewer Grid.Row="0" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Disabled">
                                <StackPanel Orientation="Horizontal" IsItemsHost="True"/>
                            </ScrollViewer>
                            <ContentPresenter Grid.Row="1" x:Name="PART_SelectedContentHost" ContentSource="SelectedContent"/>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ToggleSwitchStyle" TargetType="ToggleButton">
            <Setter Property="Width" Value="50"/>
            <Setter Property="Height" Value="25"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ToggleButton">
                        <Grid>
                            <Border x:Name="Track" CornerRadius="12" Background="#222235"/>
                            <Ellipse x:Name="Thumb" Width="18" Height="18" Fill="#C9CBD6" Margin="3.5" HorizontalAlignment="Left"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Track" Property="Background" Value="{StaticResource ColorAccent}"/>
                                <Setter TargetName="Thumb" Property="HorizontalAlignment" Value="Right"/>
                                <Setter TargetName="Thumb" Property="Fill" Value="#F4F4F4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Cards criados programaticamente pelo PowerShell -->

        <Style x:Key="HeaderUserCardStyle" TargetType="Border">
            <Setter Property="Background" Value="#0C0C12"/>
            <Setter Property="CornerRadius" Value="12"/>
            <Setter Property="BorderBrush" Value="#242436"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="14,10"/>
        </Style>

        <!-- Estilo da mensagem de lista vazia -->
        <Style x:Key="EmptyMsgStyle" TargetType="TextBlock">
            <Setter Property="Foreground" Value="#3A3B4A"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="HorizontalAlignment" Value="Center"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="TextAlignment" Value="Center"/>
            <Setter Property="Visibility" Value="Collapsed"/>
        </Style>

        <Style x:Key="LimpezaCardToggleStyle" TargetType="ToggleButton">
            <Setter Property="Background" Value="{StaticResource PanelColor}"/>
            <Setter Property="BorderBrush" Value="#242436"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Foreground" Value="{StaticResource PanelPrimaryText}"/>
            <Setter Property="Padding" Value="14,10,14,10"/>
            <Setter Property="Margin" Value="0,0,-14,10"/>
            <Setter Property="Height" Value="70"/>
            <Setter Property="HorizontalAlignment" Value="Stretch"/>
            <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ToggleButton">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="10" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Stretch" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Bd" Property="BorderBrush" Value="{StaticResource ColorAccent}"/>
                                <Setter TargetName="Bd" Property="BorderThickness" Value="1.5"/>
                                <Setter TargetName="Bd" Property="Background" Value="#15151F"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#15151F"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ScrollBar">
            <Setter Property="Background" Value="Transparent" />
            <Setter Property="Width" Value="5" />
            <Setter Property="BorderThickness" Value="0" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="{TemplateBinding Background}">
                            <Track x:Name="PART_Track" IsDirectionReversed="True">
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Border x:Name="ThumbBorder" Background="#242436" CornerRadius="4" Margin="10,0,0,0"/>
                                                <ControlTemplate.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter TargetName="ThumbBorder" Property="Background" Value="#3A3B4A"/>
                                                    </Trigger>
                                                    <Trigger Property="IsDragging" Value="True">
                                                        <Setter TargetName="ThumbBorder" Property="Background" Value="{StaticResource ColorAccent}"/>
                                                    </Trigger>
                                                </ControlTemplate.Triggers>
                                            </ControlTemplate>
                                        </Thumb.Template>
                                    </Thumb>
                                </Track.Thumb>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="Orientation" Value="Horizontal">
                    <Setter Property="Width" Value="Auto"/>
                    <Setter Property="Height" Value="5"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="ScrollBar">
                                <Grid Background="{TemplateBinding Background}">
                                    <Track x:Name="PART_Track" IsDirectionReversed="False">
                                        <Track.Thumb>
                                            <Thumb>
                                                <Thumb.Template>
                                                    <ControlTemplate TargetType="Thumb">
                                                        <Border x:Name="ThumbBorder" Background="#242436" CornerRadius="4" Margin="0,2,0,0"/>
                                                        <ControlTemplate.Triggers>
                                                            <Trigger Property="IsMouseOver" Value="True">
                                                                <Setter TargetName="ThumbBorder" Property="Background" Value="#3A3B4A"/>
                                                            </Trigger>
                                                            <Trigger Property="IsDragging" Value="True">
                                                                <Setter TargetName="ThumbBorder" Property="Background" Value="{StaticResource ColorAccent}"/>
                                                            </Trigger>
                                                        </ControlTemplate.Triggers>
                                                    </ControlTemplate>
                                                </Thumb.Template>
                                            </Thumb>
                                        </Track.Thumb>
                                    </Track>
                                </Grid>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style x:Key="SecondaryButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource SecondaryColor}"/>
            <Setter Property="Foreground" Value="#9EA7B8"/>
            <Setter Property="BorderBrush" Value="{StaticResource ButtonBorderColor}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="0,8"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="BtnBorder" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="BtnBorder" Property="Background" Value="#222235"/>
                                <Setter Property="Foreground" Value="#F4F4F4"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="BtnBorder" Property="Background" Value="#222235"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="MiniCancelButton" TargetType="Button">
            <Setter Property="Background" Value="#0A0A0F"/>
            <Setter Property="Foreground" Value="#9EA7B8"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#12121A"/>
                                <Setter Property="Foreground" Value="#F4F4F4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="MiniButtonOutlineStyle" TargetType="Button">
            <Setter Property="Background" Value="#0A0A0F"/>
            <Setter Property="Foreground" Value="#9EA7B8"/>
            <Setter Property="BorderBrush" Value="#181825"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#12121A"/>
                                <Setter Property="Foreground" Value="#F4F4F4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="MiniButtonAccentStyle" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource ColorAccent}"/>
            <Setter Property="Foreground" Value="#F4F4F4"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Opacity" Value="0.9"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="MiniButtonSecondaryStyle" TargetType="Button">
            <Setter Property="Background" Value="#181825"/>
            <Setter Property="Foreground" Value="#9EA7B8"/>
            <Setter Property="BorderBrush" Value="#232334"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#222235"/>
                                <Setter Property="Foreground" Value="#F4F4F4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="185"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <Border Grid.Column="0" Background="{StaticResource SidebarColor}">
            <Grid Margin="16,20,16,14">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0">
                    <TextBlock Text="Painel" Foreground="#67687B" FontSize="12"/>
                    <TextBlock Text="PULSE" FontWeight="ExtraBold" FontSize="22" Foreground="#F4F4F4" Margin="0,0,0,20"/>
                    <Button x:Name="BtnFazerBackup" Content="Fazer Backup" Style="{StaticResource AccentButtonStyle}" HorizontalAlignment="Stretch" Margin="0,0,0,20" Padding="0,8"/>
                </StackPanel>
                
                <ListBox x:Name="NavMenu" Grid.Row="1" Background="Transparent" BorderThickness="0" 
                         ScrollViewer.HorizontalScrollBarVisibility="Disabled"
                         ItemContainerStyle="{StaticResource NavMenuItemStyle}">

                    <ListBoxItem Tag="inicio" IsSelected="True">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="30"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" FontFamily="Segoe Fluent Icons" Text="&#xE80F;" VerticalAlignment="Center" FontSize="16"/>
                            <TextBlock Grid.Column="1" Text="Início" VerticalAlignment="Center" FontWeight="SemiBold" FontSize="13"/>
                        </Grid>
                    </ListBoxItem>
                    <ListBoxItem Tag="restaurar">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="30"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" FontFamily="Segoe Fluent Icons" Text="&#xE777;" VerticalAlignment="Center" FontSize="16"/>
                            <TextBlock Grid.Column="1" Text="Restaurar" VerticalAlignment="Center" FontWeight="SemiBold" FontSize="13"/>
                        </Grid>
                    </ListBoxItem>
                    <ListBoxItem Tag="pulsemode" Margin="0,0,0,25">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="30"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" FontFamily="Segoe Fluent Icons" Text="&#xE9D9;" VerticalAlignment="Center" FontSize="16"/>
                            <TextBlock Grid.Column="1" Text="Pulse Mode" VerticalAlignment="Center" FontWeight="SemiBold" FontSize="13"/>
                        </Grid>
                    </ListBoxItem>
                    <ListBoxItem Tag="geral">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="30"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" FontFamily="Segoe Fluent Icons" Text="&#xF42F;" VerticalAlignment="Center" FontSize="16"/>
                            <TextBlock Grid.Column="1" Text="Geral" VerticalAlignment="Center" FontWeight="SemiBold" FontSize="13"/>
                        </Grid>
                    </ListBoxItem>
                    <ListBoxItem Tag="hardware">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="30"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" FontFamily="Segoe Fluent Icons" Text="&#xEC4E;" VerticalAlignment="Center" FontSize="16"/>
                            <TextBlock Grid.Column="1" Text="Hardware" VerticalAlignment="Center" FontWeight="SemiBold" FontSize="13"/>
                        </Grid>
                    </ListBoxItem>
                    <ListBoxItem Tag="internet">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="30"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" FontFamily="Segoe Fluent Icons" Text="&#xE774;" VerticalAlignment="Center" FontSize="16"/>
                            <TextBlock Grid.Column="1" Text="Internet" VerticalAlignment="Center" FontWeight="SemiBold" FontSize="13"/>
                        </Grid>
                    </ListBoxItem>
                    <ListBoxItem Tag="limpeza">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="30"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" FontFamily="Segoe Fluent Icons" Text="&#xEA99;" VerticalAlignment="Center" FontSize="16"/>
                            <TextBlock Grid.Column="1" Text="Limpeza" VerticalAlignment="Center" FontWeight="SemiBold" FontSize="13"/>
                        </Grid>
                    </ListBoxItem>
                </ListBox>

                <Grid Grid.Row="2" Margin="0,10,0,10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <Button x:Name="BtnRestaurar" Grid.Row="0" Content="Restaurar" Style="{StaticResource SecondaryButtonStyle}" Margin="0,0,0,8"/>
                    <Button x:Name="BtnAbrirLog" Grid.Row="1" Content="Abrir Log" Style="{StaticResource SecondaryButtonStyle}"/>
                </Grid>
            </Grid>
        </Border>

        <Grid Grid.Column="1" Margin="24,24,24,24">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <Border Grid.Row="0" HorizontalAlignment="Center" Style="{StaticResource HeaderUserCardStyle}" Margin="0,0,0,20">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    
                    <StackPanel Grid.Column="0" Margin="0,0,16,0" VerticalAlignment="Center">
                        <TextBlock x:Name="LblDeviceType" Text="—" Foreground="#6F7581" FontSize="11.5"/>
                        <TextBlock x:Name="ValOS" Text="—" Foreground="#9EA7B8" FontWeight="SemiBold" FontSize="12.5"/>
                    </StackPanel>

                    <StackPanel Grid.Column="1" Margin="0,0,16,0" VerticalAlignment="Center">
                        <TextBlock Text="Processador" Foreground="#6F7581" FontSize="11.5"/>
                        <TextBlock x:Name="ValCPU" Text="—" Foreground="#9EA7B8" FontWeight="SemiBold" FontSize="12.5" TextTrimming="CharacterEllipsis" MaxWidth="160"/>
                    </StackPanel>

                    <StackPanel Grid.Column="2" Margin="0,0,16,0" VerticalAlignment="Center">
                        <TextBlock Text="Placa de Vídeo" Foreground="#6F7581" FontSize="11.5"/>
                        <TextBlock x:Name="ValGPU" Text="—" Foreground="#9EA7B8" FontWeight="SemiBold" FontSize="12.5" TextTrimming="CharacterEllipsis" MaxWidth="140"/>
                    </StackPanel>

                    <StackPanel Grid.Column="3" Margin="0,0,16,0" VerticalAlignment="Center">
                        <TextBlock Text="Memória RAM" Foreground="#6F7581" FontSize="11.5"/>
                        <TextBlock x:Name="ValRAM" Text="—" Foreground="#9EA7B8" FontWeight="SemiBold" FontSize="12.5"/>
                    </StackPanel>

                    <StackPanel Grid.Column="4" VerticalAlignment="Center">
                        <TextBlock Text="Disco" Foreground="#6F7581" FontSize="11.5"/>
                        <TextBlock x:Name="ValStorage" Text="—" Foreground="#9EA7B8" FontWeight="SemiBold" FontSize="12.5" TextTrimming="CharacterEllipsis" MaxWidth="210"/>
                    </StackPanel>
                </Grid>
            </Border>



            <Grid Grid.Row="1">

                <!-- ======== PÁGINA: INÍCIO ======== -->
                <Grid x:Name="Page_Inicio" Visibility="Visible">
                    <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Margin="0,0,-14,0">
                        <StackPanel Margin="0,0,14,20">

                            <Grid Grid.Row="0" Margin="0,0,0,16">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                    
                                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Bottom">
                                    <TextBlock Text="Instalar Aplicativos" FontSize="22" FontWeight="ExtraBold" Foreground="{StaticResource PanelPrimaryText}"/>
                                    <TextBlock Text="Pesquise e instale seus aplicativos" FontSize="13" Foreground="#6F7581" Margin="12,0,0,4" VerticalAlignment="Bottom"/>
                                </StackPanel>
                            </Grid>

                            <Border Background="{StaticResource PanelColor}" CornerRadius="10" BorderBrush="#242436" BorderThickness="1" Padding="16" Margin="0,0,0,15">
                                <StackPanel>
                                    <Grid Margin="0,0,0,16">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <Border Grid.Column="0" Background="#191923" CornerRadius="6" BorderBrush="#242436" BorderThickness="1" Margin="0,0,10,0">
                                            <Grid>
                                                <TextBlock FontFamily="Segoe Fluent Icons" Text="&#xE721;" Foreground="#6F7581" VerticalAlignment="Center" Margin="10,0,0,0" FontSize="14"/>
                                                <TextBox x:Name="TxtSearchApp" Background="Transparent" Foreground="#F4F4F4" BorderThickness="0" VerticalAlignment="Center" Margin="30,0,10,0" Padding="0,8" FontSize="13"/>
                                            </Grid>
                                        </Border>
                                        <Button x:Name="BtnSearchApp" Grid.Column="1" Content="Pesquisar" Style="{StaticResource SecondaryButtonStyle}" Padding="16,8"/>
                                    </Grid>
                                    
                                    <TextBlock Text="Aplicativos Selecionados" Foreground="#9EA7B8" FontSize="12" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                    <Border Background="#15151F" CornerRadius="8" BorderBrush="#242436" BorderThickness="1" MinHeight="50" Padding="10,10,10,2" Margin="0,0,0,16">
                                        <WrapPanel x:Name="SelectedAppsPanel" Orientation="Horizontal"/>
                                    </Border>

                                    <Button x:Name="BtnInstallApps" Content="Instalar Selecionados" Style="{StaticResource AccentButtonStyle}" HorizontalAlignment="Stretch" IsEnabled="False" Padding="16,10" FontSize="14"/>
                                </StackPanel>
                            </Border>

                            <Grid Grid.Row="0" Margin="0,0,0,16">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                    
                                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Bottom">
                                    <TextBlock Text="Gerenciar Aplicativos" FontSize="22" FontWeight="ExtraBold" Foreground="{StaticResource PanelPrimaryText}"/>
                                    <TextBlock Text="Gerencie a inicialização e desinstale aplicativos" FontSize="13" Foreground="#6F7581" Margin="12,0,0,4" VerticalAlignment="Bottom"/>
                                </StackPanel>
                            </Grid>

                            <Border Background="{StaticResource PanelColor}" CornerRadius="10" BorderBrush="#242436" BorderThickness="1" Padding="20">
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="30"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    
                                    <StackPanel Grid.Column="0">
                                        <TextBlock Text="Inicialização" FontSize="16" FontWeight="SemiBold" Foreground="{StaticResource PanelPrimaryText}" Margin="0,-5,0,8"/>
                                        <StackPanel Orientation="Horizontal" Margin="0,0,0,16">
                                            <TextBlock x:Name="LblStartupActive" Text="--" FontSize="24" FontWeight="Bold" Foreground="#F4F4F4"/>
                                            <TextBlock Text="ativos" Foreground="#6F7581" FontSize="13" VerticalAlignment="Bottom" Margin="6,0,0,5"/>
                                        </StackPanel>
                                        <Button x:Name="BtnOpenStartupModal" Content="Gerenciar Inicialização" Style="{StaticResource AccentButtonStyle}" HorizontalAlignment="Stretch" Padding="0,8" FontSize="13" IsEnabled="False"/>
                                    </StackPanel>
                                    
                                    <Border Grid.Column="1" Width="1" Background="#242436" Margin="0,10"/>
                                    
                                    <StackPanel Grid.Column="2">
                                        <TextBlock Text="Desinstalar" FontSize="16" FontWeight="SemiBold" Foreground="{StaticResource PanelPrimaryText}" Margin="0,-5,0,8"/>
                                        <StackPanel Orientation="Horizontal" Margin="0,0,0,16">
                                            <TextBlock x:Name="LblInstalledCount" Text="--" FontSize="24" FontWeight="Bold" Foreground="#F4F4F4"/>
                                            <TextBlock Text="apps" Foreground="#6F7581" FontSize="13" VerticalAlignment="Bottom" Margin="6,0,16,5"/>
                                            <TextBlock x:Name="LblSystemCount" Text="--" FontSize="24" FontWeight="Bold" Foreground="#F4F4F4"/>
                                            <TextBlock Text="sistema" Foreground="#6F7581" FontSize="13" VerticalAlignment="Bottom" Margin="6,0,0,5"/>
                                        </StackPanel>
                                        <Button x:Name="BtnOpenUninstallerModal" Content="Desinstalar" Style="{StaticResource AccentButtonStyle}" HorizontalAlignment="Stretch" Padding="0,8" FontSize="13" IsEnabled="False"/>
                                    </StackPanel>
                                </Grid>
                            </Border>

                        </StackPanel>
                    </ScrollViewer>
                </Grid>

                <!-- ======== PÁGINA: RESTAURAR ======== -->
                <Grid x:Name="Page_Restaurar" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Orientation="Horizontal" VerticalAlignment="Bottom" Margin="0,0,0,16">
                        <TextBlock Text="Restaurar" FontSize="22" FontWeight="ExtraBold" Foreground="{StaticResource PanelPrimaryText}"/>
                        <TextBlock Text="Restaure funcionalidades que foram desativadas na instalação do Windows." FontSize="13" Foreground="#6F7581" Margin="12,0,0,4" VerticalAlignment="Bottom"/>
                    </StackPanel>

                    <Border Grid.Row="1" Background="#1A1111" BorderBrush="#3D2020" BorderThickness="1" CornerRadius="8" Padding="12,8" Margin="0,0,0,16">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock FontFamily="Segoe Fluent Icons" Text="&#xE7BA;" Foreground="#F52C42" FontSize="14" VerticalAlignment="Center" Margin="0,0,10,0"/>
                            <TextBlock Text="Algumas foram desativadas na instalação do Windows, não há garantia de que voltará a funcionar corretamente." Foreground="#D68383" FontSize="12.5" VerticalAlignment="Center" FontWeight="SemiBold"/>
                        </StackPanel>
                    </Border>

                    <Grid Grid.Row="2">
                        <ScrollViewer x:Name="Scroll_Restaurar" VerticalScrollBarVisibility="Auto">
                            <StackPanel x:Name="Items_Restaurar" HorizontalAlignment="Stretch" Margin="0,0,0,0"/>
                        </ScrollViewer>
                        <TextBlock x:Name="Msg_Restaurar"
                                   Text="Nenhuma opção de restauração disponível no momento."
                                   Style="{StaticResource EmptyMsgStyle}"/>
                    </Grid>
                </Grid>

                <!-- ======== PÁGINA: PULSE MODE ======== -->
                <Grid x:Name="Page_PulseMode" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Border Grid.Row="0" Background="Transparent" CornerRadius="10" BorderThickness="0" Padding="20,6,20,10" Margin="0,0,10,0">
                        <StackPanel>
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>

                                <StackPanel Grid.Column="0" VerticalAlignment="Center" HorizontalAlignment="Left">
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="Auto"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <Border x:Name="LedPulseModeMaster" Grid.Column="0" Width="10" Height="10" CornerRadius="4" Background="#3A3B4A" VerticalAlignment="Center" Margin="0,2.5,10,0"/>
                                        <TextBlock Grid.Column="1" Text="Pulse Mode" FontSize="20" FontWeight="Black" Foreground="#C9CBD6" VerticalAlignment="Center"/>
                                    </Grid>
                                    <TextBlock Text="Otimizações exclusivas e controle centralizado do sistema." FontSize="13" Foreground="#6F7581" Margin="0,0,0,4" VerticalAlignment="Bottom"/>
                                </StackPanel>
                                
                                <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Right">
                                    <StackPanel VerticalAlignment="Center" Margin="0,0,24,0">
                                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,3">
                                            <TextBlock Text="Ativado" FontSize="11" Foreground="#C9CBD6" FontWeight="SemiBold" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                            <Border Width="8" Height="8" CornerRadius="4" Background="{StaticResource ColorAccent}" Margin="2,0"/>
                                            <Border Width="8" Height="8" CornerRadius="4" Background="{StaticResource ColorAccent}" Margin="2,0"/>
                                            <Border Width="8" Height="8" CornerRadius="4" Background="{StaticResource ColorAccent}" Margin="2,0"/>
                                            <Border Width="8" Height="8" CornerRadius="4" Background="{StaticResource ColorAccent}" Margin="2,0"/>
                                            <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                        </StackPanel>
                                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,3">
                                            <TextBlock Text="Desativado" FontSize="11" Foreground="#6F7581" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                            <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                            <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                            <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                            <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                            <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                        </StackPanel>
                                        <TextBlock Text="Desempenho | Mais = Melhor" FontSize="10" Foreground="#515662" HorizontalAlignment="Right"/>
                                    </StackPanel>
                                    
                                    <ToggleButton x:Name="TglPulseModeMaster" Style="{StaticResource ToggleSwitchStyle}" VerticalAlignment="Center" RenderTransformOrigin="0.5,0.5" Margin="0,0,15,0">
                                        <ToggleButton.RenderTransform>
                                            <ScaleTransform ScaleX="1.1" ScaleY="1.1"/>
                                        </ToggleButton.RenderTransform>
                                    </ToggleButton>

                                    <ToggleButton x:Name="BtnExpandPulse" Background="Transparent" BorderThickness="0" Foreground="#6F7581" Cursor="Hand" VerticalAlignment="Center">
                                        <ToggleButton.Template>
                                            <ControlTemplate TargetType="ToggleButton">
                                                <TextBlock x:Name="Chevron" FontFamily="Segoe Fluent Icons" Text="&#xE70D;" FontSize="16" FontWeight="Bold"/>
                                                <ControlTemplate.Triggers>
                                                    <Trigger Property="IsChecked" Value="True">
                                                        <Setter TargetName="Chevron" Property="Text" Value="&#xE70E;"/>
                                                        <Setter Property="Foreground" Value="#F4F4F4"/>
                                                    </Trigger>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter Property="Foreground" Value="#F4F4F4"/>
                                                    </Trigger>
                                                </ControlTemplate.Triggers>
                                            </ControlTemplate>
                                        </ToggleButton.Template>
                                    </ToggleButton>
                                </StackPanel>
                            </Grid>

                            <Grid x:Name="PanelPulseExpanded" Visibility="Collapsed" Margin="0,10,0,0">
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                <Border Grid.Row="0" Height="0.5" Background="#242436" Margin="0,0,0,12"/>
                                <Grid Grid.Row="1" Margin="0,0,0,8">
                                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                        <Border x:Name="LedPulseSubGeral" Width="8" Height="8" CornerRadius="4" Background="#3A3B4A" Margin="0,0,10,0"/>
                                        <TextBlock Text="Geral" FontSize="14" FontWeight="SemiBold" Foreground="#C9CBD6"/>
                                    </StackPanel>
                                    <ToggleButton x:Name="TglPulseSubGeral" Style="{StaticResource ToggleSwitchStyle}" HorizontalAlignment="Right" Margin="0,0,5,0"/>
                                </Grid>
                                <Grid Grid.Row="2" Margin="0,0,0,8">
                                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                        <Border x:Name="LedPulseSubHardware" Width="8" Height="8" CornerRadius="4" Background="#3A3B4A" Margin="0,0,10,0"/>
                                        <TextBlock Text="Hardware" FontSize="14" FontWeight="SemiBold" Foreground="#C9CBD6"/>
                                    </StackPanel>
                                    <ToggleButton x:Name="TglPulseSubHardware" Style="{StaticResource ToggleSwitchStyle}" HorizontalAlignment="Right" Margin="0,0,5,0"/>
                                </Grid>
                                <Grid Grid.Row="3">
                                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                        <Border x:Name="LedPulseSubInternet" Width="8" Height="8" CornerRadius="4" Background="#3A3B4A" Margin="0,0,10,0"/>
                                        <TextBlock Text="Internet" FontSize="14" FontWeight="SemiBold" Foreground="#C9CBD6"/>
                                    </StackPanel>
                                    <ToggleButton x:Name="TglPulseSubInternet" Style="{StaticResource ToggleSwitchStyle}" HorizontalAlignment="Right" Margin="0,0,5,0"/>
                                </Grid>
                            </Grid>
                        </StackPanel>
                    </Border>

                    <TabControl x:Name="Tabs_PulseMode" Grid.Row="1" Style="{StaticResource TopTabsStyle}">
                        <TabItem Style="{StaticResource TopTabItemStyle}" Tag="pulsemode">
                            <TabItem.Header>
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock FontFamily="Segoe Fluent Icons" Text="&#xE9D9;" FontSize="15" FontWeight="Regular" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                    <TextBlock Text="Pulse Mode" VerticalAlignment="Center" Margin="0,0,0,2"/>
                                </StackPanel>
                            </TabItem.Header>
                        </TabItem>
                        
                        <TabItem x:Name="Tab_Pulse_Geral" Style="{StaticResource TopTabItemStyle}" Tag="pulse_dyn_geral" Visibility="Collapsed">
                            <TabItem.Header>
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock FontFamily="Segoe Fluent Icons" Text="&#xF42F;" FontSize="15" FontWeight="Regular" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                    <TextBlock Text="Geral" VerticalAlignment="Center" Margin="0,0,0,2"/>
                                </StackPanel>
                            </TabItem.Header>
                        </TabItem>

                        <TabItem x:Name="Tab_Pulse_Hardware" Style="{StaticResource TopTabItemStyle}" Tag="pulse_dyn_hardware" Visibility="Collapsed">
                            <TabItem.Header>
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock FontFamily="Segoe Fluent Icons" Text="&#xEC4E;" FontSize="15" FontWeight="Regular" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                    <TextBlock Text="Hardware" VerticalAlignment="Center" Margin="0,0,0,2"/>
                                </StackPanel>
                            </TabItem.Header>
                        </TabItem>

                        <TabItem x:Name="Tab_Pulse_Internet" Style="{StaticResource TopTabItemStyle}" Tag="pulse_dyn_internet" Visibility="Collapsed">
                            <TabItem.Header>
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock FontFamily="Segoe Fluent Icons" Text="&#xE774;" FontSize="15" FontWeight="Regular" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                    <TextBlock Text="Internet" VerticalAlignment="Center" Margin="0,0,0,2"/>
                                </StackPanel>
                            </TabItem.Header>
                        </TabItem>
                    </TabControl>

                    <Grid Grid.Row="2" Margin="0,16,0,0">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <Border x:Name="PulseWarningBox" Grid.Row="0" Background="#1A1111" BorderBrush="#3D2020" BorderThickness="1" CornerRadius="8" Padding="12,8" Margin="0,0,0,10" Visibility="Collapsed">
                            <StackPanel Orientation="Horizontal">
                                <TextBlock FontFamily="Segoe Fluent Icons" Text="&#xE7BA;" Foreground="#F52C42" FontSize="14" VerticalAlignment="Center" Margin="0,0,10,0"/>
                                <TextBlock Text="Algumas otimizações podem desativar recursos de segurança e alterar componentes sensíveis do sistema." Foreground="#D68383" FontSize="12.5" VerticalAlignment="Center" FontWeight="SemiBold"/>
                            </StackPanel>
                        </Border>

                        <ScrollViewer x:Name="Scroll_PulseMode" Grid.Row="1" VerticalScrollBarVisibility="Auto">
                            <StackPanel x:Name="Items_PulseMode" HorizontalAlignment="Stretch" Margin="0,0,0,0"/>
                        </ScrollViewer>
                        <TextBlock x:Name="Msg_PulseMode" Grid.Row="1" Text="Nenhuma otimização exclusiva carregada no momento." Style="{StaticResource EmptyMsgStyle}"/>
                    </Grid>
                </Grid>

                <!-- ======== PÁGINA: GERAL ======== -->
                <Grid x:Name="Page_Geral" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Orientation="Horizontal" VerticalAlignment="Bottom">
                        <TextBlock Text="Geral" FontSize="22" FontWeight="ExtraBold" Foreground="{StaticResource PanelPrimaryText}"/>
                        <TextBlock Text="Ajuste configurações do sistema, privacidade e experiência de uso." FontSize="13" Foreground="#6F7581" Margin="12,0,0,4" VerticalAlignment="Bottom"/>
                    </StackPanel>

                    <Border Grid.Row="1" Background="Transparent" CornerRadius="10" BorderThickness="0" Padding="20,6,20,10" Margin="0,0,10,0">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>

                            <StackPanel Grid.Column="0" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,24,0">
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>

                                    <Border x:Name="LedPulseModeGeral" Grid.Column="0" Width="10" Height="10" CornerRadius="4" Background="#3A3B4A" VerticalAlignment="Center" Margin="0,2.5,0,0"/>
                                    <TextBlock Grid.Column="1" Text="Pulse Mode" FontSize="20" FontWeight="Black" Foreground="#C9CBD6" VerticalAlignment="Center" Margin="10,0,0,0"/>
                                </Grid>
                                <TextBlock Text="Reduz processos, blotwares e melhora a fluidez." FontSize="11.5" Foreground="#6F7581" VerticalAlignment="Bottom"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Column="1" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,24,0">
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,3">
                                    <TextBlock Text="Ativado" FontSize="11" Foreground="#C9CBD6" FontWeight="SemiBold" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="{StaticResource ColorAccent}" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="{StaticResource ColorAccent}" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                </StackPanel>
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,3">
                                    <TextBlock Text="Desativado" FontSize="11" Foreground="#6F7581" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                </StackPanel>
                                <TextBlock Text="Uso de Recursos | Menos = Melhor" FontSize="10" Foreground="#515662" HorizontalAlignment="Right"/>
                            </StackPanel>
                            
                            <ToggleButton x:Name="TglPulseModeGeral" Grid.Column="2" Style="{StaticResource ToggleSwitchStyle}" VerticalAlignment="Center" RenderTransformOrigin="0.5,0.5" Margin="0,0,10,0">
                                <ToggleButton.RenderTransform>
                                    <ScaleTransform ScaleX="1.1" ScaleY="1.1"/>
                                </ToggleButton.RenderTransform>
                            </ToggleButton>
                        </Grid>
                    </Border>

                    <TabControl x:Name="Tabs_Geral" Grid.Row="2" Style="{StaticResource TopTabsStyle}">
                        <TabItem Header="Geral"       Style="{StaticResource TopTabItemStyle}" Tag="geral_geral"/>
                        <TabItem Header="Experiência" Style="{StaticResource TopTabItemStyle}" Tag="geral_exp"/>
                        <TabItem Header="Privacidade" Style="{StaticResource TopTabItemStyle}" Tag="geral_priv"/>
                    </TabControl>

                    <!-- Conteúdo: lista ou mensagem de vazio -->
                    <Grid Grid.Row="3" Margin="0,16,0,0">
                        <ScrollViewer x:Name="Scroll_Geral" VerticalScrollBarVisibility="Auto">
                            <StackPanel x:Name="Items_Geral" HorizontalAlignment="Stretch" Margin="0,0,0,0"/>
                        </ScrollViewer>
                        <TextBlock x:Name="Msg_Geral"
                                   Text="Nenhuma otimização disponível para esta aba."
                                   Style="{StaticResource EmptyMsgStyle}"/>
                    </Grid>
                </Grid>

                <!-- ======== PÁGINA: HARDWARE ======== -->
                <Grid x:Name="Page_Hardware" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Orientation="Horizontal" VerticalAlignment="Bottom">
                        <TextBlock Text="Hardware" FontSize="22" FontWeight="ExtraBold" Foreground="{StaticResource PanelPrimaryText}"/>
                        <TextBlock Text="Configure seu hardware para obter máxima fluidez e resposta." FontSize="13" Foreground="#6F7581" Margin="12,0,0,4" VerticalAlignment="Bottom"/>
                    </StackPanel>

                    <Border Grid.Row="1" Background="Transparent" CornerRadius="10" BorderThickness="0" Padding="20,6,20,10" Margin="0,0,10,0">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>

                            <StackPanel Grid.Column="0" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,24,0">
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>

                                    <Border x:Name="LedPulseModeHardware" Grid.Column="0" Width="10" Height="10" CornerRadius="4" Background="#3A3B4A" VerticalAlignment="Center" Margin="0,2.5,0,0"/>
                                    <TextBlock Grid.Column="1" Text="Pulse Mode" FontSize="20" FontWeight="Black" Foreground="#C9CBD6" VerticalAlignment="Center" Margin="10,0,0,0"/>
                                </Grid>
                                <TextBlock Text="Ajuste inteligente para extrair o máximo de desempenho." FontSize="11.5" Foreground="#6F7581" VerticalAlignment="Bottom"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Column="1" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,24,0">
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,3">
                                    <TextBlock Text="Ativado" FontSize="11" Foreground="#C9CBD6" FontWeight="SemiBold" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="{StaticResource ColorAccent}" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="{StaticResource ColorAccent}" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="{StaticResource ColorAccent}" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="{StaticResource ColorAccent}" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                </StackPanel>
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,3">
                                    <TextBlock Text="Desativado" FontSize="11" Foreground="#6F7581" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                </StackPanel>
                                <TextBlock Text="Responsividade | Mais = Melhor" FontSize="10" Foreground="#515662" HorizontalAlignment="Right"/>
                            </StackPanel>
                            
                            <ToggleButton x:Name="TglPulseModeHardware" Grid.Column="2" Style="{StaticResource ToggleSwitchStyle}" VerticalAlignment="Center" RenderTransformOrigin="0.5,0.5" Margin="0,0,10,0">
                                <ToggleButton.RenderTransform>
                                    <ScaleTransform ScaleX="1.1" ScaleY="1.1"/>
                                </ToggleButton.RenderTransform>
                            </ToggleButton>
                        </Grid>
                    </Border>

                    <TabControl x:Name="Tabs_Hardware" Grid.Row="2" Style="{StaticResource TopTabsStyle}">
                        <TabItem Header="Placa de Vídeo"  Style="{StaticResource TopTabItemStyle}" Tag="hw_gpu"/>
                        <TabItem Header="Processador"     Style="{StaticResource TopTabItemStyle}" Tag="hw_cpu"/>
                        <TabItem Header="Memória RAM"             Style="{StaticResource TopTabItemStyle}" Tag="hw_ram"/>
                        <TabItem Header="Periféricos"   Style="{StaticResource TopTabItemStyle}" Tag="hw_perifericos"/>
                        <TabItem Header="Disco"           Style="{StaticResource TopTabItemStyle}" Tag="hw_storage"/>
                    </TabControl>

                    <Grid Grid.Row="3" Margin="0,16,0,0">
                        <ScrollViewer x:Name="Scroll_Hardware" VerticalScrollBarVisibility="Auto">
                            <StackPanel x:Name="Items_Hardware" HorizontalAlignment="Stretch" Margin="0,0,0,0"/>
                        </ScrollViewer>
                        <TextBlock x:Name="Msg_Hardware"
                                   Text="Nenhuma otimização disponível para esta aba."
                                   Style="{StaticResource EmptyMsgStyle}"/>
                    </Grid>
                </Grid>

                <!-- ======== PÁGINA: INTERNET ======== -->
                <Grid x:Name="Page_Internet" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <StackPanel Grid.Row="0" Orientation="Horizontal" VerticalAlignment="Bottom">
                        <TextBlock Text="Internet" FontSize="22" FontWeight="ExtraBold" Foreground="{StaticResource PanelPrimaryText}"/>
                        <TextBlock Text="Otimize sua conexão e configurações de rede" FontSize="13" Foreground="#6F7581" Margin="12,0,0,0" VerticalAlignment="Center"/>
                    </StackPanel>

                    <Border Grid.Row="1" Background="Transparent" CornerRadius="10" BorderThickness="0" Padding="20,6,20,10" Margin="0,0,10,0">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>

                            <StackPanel Grid.Column="0" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,24,0">
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                
                                    <Border x:Name="LedPulseModeInternet" Grid.Column="0" Width="10" Height="10" CornerRadius="4" Background="#3A3B4A" VerticalAlignment="Center" Margin="0,2.5,0,0"/>
                                    <TextBlock Grid.Column="1" Text="Pulse Mode" FontSize="20" FontWeight="Black" Foreground="#C9CBD6" VerticalAlignment="Center" Margin="10,0,0,0"/>
                                </Grid>
                                <TextBlock Text="Ajuste inteligente para desativar limitações e garantir uma menor latência." FontSize="11.5" Foreground="#6F7581" VerticalAlignment="Bottom"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Column="1" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,24,0">
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,3">
                                    <TextBlock Text="Ativado" FontSize="11" Foreground="#C9CBD6" FontWeight="SemiBold" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="{StaticResource ColorAccent}" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="{StaticResource ColorAccent}" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                </StackPanel>
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,3">
                                    <TextBlock Text="Desativado" FontSize="11" Foreground="#6F7581" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" Background="#6F7581" Margin="2,0"/>
                                    <Border Width="8" Height="8" CornerRadius="4" BorderBrush="#3A3B4A" BorderThickness="1.5" Margin="2,0"/>
                                </StackPanel>
                                <TextBlock Text="Latência | Menos = Melhor" FontSize="10" Foreground="#515662" HorizontalAlignment="Right"/>
                            </StackPanel>
                            
                            <ToggleButton x:Name="TglPulseModeInternet" Grid.Column="2" Style="{StaticResource ToggleSwitchStyle}" VerticalAlignment="Center" RenderTransformOrigin="0.5,0.5" Margin="0,0,10,0">
                                <ToggleButton.RenderTransform>
                                    <ScaleTransform ScaleX="1.1" ScaleY="1.1"/>
                                </ToggleButton.RenderTransform>
                            </ToggleButton>
                        </Grid>
                    </Border>

                    <Grid Grid.Row="2">
                        <ScrollViewer x:Name="Scroll_Internet" VerticalScrollBarVisibility="Auto">
                            <StackPanel x:Name="Items_Internet" HorizontalAlignment="Stretch" Margin="0,0,0,0"/>
                        </ScrollViewer>
                        <TextBlock x:Name="Msg_Internet"
                                   Text="Nenhuma otimização disponível para esta página."
                                   Style="{StaticResource EmptyMsgStyle}"/>
                    </Grid>
                </Grid>

                <!-- ======== PÁGINA: LIMPEZA ======== -->
                <Grid x:Name="Page_Limpeza" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                        
                    <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Bottom">
                        <TextBlock Text="Limpeza" FontSize="22" FontWeight="ExtraBold" Foreground="{StaticResource PanelPrimaryText}"/>
                    </StackPanel>

                    <Grid Grid.Row="1" Margin="0,0,0,10">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>

                        <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,15,0">
                            <TextBlock Text="Selecione os itens e realize uma limpeza no sistema" FontSize="13" Foreground="#6F7581" Margin="0,0,0,4" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                        </StackPanel>

                        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,15,0">
                            <Button x:Name="BtnLimpezaNenhuma" Content="&#xE711;" FontFamily="Segoe Fluent Icons" FontSize="12" Style="{StaticResource MiniCancelButton}" Margin="0,0,8,0" ToolTip="Limpar Seleção"/>
                            <Button x:Name="BtnLimpezaRecomendada" Content="Recomendada" Style="{StaticResource MiniButtonAccentStyle}" Margin="0,0,8,0"/>
                            <Button x:Name="BtnLimpezaTudo" Content="Selecionar Tudo" Style="{StaticResource MiniButtonOutlineStyle}"/>
                        </StackPanel>
                    </Grid>
                    
                    <Grid Grid.Row="2">
                        <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,0,0,50">
                            <StackPanel x:Name="LimpezaGrid" VerticalAlignment="Top" Margin="0,0,15,0"/>
                        </ScrollViewer>
                        
                        <Button x:Name="BtnIniciarLimpeza" Content="Iniciar Limpeza" Style="{StaticResource AccentButtonStyle}" HorizontalAlignment="Stretch" VerticalAlignment="Bottom" IsEnabled="False" Padding="16,10" FontSize="18" Margin="0,0,17,0">
                            <Button.Effect>
                                <DropShadowEffect Color="#000000" Direction="270" ShadowDepth="4" BlurRadius="20" Opacity="0.5"/>
                            </Button.Effect>
                        </Button>
                    </Grid>
                </Grid>

            </Grid>
        </Grid>
    </Grid>
</Window>
'@

# ==========================================
# LÓGICA DE FUNCIONAMENTO E EVENTOS
# ==========================================
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# --- Mapeamento de elementos da UI ---
$script:NavMenu          = $window.FindName('NavMenu')
$script:BtnFazerBackup   = $window.FindName('BtnFazerBackup')
$script:BtnRestaurar     = $window.FindName('BtnRestaurar')
$script:BtnAbrirLog      = $window.FindName('BtnAbrirLog')

$script:Scroll_Restaurar = $window.FindName('Scroll_Restaurar')
$script:Items_Restaurar  = $window.FindName('Items_Restaurar')
$script:Msg_Restaurar    = $window.FindName('Msg_Restaurar')

$script:Page_PulseMode     = $window.FindName('Page_PulseMode')
$script:Scroll_PulseMode   = $window.FindName('Scroll_PulseMode')
$script:Items_PulseMode    = $window.FindName('Items_PulseMode')
$script:Msg_PulseMode      = $window.FindName('Msg_PulseMode')
$script:Tabs_PulseMode     = $window.FindName('Tabs_PulseMode')
$script:Tab_Pulse_Geral    = $window.FindName('Tab_Pulse_Geral')
$script:Tab_Pulse_Hardware = $window.FindName('Tab_Pulse_Hardware')
$script:Tab_Pulse_Internet = $window.FindName('Tab_Pulse_Internet')
$script:PulseWarningBox = $window.FindName('PulseWarningBox')

$script:BtnExpandPulse     = $window.FindName('BtnExpandPulse')
$script:PanelPulseExpanded = $window.FindName('PanelPulseExpanded')

$script:TglPulseModeMaster = $window.FindName('TglPulseModeMaster')
$script:LedPulseModeMaster = $window.FindName('LedPulseModeMaster')
$script:TglPulseSubGeral   = $window.FindName('TglPulseSubGeral')
$script:LedPulseSubGeral   = $window.FindName('LedPulseSubGeral')
$script:TglPulseSubHardware = $window.FindName('TglPulseSubHardware')
$script:LedPulseSubHardware = $window.FindName('LedPulseSubHardware')
$script:TglPulseSubInternet = $window.FindName('TglPulseSubInternet')
$script:LedPulseSubInternet = $window.FindName('LedPulseSubInternet')

$script:Tabs_Geral       = $window.FindName('Tabs_Geral')
$script:Scroll_Geral     = $window.FindName('Scroll_Geral')
$script:Items_Geral      = $window.FindName('Items_Geral')
$script:Msg_Geral        = $window.FindName('Msg_Geral')
$script:TglPulseModeGeral    = $window.FindName('TglPulseModeGeral')
$script:LedPulseModeGeral    = $window.FindName('LedPulseModeGeral')

$script:Tabs_Hardware    = $window.FindName('Tabs_Hardware')
$script:Scroll_Hardware  = $window.FindName('Scroll_Hardware')
$script:Items_Hardware   = $window.FindName('Items_Hardware')
$script:Msg_Hardware     = $window.FindName('Msg_Hardware')
$script:TglPulseModeHardware = $window.FindName('TglPulseModeHardware')
$script:LedPulseModeHardware = $window.FindName('LedPulseModeHardware')

$script:Scroll_Internet  = $window.FindName('Scroll_Internet')
$script:Items_Internet   = $window.FindName('Items_Internet')
$script:Msg_Internet     = $window.FindName('Msg_Internet')
$script:TglPulseModeInternet = $window.FindName('TglPulseModeInternet')
$script:LedPulseModeInternet = $window.FindName('LedPulseModeInternet')

$script:BtnLimpezaNenhuma     = $window.FindName('BtnLimpezaNenhuma')
$script:BtnLimpezaRecomendada = $window.FindName('BtnLimpezaRecomendada')
$script:BtnLimpezaTudo        = $window.FindName('BtnLimpezaTudo')
$script:LimpezaGrid       = $window.FindName('LimpezaGrid')
$script:BtnIniciarLimpeza = $window.FindName('BtnIniciarLimpeza')

$script:BtnFazerBackup   = $window.FindName('BtnFazerBackup')
$script:TxtSearchApp     = $window.FindName('TxtSearchApp')
$script:BtnSearchApp     = $window.FindName('BtnSearchApp')
$script:SelectedAppsPanel= $window.FindName('SelectedAppsPanel')
$script:BtnInstallApps   = $window.FindName('BtnInstallApps')
$script:LblStartupActive        = $window.FindName('LblStartupActive')
$script:BtnOpenStartupModal     = $window.FindName('BtnOpenStartupModal')
$script:LblInstalledCount       = $window.FindName('LblInstalledCount')
$script:LblSystemCount          = $window.FindName('LblSystemCount')
$script:BtnOpenUninstallerModal = $window.FindName('BtnOpenUninstallerModal')

if ($script:PulseState["Master_Geral"]) {
    $script:TglPulseModeGeral.IsChecked = $true
    $script:LedPulseModeGeral.Background = $window.Resources["ColorAccent"]
}
if ($script:PulseState["Master_Hardware"]) {
    $script:TglPulseModeHardware.IsChecked = $true
    $script:LedPulseModeHardware.Background = $window.Resources["ColorAccent"]
}
if ($script:PulseState["Master_Internet"]) {
    $script:TglPulseModeInternet.IsChecked = $true
    $script:LedPulseModeInternet.Background = $window.Resources["ColorAccent"]
}

$script:Page_Inicio      = $window.FindName('Page_Inicio')
$script:Page_Restaurar   = $window.FindName('Page_Restaurar')
$script:Page_Geral       = $window.FindName('Page_Geral')
$script:Page_Hardware    = $window.FindName('Page_Hardware')
$script:Page_Internet    = $window.FindName('Page_Internet')
$script:Page_Limpeza     = $window.FindName('Page_Limpeza')

function Write-PulseLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Add-Content -Path $script:LogFile -Value "[$timestamp] $Message" -Encoding UTF8
}
Write-PulseLog "Painel Pulse iniciado."

# --- Cria um card de otimização programaticamente e anexa o evento diretamente ---
function New-OptCard {
    param($item, [System.Windows.ResourceDictionary]$res)

    $panelColor  = $res['PanelColor']
    $primaryText = $res['PanelPrimaryText']
    $toggleStyle = $res['ToggleSwitchStyle']

    $border = [System.Windows.Controls.Border]::new()
    $border.Background      = $panelColor
    $border.CornerRadius    = [System.Windows.CornerRadius]::new(10)
    $border.BorderBrush     = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#242436')
    $border.BorderThickness = [System.Windows.Thickness]::new(1)
    $border.Padding         = [System.Windows.Thickness]::new(14,10,14,10)
    $border.Height          = 70
    $border.Margin          = [System.Windows.Thickness]::new(0,0,0,10)
    $border.HorizontalAlignment = 'Stretch'

    $grid = [System.Windows.Controls.Grid]::new()
    $grid.VerticalAlignment = 'Center'
    $r0 = [System.Windows.Controls.RowDefinition]::new(); $r0.Height = 'Auto'
    $r1 = [System.Windows.Controls.RowDefinition]::new(); $r1.Height = 'Auto'
    $grid.RowDefinitions.Add($r0); $grid.RowDefinitions.Add($r1)
    $c0 = [System.Windows.Controls.ColumnDefinition]::new(); $c0.Width = '*'
    $c1 = [System.Windows.Controls.ColumnDefinition]::new(); $c1.Width = 'Auto'
    $grid.ColumnDefinitions.Add($c0); $grid.ColumnDefinitions.Add($c1)

    # --- Linha do Nome com Ícones de Foco/Favorito ---
    $nameRow = [System.Windows.Controls.StackPanel]::new()
    $nameRow.Orientation = 'Horizontal'
    $nameRow.VerticalAlignment = 'Center'
    $nameRow.Margin = [System.Windows.Thickness]::new(0,0,14,0)
    [System.Windows.Controls.Grid]::SetRow($nameRow, 0)
    [System.Windows.Controls.Grid]::SetColumn($nameRow, 0)

    # Ícone de Favorito (amarelo, estrela)
    $favVal = ([string]$item.Favorito).Trim().ToLower()
    if ($favVal -eq 'sim') {
        $icoFav = [System.Windows.Controls.TextBlock]::new()
        $icoFav.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe Fluent Icons")
        $icoFav.Text = [char]0xe735
        $icoFav.FontSize = 12
        $icoFav.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#FFD700')
        $icoFav.VerticalAlignment = 'Center'
        $icoFav.Margin = [System.Windows.Thickness]::new(0,0,7,0)
        $null = $nameRow.Children.Add($icoFav)
    }

    $tbName = [System.Windows.Controls.TextBlock]::new()
    $tbName.Text = $item.Name; $tbName.FontSize = 14
    $tbName.FontWeight = [System.Windows.FontWeights]::SemiBold
    $tbName.Foreground = $primaryText
    $tbName.VerticalAlignment = 'Center'
    $tbName.TextTrimming = 'CharacterEllipsis'
    $null = $nameRow.Children.Add($tbName)

    # Ícone de Foco (ao lado do nome, cor de texto secundário)
    $focoMap = @{
        'jogos'       = 0xe7fc
        'segurança'   = 0xea18
        'visual'      = 0xf4a5
        'windows'     = 0xec4a
        'privacidade' = 0xed1a
    }
    $focoSizeMap = @{
        'jogos'     = 17
        'segurança' = 15
        'visual'    = 16
        'windows'   = 16
        'privacidade' = 15
    }
    $focoTooltipMap = @{
        'jogos'     = "Prioriza recursos para o ambiente de jogo, melhorando o desempenho e reduzindo latência."
        'segurança' = "Desativa recursos de segurança do Windows, o sistema pode ficar vulnerável."
        'visual'    = "Ajusta animações, efeitos e aparência do sistema. Geralmente não impacta o desempenho."
        'windows'   = "Melhorar a responsividade e fluidez do Windows sem necessariamente aumentar o desempenho em jogos."
        'privacidade' = "Desativa telemetrias e coleta de dados e semelhantes, aumentando a privacidade."
    }
    $focoVal = ([string]$item.Foco).Trim().ToLower()
    if (-not [string]::IsNullOrWhiteSpace($focoVal) -and $focoMap.ContainsKey($focoVal)) {
        $icoFoco = [System.Windows.Controls.TextBlock]::new()
        $icoFoco.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe Fluent Icons")
        $icoFoco.Text = [char]$focoMap[$focoVal]
        $icoFoco.FontSize = $focoSizeMap[$focoVal]
        $icoFoco.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#9EA7B8')
        $icoFoco.VerticalAlignment = 'Center'
        $icoFoco.Margin = [System.Windows.Thickness]::new(7,0,0,0)
        $icoFoco.Cursor = [System.Windows.Input.Cursors]::Help

        $ttFoco = [System.Windows.Controls.ToolTip]::new()
        $ttFoco.Background = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#191923')
        $ttFoco.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#F4F4F4')
        $ttFoco.BorderBrush = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#242436')
        $ttFoco.BorderThickness = [System.Windows.Thickness]::new(1)
        $ttFoco.Padding = [System.Windows.Thickness]::new(12,8,12,8)
        $ttFoco.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom
        $ttFoco.IsHitTestVisible = $false

        $ttFocoText = [System.Windows.Controls.TextBlock]::new()
        $ttFocoText.Text = $focoTooltipMap[$focoVal]
        $ttFocoText.TextWrapping = 'Wrap'
        $ttFocoText.MaxWidth = 320
        $ttFocoText.FontSize = 11.5
        $ttFoco.Content = $ttFocoText

        [System.Windows.Controls.ToolTipService]::SetInitialShowDelay($icoFoco, 400)
        [System.Windows.Controls.ToolTipService]::SetShowDuration($icoFoco, 60000)
        $icoFoco.ToolTip = $ttFoco

        $icoFoco.Add_MouseLeave({
            if ($this.ToolTip -is [System.Windows.Controls.ToolTip]) {
                $this.ToolTip.IsOpen = $false
            }
        })

        $null = $nameRow.Children.Add($icoFoco)
    }

    $tbDesc = [System.Windows.Controls.TextBlock]::new()
    $tbDesc.Text = $item.Description; $tbDesc.FontSize = 12
    $tbDesc.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#6F7581')
    $tbDesc.VerticalAlignment = 'Center'; $tbDesc.TextTrimming = 'CharacterEllipsis'
    $tbDesc.Margin = [System.Windows.Thickness]::new(0,6,14,0)
    
    if (-not [string]::IsNullOrWhiteSpace($item.TooltipText)) {
        $tt = [System.Windows.Controls.ToolTip]::new()
        $tt.Background = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#191923')
        $tt.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#F4F4F4')
        $tt.BorderBrush = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#242436')
        $tt.BorderThickness = [System.Windows.Thickness]::new(1)
        $tt.Padding = [System.Windows.Thickness]::new(14)
        $tt.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom

        $ttText = [System.Windows.Controls.TextBlock]::new()
        $ttText.Text = $item.TooltipText
        $ttText.TextWrapping = 'Wrap'
        $ttText.MaxWidth = 450
        $ttText.FontSize = 11.5
        
        $tt.Content = $ttText
        $tt.IsHitTestVisible = $false
        
        [System.Windows.Controls.ToolTipService]::SetInitialShowDelay($tbDesc, 1000)
        [System.Windows.Controls.ToolTipService]::SetShowDuration($tbDesc, 60000)
        
        $tbDesc.ToolTip = $tt
        
        $tbDesc.Add_MouseLeave({
            if ($this.ToolTip -is [System.Windows.Controls.ToolTip]) {
                $this.ToolTip.IsOpen = $false
            }
        })
    }

    [System.Windows.Controls.Grid]::SetRow($tbDesc, 1)
    [System.Windows.Controls.Grid]::SetColumn($tbDesc, 0)

    $rightPanel = [System.Windows.Controls.StackPanel]::new()
    $rightPanel.Orientation = 'Horizontal'
    $rightPanel.HorizontalAlignment = 'Right'
    $rightPanel.VerticalAlignment = 'Center'
    [System.Windows.Controls.Grid]::SetRow($rightPanel, 0)
    [System.Windows.Controls.Grid]::SetRowSpan($rightPanel, 2)
    [System.Windows.Controls.Grid]::SetColumn($rightPanel, 1)

    $btnEdit = [System.Windows.Controls.TextBlock]::new()
    $btnEdit.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe Fluent Icons")
    $btnEdit.Text = [char]0xF8B0
    $btnEdit.FontSize = 16
    $btnEdit.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#9EA7B8')
    $btnEdit.Cursor = [System.Windows.Input.Cursors]::Hand
    $btnEdit.Margin = [System.Windows.Thickness]::new(0,0,12,0)
    $btnEdit.VerticalAlignment = 'Center'
    $btnEdit.Visibility = 'Collapsed'
    $btnEdit.ToolTip = "Alterar Valor"
    
    $btnEdit.Add_MouseEnter({ $this.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#F4F4F4') })
    $btnEdit.Add_MouseLeave({ $this.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#9EA7B8') })

    $toggle = [System.Windows.Controls.Primitives.ToggleButton]::new()
    $toggle.Style = $toggleStyle
    $toggle.VerticalAlignment = 'Center'
    
    # LÊ A MEMÓRIA INICIAL
    $toggle.IsChecked = if ($item.IsChecked -eq $true) { $true } else { $false }

    # Exibe o botão de edição se já estiver ativado e tiver perfis
    if ($toggle.IsChecked -eq $true -and $null -ne $item.Values -and $item.Values.Count -gt 0) {
        $btnEdit.Visibility = 'Visible'
    }

    $null = $rightPanel.Children.Add($btnEdit)
    $null = $rightPanel.Children.Add($toggle)

    $applyBat    = $item.ApplyBat
    $applyParam  = $item.ApplyParam
    $revertBat   = $item.RevertBat
    $revertParam = $item.RevertParam
    $capturedBaseDir = $script:BaseDir

    # --- Evento: Clique no Ícone de Edição ---
    $btnEdit.Add_MouseLeftButtonDown({
        $selectedCmdString = Show-ValuesModal -Item $item -OwnerWindow $window
        if (-not $selectedCmdString) { return }
        
        # SALVA A ESCOLHA NA MEMÓRIA
        $item.SavedValue = $selectedCmdString
        $global:PulseState["$($item.Id)_Value"] = $selectedCmdString
        Save-PulseState
        
        [string]$cmdFull = $selectedCmdString
        $cmdFull = $cmdFull.Trim()
        [int]$lastSpace = $cmdFull.LastIndexOf(' ')
        
        if ($lastSpace -ge 0) {
            $batRel = $cmdFull.Substring(0, $lastSpace).TrimStart('.').TrimStart('\').TrimStart('/')
            $param  = $cmdFull.Substring($lastSpace + 1)
        } else {
            $batRel = $cmdFull.TrimStart('.').TrimStart('\').TrimStart('/')
            $param  = ""
        }
        $bat = Join-Path $capturedBaseDir $batRel

        if ([string]::IsNullOrWhiteSpace($bat) -or -not (Test-Path $bat)) {
            [System.Windows.MessageBox]::Show("Arquivo não encontrado:`n$bat", "Painel Pulse – Erro", 'OK', 'Error') | Out-Null
            return
        }

        Add-PulseJob -BatPath $bat -Param $param -OptName $item.Name -Action "Aplicar"
    }.GetNewClosure())

    # --- Evento: Clique no Toggle ---
    $toggle.Add_Click({
        $bat = ""
        $param = ""

        if ($toggle.IsChecked -eq $true) {
            if ($null -ne $item.Values -and $item.Values.Count -gt 0) {
                $selectedCmdString = Show-ValuesModal -Item $item -OwnerWindow $window
                if (-not $selectedCmdString) {
                    $toggle.IsChecked = $false
                    $btnEdit.Visibility = 'Collapsed'
                    return
                }
                $btnEdit.Visibility = 'Visible'
                
                # SALVA A ESCOLHA NA MEMÓRIA
                $item.SavedValue = $selectedCmdString
                $global:PulseState["$($item.Id)_Value"] = $selectedCmdString
                
                [string]$cmdFull = $selectedCmdString
                $cmdFull = $cmdFull.Trim()
                [int]$lastSpace = $cmdFull.LastIndexOf(' ')
                
                if ($lastSpace -ge 0) {
                    $batRel = $cmdFull.Substring(0, $lastSpace).TrimStart('.').TrimStart('\').TrimStart('/')
                    $param  = $cmdFull.Substring($lastSpace + 1)
                } else {
                    $batRel = $cmdFull.TrimStart('.').TrimStart('\').TrimStart('/')
                    $param  = ""
                }
                $bat = Join-Path $capturedBaseDir $batRel

            } else {
                $bat = $applyBat
                $param = $applyParam
            }
        } else {
            $btnEdit.Visibility = 'Collapsed'
            $bat = $revertBat
            $param = $revertParam
        }

        if (-not [string]::IsNullOrWhiteSpace($bat)) {
            if (-not (Test-Path $bat)) {
                [System.Windows.MessageBox]::Show("Arquivo não encontrado:`n$bat", "Painel Pulse – Erro", 'OK', 'Error') | Out-Null
                $toggle.IsChecked = -not $toggle.IsChecked
                if ($toggle.IsChecked -eq $false) { $btnEdit.Visibility = 'Collapsed' }
                return
            }
            $action = if ($toggle.IsChecked -eq $true) { "Aplicar" } else { "Reverter" }
            Add-PulseJob -BatPath $bat -Param $param -OptName $item.Name -Action $action
        }

        [bool]$estadoVisual = if ($toggle.IsChecked -eq $true) { $true } else { $false }
        $item.IsChecked = $estadoVisual
        
        if ($null -eq $global:PulseState) { $global:PulseState = @{} }
        $global:PulseState[[string]$item.Id] = $estadoVisual
        Save-PulseState

    }.GetNewClosure())

    $null = $grid.Children.Add($nameRow)
    $null = $grid.Children.Add($tbDesc)
    $null = $grid.Children.Add($rightPanel)
    $border.Child = $grid

    # AGORA SIM O SCRIPT SABE ONDE ENCONTRAR O ÍCONE (BtnEdit)
    $border.Tag = @{ Item = $item; Toggle = $toggle; BtnEdit = $btnEdit }

    return $border
}

# --- Preenche um StackPanel com cards ou exibe mensagem de vazio ---
function Set-ListOrEmpty {
    param(
        [System.Windows.Controls.StackPanel]$Panel,
        [System.Windows.Controls.ScrollViewer]$Scroll,
        [System.Windows.Controls.TextBlock]$MsgBlock,
        [array]$Items
    )
    $Panel.Children.Clear()
    if ($Items.Count -gt 0) {
        $res = $window.Resources
        foreach ($item in $Items) {
            $null = $Panel.Children.Add((New-OptCard -item $item -res $res))
        }
        $Scroll.Visibility   = 'Visible'
        $MsgBlock.Visibility = 'Collapsed'
    } else {
        $Scroll.Visibility   = 'Collapsed'
        $MsgBlock.Visibility = 'Visible'
    }
}

# ==========================================
# JANELA MODAL PARA PESQUISA DO WINGET
# ==========================================
function Show-WingetSearchModal {
    param([string]$Query, [System.Windows.Window]$OwnerWindow)

    $modalXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Width="550" Height="380" WindowStartupLocation="CenterOwner"
            WindowStyle="None" AllowsTransparency="True" Background="Transparent"
            ShowInTaskbar="False" ResizeMode="NoResize">
        <Window.Resources>
            <SolidColorBrush x:Key="ColorAccent" Color="#F52C42"/>
            <Style TargetType="ToggleButton">
                <Setter Property="Foreground" Value="#F4F4F4"/>
                <Setter Property="Background" Value="#191923"/>
                <Setter Property="BorderBrush" Value="#242436"/>
                <Setter Property="BorderThickness" Value="1.5"/>
                <Setter Property="Padding" Value="14,10"/>
                <Setter Property="Margin" Value="0,0,0,8"/>
                <Setter Property="FontSize" Value="13"/>
                <Setter Property="FontWeight" Value="SemiBold"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="HorizontalAlignment" Value="Stretch"/>
                <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="ToggleButton">
                            <Border x:Name="Bd" Background="{TemplateBinding Background}" 
                                    BorderBrush="{TemplateBinding BorderBrush}" 
                                    BorderThickness="{TemplateBinding BorderThickness}" 
                                    CornerRadius="8" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsChecked" Value="True">
                                    <Setter TargetName="Bd" Property="BorderBrush" Value="{StaticResource ColorAccent}"/>
                                    <Setter TargetName="Bd" Property="BorderThickness" Value="1.5"/>
                                    <Setter TargetName="Bd" Property="Background" Value="#1F151B"/>
                                </Trigger>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="Bd" Property="Background" Value="#222235"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

            <Style TargetType="ScrollBar">
                <Setter Property="Background" Value="Transparent" />
                <Setter Property="Width" Value="5" />
                <Setter Property="BorderThickness" Value="0" />
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="ScrollBar">
                            <Grid Background="{TemplateBinding Background}">
                                <Track x:Name="PART_Track" IsDirectionReversed="True">
                                    <Track.Thumb>
                                        <Thumb>
                                            <Thumb.Template>
                                                <ControlTemplate TargetType="Thumb">
                                                    <Border x:Name="ThumbBorder" Background="#242436" CornerRadius="4" Margin="5"/>
                                                    <ControlTemplate.Triggers>
                                                        <Trigger Property="IsMouseOver" Value="True">
                                                            <Setter TargetName="ThumbBorder" Property="Background" Value="#3A3B4A"/>
                                                        </Trigger>
                                                        <Trigger Property="IsDragging" Value="True">
                                                            <Setter TargetName="ThumbBorder" Property="Background" Value="{StaticResource ColorAccent}"/>
                                                        </Trigger>
                                                    </ControlTemplate.Triggers>
                                                </ControlTemplate>
                                            </Thumb.Template>
                                        </Thumb>
                                    </Track.Thumb>
                                </Track>
                            </Grid>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

            <Style x:Key="ShowMoreButtonStyle" TargetType="Button">
                <Setter Property="Background" Value="Transparent"/>
                <Setter Property="Foreground" Value="#9EA7B8"/>
                <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Padding" Value="0,0,0,10"/>
                <Setter Property="FontSize" Value="12.5"/>
                <Setter Property="FontWeight" Value="SemiBold"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="HorizontalAlignment" Value="Center"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter Property="Foreground" Value="#F4F4F4"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
        </Window.Resources>
        
        <Border Background="#101019" CornerRadius="12" BorderBrush="#242436" BorderThickness="1" Padding="20" Margin="10">
            <Border.Effect><DropShadowEffect Color="#000000" Direction="270" ShadowDepth="4" BlurRadius="15" Opacity="0.5"/></Border.Effect>
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                
                <TextBlock Grid.Row="0" Text="Resultados para: '$Query'" FontSize="18" FontWeight="ExtraBold" Foreground="#F4F4F4" Margin="0,0,0,16"/>
                
                <Border Grid.Row="1" Background="#15151F" CornerRadius="8" BorderBrush="#242436" BorderThickness="1" Margin="0,0,0,16">
                    <Grid>
                        <TextBlock x:Name="LblStatus" Text="Buscando nos repositórios oficiais..." Foreground="#6F7581" HorizontalAlignment="Center" VerticalAlignment="Center" FontSize="14" FontWeight="SemiBold"/>
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <StackPanel x:Name="ResultsPanel" Margin="10"/>
                        </ScrollViewer>
                    </Grid>
                </Border>
                
                <Grid Grid.Row="2">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="14"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="BtnCancel" Grid.Column="0" Content="Cancelar" Background="#222235" Foreground="#F4F4F4" BorderThickness="0" Padding="12" Cursor="Hand" FontWeight="SemiBold" Height="42">
                        <Button.Template><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="8"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Button.Template>
                    </Button>
                    <Button x:Name="BtnAdd" Grid.Column="2" Content="Adicionar Selecionados" Background="#F52C42" Foreground="#F4F4F4" BorderThickness="0" Padding="12" Cursor="Hand" FontWeight="SemiBold" Height="42" IsEnabled="False">
                        <Button.Template><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="8"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Button.Template>
                    </Button>
                </Grid>
            </Grid>
        </Border>
    </Window>
"@
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$modalXaml)
    $modal = [Windows.Markup.XamlReader]::Load($reader)
    $modal.Owner = $OwnerWindow

    $LblStatus = $modal.FindName("LblStatus")
    $ResultsPanel = $modal.FindName("ResultsPanel")
    $BtnAdd = $modal.FindName("BtnAdd")
    $script:AppToggles = @()
    $script:SelectedAppsFromModal = @()

    $modal.Add_ContentRendered({
        $modal.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
        
        $safeQuery = $Query -replace '["'']', ''
        $cmdArgs = "/c chcp 65001 >NUL & winget search `"$safeQuery`" --disable-interactivity --accept-source-agreements > `"$env:TEMP\winget_out.txt`""
        $process = Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -Wait -WindowStyle Hidden
        
        $output = @()
        if (Test-Path "$env:TEMP\winget_out.txt") {
            $output = Get-Content "$env:TEMP\winget_out.txt" -Encoding UTF8 -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\winget_out.txt" -ErrorAction SilentlyContinue
        }
        
        $LblStatus.Visibility = 'Collapsed'
        $startIndex = -1
        
        for ($i=0; $i -lt $output.Count; $i++) {
            if ($output[$i] -match '^---') { $startIndex = $i + 1; break }
        }

        if ($startIndex -ne -1 -and $startIndex -lt $output.Count) {
            $exactMatches = @()
            $otherMatches = @()
            $queryLC = $Query.ToLower()

            for ($i = $startIndex; $i -lt $output.Count; $i++) {
                $line = $output[$i].Trim()
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                
                # Divide a linha em palavras separadas, destruindo os múltiplos espaços
                $tokens = $line -split '\s+'
                if ($tokens.Count -lt 3) { continue }
                
                # --- LEITURA DE TRÁS PARA FRENTE (A sua ideia em código!) ---
                # A última palavra (índice -1) é sempre a Origem (Source)
                $appSource = $tokens[-1]
                
                # O Match ("Tag: epicgames") sempre adiciona dois blocos: "Tag:" e "epicgames"
                # Sabendo que ele usa dois pontos (:), checamos se a antipenúltima palavra tem dois pontos
                if ($tokens.Count -ge 5 -and $tokens[-3] -match ':$') {
                    $appVersion = $tokens[-4]
                    $appId = $tokens[-5]
                    $nameLimit = $tokens.Count - 6
                } else {
                    # Se não tem o Match, é o padrão normal
                    $appVersion = $tokens[-2]
                    $appId = $tokens[-3]
                    $nameLimit = $tokens.Count - 4
                }
                
                # Prevenção caso a linha seja muito curta
                if ($nameLimit -lt 0) { continue }
                
                # Tudo do índice 0 até o limite do Nome, nós juntamos de volta com 1 espaço
                $appName = $tokens[0..$nameLimit] -join ' '
                # -----------------------------------------------------------

                if ([string]::IsNullOrWhiteSpace($appName) -or [string]::IsNullOrWhiteSpace($appId)) { continue }
                
                $nameLC = $appName.ToLower()
                if (($nameLC -match "plugin|extension|beta|preview|update|language") -and ($queryLC -notmatch "plugin|extension|beta|preview|update|language")) { continue }

                $appObj = [PSCustomObject]@{ Name = $appName; Id = $appId; Version = $appVersion }

                if ($nameLC -eq $queryLC -or $appId.ToLower() -match $queryLC) {
                    $exactMatches += $appObj
                } else {
                    $otherMatches += $appObj
                }
            }

            $finalResults = $exactMatches + $otherMatches | Group-Object Id | ForEach-Object { $_.Group[0] } | Select-Object -First 15

            $isFirstResult = $true
            $hiddenToggles = @()

            foreach ($res in $finalResults) {
                $tb = [System.Windows.Controls.Primitives.ToggleButton]::new()
                
                # --- Criação da Tabela Interna do Botão ---
                $btnGrid = [System.Windows.Controls.Grid]::new()
                $col0 = [System.Windows.Controls.ColumnDefinition]::new(); $col0.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
                $col1 = [System.Windows.Controls.ColumnDefinition]::new(); $col1.Width = [System.Windows.GridLength]::Auto
                $btnGrid.ColumnDefinitions.Add($col0)
                $btnGrid.ColumnDefinitions.Add($col1)

                # Lado Esquerdo: Nome + ID
                $leftStack = [System.Windows.Controls.StackPanel]::new(); $leftStack.Orientation = 'Horizontal'; $leftStack.VerticalAlignment = 'Center'
                
                $tbName = [System.Windows.Controls.TextBlock]::new()
                $tbName.Text = $res.Name; $tbName.FontWeight = [System.Windows.FontWeights]::SemiBold
                $tbName.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#F4F4F4')
                $tbName.TextTrimming = 'CharacterEllipsis'
                
                $tbId = [System.Windows.Controls.TextBlock]::new()
                $tbId.Text = " - $($res.Id)"; $tbId.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#6F7581')
                $tbId.Margin = [System.Windows.Thickness]::new(4,0,0,0); $tbId.TextTrimming = 'CharacterEllipsis'
                
                $null = $leftStack.Children.Add($tbName)
                $null = $leftStack.Children.Add($tbId)
                [System.Windows.Controls.Grid]::SetColumn($leftStack, 0)
                
                # Lado Direito: Versão
                $tbVer = [System.Windows.Controls.TextBlock]::new()
                $tbVer.Text = "Versão: " + $res.Version; $tbVer.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#9EA7B8')
                $tbVer.VerticalAlignment = 'Center'; $tbVer.Margin = [System.Windows.Thickness]::new(10,0,0,0)
                [System.Windows.Controls.Grid]::SetColumn($tbVer, 1)

                $null = $btnGrid.Children.Add($leftStack)
                $null = $btnGrid.Children.Add($tbVer)

                $tb.Content = $btnGrid
                $tb.ToolTip = "ID: $($res.Id) | Versão: $($res.Version)"
                $tb.Tag = $res
                
                $tb.Add_Click({
                    $temMarcado = $false
                    foreach ($box in $script:AppToggles) { if ($box.IsChecked -eq $true) { $temMarcado = $true; break } }
                    $BtnAdd.IsEnabled = $temMarcado
                })
                
                $script:AppToggles += $tb

                # LÓGICA DE EXIBIÇÃO: O primeiro é renderizado normal, os demais vão para a lista de ocultos.
                if ($isFirstResult) {
                    $null = $ResultsPanel.Children.Add($tb)
                    $isFirstResult = $false
                } else {
                    $tb.Visibility = 'Collapsed'
                    $hiddenToggles += $tb
                }
            }

            # LÓGICA DE EXIBIÇÃO: Cria o botão 'Mostrar outros' se houver itens ocultos.
            if ($hiddenToggles.Count -gt 0) {
                $btnShowMore = [System.Windows.Controls.Button]::new()
                $btnShowMore.Content = "Mostrar outros resultados ($($hiddenToggles.Count))"
                
                # Aplica o estilo limpo definido no XAML (remove o highlight do Windows)
                $btnShowMore.Style = $modal.Resources["ShowMoreButtonStyle"]
                
                $null = $ResultsPanel.Children.Add($btnShowMore)

                # Anexa os Toggles invisíveis na interface abaixo do botão
                foreach ($ht in $hiddenToggles) {
                    $null = $ResultsPanel.Children.Add($ht)
                }

                # Ação: Esconde o botão e revela os itens ocultos
                $btnShowMore.Add_Click({
                    $this.Visibility = 'Collapsed'
                    foreach ($ht in $hiddenToggles) {
                        $ht.Visibility = 'Visible'
                    }
                }.GetNewClosure())
            }
        }
        
        if ($script:AppToggles.Count -eq 0) {
            $LblStatus.Text = "Nenhum aplicativo oficial encontrado."
            $LblStatus.Visibility = 'Visible'
        }
    })

    $modal.FindName("BtnCancel").Add_Click({ $modal.DialogResult = $false })
    
    $BtnAdd.Add_Click({
        foreach ($box in $script:AppToggles) {
            if ($box.IsChecked -eq $true) { $script:SelectedAppsFromModal += $box.Tag }
        }
        $modal.DialogResult = $true
    })

    if ($modal.ShowDialog() -eq $true) { return $script:SelectedAppsFromModal }
    return $null
}

# --- Adiciona um Token de Aplicativo na Lista ---
function Add-SelectedAppToken {
    param($AppName, $AppId)

    $border = [System.Windows.Controls.Border]::new()
    $border.Background = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#1F151B')
    $border.BorderBrush = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#F52C42')
    $border.BorderThickness = [System.Windows.Thickness]::new(1.5)
    $border.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $border.Padding = [System.Windows.Thickness]::new(10,6,10,6)
    $border.Margin = [System.Windows.Thickness]::new(0,0,10,10)

    $grid = [System.Windows.Controls.Grid]::new()
    $c0 = [System.Windows.Controls.ColumnDefinition]::new(); $c0.Width = 'Auto'
    $c1 = [System.Windows.Controls.ColumnDefinition]::new(); $c1.Width = '*'
    $c2 = [System.Windows.Controls.ColumnDefinition]::new(); $c2.Width = 'Auto'
    $grid.ColumnDefinitions.Add($c0); $grid.ColumnDefinitions.Add($c1); $grid.ColumnDefinitions.Add($c2)

    $iconLeft = [System.Windows.Controls.TextBlock]::new()
    $iconLeft.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe Fluent Icons")
    $iconLeft.Text = [char]0xE896
    $iconLeft.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#F4F4F4')
    $iconLeft.VerticalAlignment = 'Center'
    $iconLeft.FontSize = 14
    $iconLeft.Margin = [System.Windows.Thickness]::new(0,0,10,0)
    [System.Windows.Controls.Grid]::SetColumn($iconLeft, 0)

    $textBlock = [System.Windows.Controls.TextBlock]::new()
    $textBlock.Text = $AppName
    $textBlock.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#F4F4F4')
    $textBlock.FontWeight = [System.Windows.FontWeights]::SemiBold
    $textBlock.VerticalAlignment = 'Center'
    $textBlock.FontSize = 13.5
    [System.Windows.Controls.Grid]::SetColumn($textBlock, 1)

    $btnRemoveContainer = [System.Windows.Controls.Border]::new()
    $btnRemoveContainer.Background = [System.Windows.Media.Brushes]::Transparent
    $btnRemoveContainer.Padding = [System.Windows.Thickness]::new(12,2,0,2)
    $btnRemoveContainer.Cursor = [System.Windows.Input.Cursors]::Hand
    [System.Windows.Controls.Grid]::SetColumn($btnRemoveContainer, 2)

    $iconRemove = [System.Windows.Controls.TextBlock]::new()
    $iconRemove.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe Fluent Icons")
    $iconRemove.Text = [char]0xE711
    $iconRemove.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#F52C42')
    $iconRemove.VerticalAlignment = 'Center'
    $iconRemove.FontSize = 12
    $btnRemoveContainer.Child = $iconRemove

    # Captura os elementos globais em variáveis locais para a closure não perder a referência
    $localPanel = $script:SelectedAppsPanel
    $localBtnInstall = $script:BtnInstallApps

    $btnRemoveContainer.Add_MouseLeftButtonUp({
        $localPanel.Children.Remove($border)
        
        if ($localPanel.Children.Count -eq 0) {
            $localBtnInstall.IsEnabled = $false
        }
    }.GetNewClosure())

    $null = $grid.Children.Add($iconLeft)
    $null = $grid.Children.Add($textBlock)
    $null = $grid.Children.Add($btnRemoveContainer)
    $border.Child = $grid

    # Guardamos os dados e os elementos visuais na Tag para facilitar a alteração no Pós-Install
    $border.Tag = @{ 
        Name = $AppName; 
        Id = $AppId; 
        Status = "Pending";
        IconElement = $iconLeft;
        RemoveElement = $btnRemoveContainer
    }

    $null = $script:SelectedAppsPanel.Children.Add($border)
    $script:BtnInstallApps.IsEnabled = $true
}

# ==========================================
# LÓGICA DO DESINSTALADOR (VARREDURA E MODAL)
# ==========================================
function Get-PulseInstalledApps {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $normalApps = @(); $systemApps = @()

    foreach ($path in $paths) {
        $keys = Get-ItemProperty $path -ErrorAction SilentlyContinue
        foreach ($key in $keys) {
            if ($null -eq $key.DisplayName -or $key.ParentKeyName) { continue }
            $name = $key.DisplayName.Trim()
            $uninstallCmd = if ($key.QuietUninstallString) { $key.QuietUninstallString } else { $key.UninstallString }
            if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($uninstallCmd)) { continue }
            
            $isSystem = ($key.SystemComponent -eq 1) -or ($name -match "(?i)Visual C\+\+|Redistributable|Runtime|Update|SDK|Language Pack|Service Pack|Microsoft .NET")
            
            $appObj = [PSCustomObject]@{ Name = $name; UninstallString = $uninstallCmd; Version = $key.DisplayVersion; IsSystem = $isSystem }
            if ($isSystem) { $systemApps += $appObj } else { $normalApps += $appObj }
        }
    }
    
    # O @() aqui garante que a estrutura de contagem nunca quebre
    return @{
        Normal = @($normalApps | Group-Object Name | ForEach-Object { $_.Group[0] } | Sort-Object Name)
        System = @($systemApps | Group-Object Name | ForEach-Object { $_.Group[0] } | Sort-Object Name)
    }
}

function Get-PulseStartupApps {
    $startupApps = @()
    $locations = @(
        @{ Hive="HKCU"; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Appr="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" },
        @{ Hive="HKLM"; Path="SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Appr="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" }
    )
    foreach ($loc in $locations) {
        $regPath = "$($loc.Hive):\$($loc.Path)"
        $apprPath = "$($loc.Hive):\$($loc.Appr)"
        
        if (-not (Test-Path $apprPath)) { New-Item -Path $apprPath -Force | Out-Null }

        $items = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        $apprItems = Get-ItemProperty -Path $apprPath -ErrorAction SilentlyContinue
        
        if ($items) {
            foreach ($prop in $items.psobject.properties) {
                $name = $prop.Name
                if ($name -match "^(PSPath|PSParentPath|PSChildName|PSDrive|PSProvider)$") { continue }
                
                $cmdString = $prop.Value
                
                # --- LÓGICA DE NOME LIMPO ---
                $cleanName = $name
                if ($cmdString -match "([^\\]+\.exe)") {
                    $exeName = $matches[1]
                    switch -Regex ($exeName) {
                        "(?i)msedge\.exe" { $cleanName = "Microsoft Edge" }
                        "(?i)chrome\.exe" { $cleanName = "Google Chrome" }
                        "(?i)onedrive\.exe" { $cleanName = "Microsoft OneDrive" }
                        "(?i)discord\.exe" { $cleanName = "Discord" }
                        "(?i)steam\.exe" { $cleanName = "Steam" }
                        "(?i)spotify\.exe" { $cleanName = "Spotify" }
                        "(?i)brave\.exe" { $cleanName = "Brave Browser" }
                        "(?i)epicgameslauncher\.exe" { $cleanName = "Epic Games Launcher" }
                        default { $cleanName = $exeName } # Se não for conhecido, exibe o nome.exe
                    }
                } else {
                    $cleanName = $name -replace "_[A-F0-9]{8,}$", ""
                }
                
                $isEnabled = $true
                if ($apprItems -and $null -ne $apprItems.$name) {
                    if ($apprItems.$name[0] -eq 0x03) { $isEnabled = $false }
                }
                # Guardamos o OriginalName para o Registro do Windows encontrar a chave correta
                $startupApps += [PSCustomObject]@{ Name = $cleanName; Command = $cmdString; IsEnabled = $isEnabled; ApprPath = $apprPath; OriginalName = $name }
            }
        }
    }
    return $startupApps | Sort-Object Name
}

function Show-UninstallerModal {
    param([hashtable]$AppList, [System.Windows.Window]$OwnerWindow)

    $modalXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Width="680" Height="550" WindowStartupLocation="CenterOwner"
            WindowStyle="None" AllowsTransparency="True" Background="Transparent" ShowInTaskbar="False" ResizeMode="NoResize">
        <Window.Resources>
            <SolidColorBrush x:Key="ColorAccent" Color="#F52C42"/>
            <Style TargetType="ToggleButton" x:Key="UninstallCardStyle">
                <Setter Property="Foreground" Value="#F4F4F4"/><Setter Property="Background" Value="#191923"/>
                <Setter Property="BorderBrush" Value="#242436"/><Setter Property="BorderThickness" Value="1.5"/>
                <Setter Property="Padding" Value="14,10"/><Setter Property="Margin" Value="0,0,0,8"/>
                <Setter Property="HorizontalAlignment" Value="Stretch"/><Setter Property="HorizontalContentAlignment" Value="Left"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="ToggleButton">
                            <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsChecked" Value="True">
                                    <Setter TargetName="Bd" Property="BorderBrush" Value="{StaticResource ColorAccent}"/>
                                    <Setter TargetName="Bd" Property="Background" Value="#1F151B"/>
                                </Trigger>
                                <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#222235"/></Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
        </Window.Resources>
        
        <Border Background="#101019" CornerRadius="12" BorderBrush="#242436" BorderThickness="1" Padding="20" Margin="10">
            <Border.Effect><DropShadowEffect Color="#000000" Direction="270" ShadowDepth="4" BlurRadius="15" Opacity="0.5"/></Border.Effect>
            <Grid>
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                
                <Grid Grid.Row="0" Margin="0,0,0,16">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="0" Text="Desinstalar Aplicativos" FontSize="18" FontWeight="ExtraBold" Foreground="#F4F4F4" VerticalAlignment="Center"/>
                    <ToggleButton x:Name="TglSystem" Grid.Column="1" Background="#191923" BorderBrush="#242436" Foreground="#9EA7B8" Content="Mostrar Componentes de Sistema" Padding="12,6" FontSize="12" Cursor="Hand">
                        <ToggleButton.Template><ControlTemplate TargetType="ToggleButton"><Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="6" Padding="{TemplateBinding Padding}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></ToggleButton.Template>
                    </ToggleButton>
                </Grid>
                
                <Border Grid.Row="1" Background="#15151F" CornerRadius="8" BorderBrush="#242436" BorderThickness="1" Margin="0,0,0,16">
                    <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel x:Name="AppsPanel" Margin="10"/></ScrollViewer>
                </Border>
                
                <Grid Grid.Row="2">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="14"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button x:Name="BtnCancel" Grid.Column="0" Content="Cancelar" Background="#222235" Foreground="#F4F4F4" BorderThickness="0" Padding="12" Cursor="Hand" FontWeight="SemiBold" Height="42">
                        <Button.Template><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="8"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Button.Template>
                    </Button>
                    <Button x:Name="BtnUninstall" Grid.Column="2" Content="Desinstalar Selecionados" Background="#F52C42" Foreground="#F4F4F4" BorderThickness="0" Padding="12" Cursor="Hand" FontWeight="SemiBold" Height="42" IsEnabled="False">
                        <Button.Template><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="8"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Button.Template>
                    </Button>
                </Grid>
            </Grid>
        </Border>
    </Window>
"@
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$modalXaml)
    $modal = [Windows.Markup.XamlReader]::Load($reader)
    $modal.Owner = $OwnerWindow

    $AppsPanel = $modal.FindName("AppsPanel")
    $BtnUninstall = $modal.FindName("BtnUninstall")
    $TglSystem = $modal.FindName("TglSystem")
    $script:AppToggles = @()
    $script:SelectedToUninstall = @()

    $todosApps = $AppList.Normal + $AppList.System
    foreach ($app in $todosApps) {
        $tb = [System.Windows.Controls.Primitives.ToggleButton]::new()
        $tb.Style = $modal.Resources["UninstallCardStyle"]
        
        $grid = [System.Windows.Controls.Grid]::new()
        $grid.VerticalAlignment = 'Center'
        $grid.RowDefinitions.Add([System.Windows.Controls.RowDefinition]::new())
        $grid.RowDefinitions.Add([System.Windows.Controls.RowDefinition]::new())
        
        $tbName = [System.Windows.Controls.TextBlock]::new()
        $tbName.Text = $app.Name; $tbName.FontSize = 13.5; $tbName.FontWeight = [System.Windows.FontWeights]::SemiBold; $tbName.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#F4F4F4')
        [System.Windows.Controls.Grid]::SetRow($tbName, 0)
        
        $tbDesc = [System.Windows.Controls.TextBlock]::new()
        $tbDesc.Text = if ($app.IsSystem) { "Componente do Sistema" } elseif ($app.Version) { "Versão: $($app.Version)" } else { "Versão desconhecida" }
        $tbDesc.FontSize = 11.5; $tbDesc.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#6F7581'); $tbDesc.Margin = [System.Windows.Thickness]::new(0,2,0,0)
        [System.Windows.Controls.Grid]::SetRow($tbDesc, 1)
        
        $null = $grid.Children.Add($tbName)
        $null = $grid.Children.Add($tbDesc)
        $tb.Content = $grid
        $tb.Tag = $app
        
        if ($app.IsSystem) { $tb.Visibility = 'Collapsed' } # Oculta sistemas por padrão
        
        $tb.Add_Click({
            $temMarcado = $false
            foreach ($box in $script:AppToggles) { if ($box.IsChecked -eq $true) { $temMarcado = $true; break } }
            $BtnUninstall.IsEnabled = $temMarcado
        })
        $script:AppToggles += $tb
        $null = $AppsPanel.Children.Add($tb)
    }

    # Lógica do Switch de Componentes
    $TglSystem.Add_Click({
        $mostrar = $this.IsChecked
        $this.Content = if ($mostrar) { "Ocultar Componentes de Sistema" } else { "Mostrar Componentes de Sistema" }
        $this.Foreground = if ($mostrar) { [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#F4F4F4') } else { [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#9EA7B8') }
        
        foreach ($child in $AppsPanel.Children) {
            if ($child.Tag.IsSystem) { 
                $child.Visibility = if ($mostrar) { 'Visible' } else { 'Collapsed' } 
            }
        }
    })

    # Capturamos a janela em uma variável local para os eventos não perderem a referência na memória
    $localModal = $modal

    # Eventos blindados para fechar o modal corretamente
    $localModal.FindName("BtnCancel").Add_Click({ $localModal.DialogResult = $false }.GetNewClosure())
    $BtnUninstall.Add_Click({ $localModal.DialogResult = $true }.GetNewClosure())

    # A MÁGICA ACONTECE AQUI: O script pausa nesta linha até você fechar a janela.
    if ($localModal.ShowDialog() -eq $true) { 
        # A janela fechou! Lemos a nossa array nativa (que sabe que os itens são ToggleButtons)
        $itensSelecionados = @()
        foreach ($box in $script:AppToggles) {
            if ($box.IsChecked -eq $true) {
                $itensSelecionados += $box.Tag
            }
        }
        return $itensSelecionados 
    }
    
    return $null
}

function Show-StartupModal {
    param([array]$StartupList, [System.Windows.Window]$OwnerWindow)

    $modalXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Width="650" Height="500" WindowStartupLocation="CenterOwner"
            WindowStyle="None" AllowsTransparency="True" Background="Transparent" ShowInTaskbar="False" ResizeMode="NoResize">
        <Border Background="#101019" CornerRadius="12" BorderBrush="#242436" BorderThickness="1" Padding="20" Margin="10">
            <Border.Effect><DropShadowEffect Color="#000000" Direction="270" ShadowDepth="4" BlurRadius="15" Opacity="0.5"/></Border.Effect>
            <Grid>
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="Gerenciar Inicialização (Autorun)" FontSize="18" FontWeight="ExtraBold" Foreground="#F4F4F4" Margin="0,0,0,16"/>
                
                <Border Grid.Row="1" Background="#15151F" CornerRadius="8" BorderBrush="#242436" BorderThickness="1" Margin="0,0,0,16">
                    <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel x:Name="StartupPanel" Margin="10"/></ScrollViewer>
                </Border>
                
                <Button x:Name="BtnClose" Grid.Row="2" Content="Concluir" Background="#222235" Foreground="#F4F4F4" BorderThickness="0" Padding="12" Cursor="Hand" FontWeight="SemiBold" Height="42">
                    <Button.Template><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="8"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Button.Template>
                </Button>
            </Grid>
        </Border>
    </Window>
"@
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$modalXaml)
    $modal = [Windows.Markup.XamlReader]::Load($reader)
    $modal.Owner = $OwnerWindow
    $StartupPanel = $modal.FindName("StartupPanel")

    foreach ($app in $StartupList) {
        $border = [System.Windows.Controls.Border]::new()
        $border.Background = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#191923')
        $border.BorderBrush = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#242436')
        $border.BorderThickness = [System.Windows.Thickness]::new(1)
        $border.CornerRadius = [System.Windows.CornerRadius]::new(8)
        $border.Padding = [System.Windows.Thickness]::new(14,12,14,12)
        $border.Margin = [System.Windows.Thickness]::new(0,0,0,8)
        
        $grid = [System.Windows.Controls.Grid]::new()
        
        # Criação correta de colunas no WPF via PowerShell
        $c0 = [System.Windows.Controls.ColumnDefinition]::new()
        $c0.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $c1 = [System.Windows.Controls.ColumnDefinition]::new()
        $c1.Width = [System.Windows.GridLength]::Auto
        $grid.ColumnDefinitions.Add($c0)
        $grid.ColumnDefinitions.Add($c1)
        
        $textPanel = [System.Windows.Controls.StackPanel]::new()
        $textPanel.VerticalAlignment = 'Center'
        $textPanel.Margin = [System.Windows.Thickness]::new(0,0,16,0)
        [System.Windows.Controls.Grid]::SetColumn($textPanel, 0)
        
        $tbName = [System.Windows.Controls.TextBlock]::new()
        $tbName.Text = $app.Name
        $tbName.FontSize = 14
        $tbName.FontWeight = [System.Windows.FontWeights]::SemiBold
        $tbName.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#F4F4F4')
        
        $tbDesc = [System.Windows.Controls.TextBlock]::new()
        $tbDesc.Text = $app.Command
        $tbDesc.FontSize = 11.5
        $tbDesc.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#6F7581')
        $tbDesc.Margin = [System.Windows.Thickness]::new(0,4,0,0)
        $tbDesc.TextTrimming = 'CharacterEllipsis'
        
        $null = $textPanel.Children.Add($tbName)
        $null = $textPanel.Children.Add($tbDesc)
        
        $toggle = [System.Windows.Controls.Primitives.ToggleButton]::new()
        $toggle.Style = $window.Resources["ToggleSwitchStyle"]
        $toggle.VerticalAlignment = 'Center'
        $toggle.IsChecked = $app.IsEnabled
        $toggle.Tag = $app
        [System.Windows.Controls.Grid]::SetColumn($toggle, 1)
        
        $toggle.Add_Click({
            param($sender, $e)
            $appData = $sender.Tag
            $state = $sender.IsChecked
            
            # O Gerenciador de tarefas usa 02 (Ativado) e 03 (Desativado)
            $bytes = if ($state) { [byte[]](0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) } else { [byte[]](0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) }
            
            try { 
                Set-ItemProperty -Path $appData.ApprPath -Name $appData.OriginalName -Value $bytes -Type Binary -ErrorAction SilentlyContinue
                Write-PulseLog "Startup alterado: $($appData.Name) -> Ativo: $state" 
            } catch {}
        })

        $null = $grid.Children.Add($textPanel)
        $null = $grid.Children.Add($toggle)
        $border.Child = $grid
        $null = $StartupPanel.Children.Add($border)
    }

    $modal.FindName("BtnClose").Add_Click({ $modal.DialogResult = $true })
    $modal.ShowDialog() | Out-Null
}

# --- Eventos dos Botões (Abrir Modais e Recarregar Contagem) ---
function Refresh-DashboardCounts {
    $script:PulseInstalledApps = Get-PulseInstalledApps
    $script:PulseStartupApps = Get-PulseStartupApps
    
    # O @() garante a contagem correta mesmo quando há apenas 1 item
    $ativos = @($script:PulseStartupApps | Where-Object { $_.IsEnabled -eq $true }).Count
    $normCount = @($script:PulseInstalledApps.Normal).Count
    $sysCount = @($script:PulseInstalledApps.System).Count
    
    # Atualiza os painéis visuais
    $script:LblStartupActive.Text = "$ativos"
    $script:LblInstalledCount.Text = "$normCount"
    $script:LblSystemCount.Text = "$sysCount"
    
    $script:BtnOpenStartupModal.IsEnabled = $true
    $script:BtnOpenUninstallerModal.IsEnabled = $true
}

$script:BtnOpenStartupModal.Add_Click({
    Show-StartupModal -StartupList $script:PulseStartupApps -OwnerWindow $window
    Refresh-DashboardCounts # Atualiza se o usuário ligou/desligou algo
})

$script:BtnOpenUninstallerModal.Add_Click({
    $selecionados = Show-UninstallerModal -AppList $script:PulseInstalledApps -OwnerWindow $window
    if ($null -ne $selecionados -and $selecionados.Count -gt 0) {
        $script:BtnOpenUninstallerModal.Content = "Desinstalando..."
        $script:BtnOpenUninstallerModal.IsEnabled = $false
        $script:BtnOpenUninstallerModal.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
        
        $desinstalados = 0
        
        # Cria o objeto Shell nativo do Windows (O mesmo motor do Painel de Controle)
        $wsh = New-Object -ComObject WScript.Shell
        
        foreach ($app in $selecionados) {
            $cmd = $app.UninstallString
            
            # Se for um pacote MSI, troca o /I (Install) por /X (Uninstall)
            if ($cmd -match "(?i)MsiExec\.exe") { 
                $cmd = $cmd -replace "(?i)/I", "/X" 
            }
            
            # Expande variáveis nativas que os desenvolvedores deixam no registro (ex: %ProgramFiles%)
            $cmd = [System.Environment]::ExpandEnvironmentVariables($cmd)
            
            Write-PulseLog "Iniciando desinstalação nativa: $cmd"
            try { 
                # .Run (Comando, 1 = Janela Normal Visível, $true = Esperar o processo terminar)
                $exitCode = $wsh.Run($cmd, 1, $true)
                $desinstalados++ 
            } catch {
                Write-PulseLog "Erro ao desinstalar $($app.Name): $($_.Exception.Message)"
            }
        }
        
        $script:BtnOpenUninstallerModal.Content = "Desinstalar"
        Refresh-DashboardCounts
        
        [System.Windows.MessageBox]::Show("$desinstalados aplicativo(s) processado(s).", "Desinstalador", 'OK', 'Information') | Out-Null
    }
})

# ==========================================
# JANELA MODAL PARA OPÇÕES COM VALORES
# ==========================================
function Show-ValuesModal {
    param(
        [object]$Item,
        [System.Windows.Window]$OwnerWindow
    )

    $modalXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Width="480" SizeToContent="Height"
            WindowStartupLocation="CenterOwner"
            WindowStyle="None" AllowsTransparency="True" Background="Transparent"
            ShowInTaskbar="False" ResizeMode="NoResize">
        <Window.Resources>
            <Style TargetType="ToggleButton">
                <Setter Property="Foreground" Value="#F4F4F4"/>
                <Setter Property="Background" Value="#191923"/>
                <Setter Property="BorderBrush" Value="#242436"/>
                <Setter Property="BorderThickness" Value="1.5"/>
                <Setter Property="HorizontalAlignment" Value="Stretch"/>
                <Setter Property="Padding" Value="16,14"/>
                <Setter Property="Margin" Value="0,0,0,10"/>
                <Setter Property="FontSize" Value="13"/>
                <Setter Property="FontWeight" Value="SemiBold"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="ToggleButton">
                            <Border x:Name="Bd" Background="{TemplateBinding Background}" 
                                    BorderBrush="{TemplateBinding BorderBrush}" 
                                    BorderThickness="{TemplateBinding BorderThickness}" 
                                    CornerRadius="8" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsChecked" Value="True">
                                    <Setter TargetName="Bd" Property="BorderBrush" Value="#F52C42"/>
                                    <Setter TargetName="Bd" Property="BorderThickness" Value="1.5"/>
                                    <Setter TargetName="Bd" Property="Background" Value="#1F151B"/>
                                </Trigger>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="Bd" Property="Background" Value="#222235"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
        </Window.Resources>
        
        <Border Background="#101019" CornerRadius="12" BorderBrush="#242436" BorderThickness="1" Padding="24" Margin="10">
            <Border.Effect>
                <DropShadowEffect Color="#000000" Direction="270" ShadowDepth="4" BlurRadius="15" Opacity="0.5"/>
            </Border.Effect>
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                
                <TextBlock Grid.Row="0" Text="$($Item.Name)" FontSize="18" FontWeight="ExtraBold" Foreground="#F4F4F4" Margin="0,0,0,8" TextWrapping="Wrap"/>
                <TextBlock Grid.Row="0" Text="Selecione um dos valores abaixo para aplicar a otimização." FontSize="13" Foreground="#6F7581" Margin="0,28,0,20" TextWrapping="Wrap"/>
                
                <StackPanel x:Name="TokensPanel" Grid.Row="1" Margin="0,0,0,20" HorizontalAlignment="Stretch"/>
                
                <Grid Grid.Row="2">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="14"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Button x:Name="BtnCancel" Grid.Column="0" Content="Cancelar" 
                            Background="#1D1D2A" Foreground="#F4F4F4" BorderThickness="0" Padding="12" 
                            Cursor="Hand" FontWeight="SemiBold" Height="42">
                        <Button.Template>
                            <ControlTemplate TargetType="Button">
                                <Border Background="{TemplateBinding Background}" CornerRadius="8"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
                            </ControlTemplate>
                        </Button.Template>
                    </Button>
                    
                    <Button x:Name="BtnApply" Grid.Column="2" Content="Aplicar" 
                            Background="#F52C42" Foreground="#F4F4F4" BorderThickness="0" Padding="12" 
                            Cursor="Hand" FontWeight="SemiBold" Height="42">
                        <Button.Template>
                            <ControlTemplate TargetType="Button">
                                <Border Background="{TemplateBinding Background}" CornerRadius="8"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
                            </ControlTemplate>
                        </Button.Template>
                    </Button>
                </Grid>
            </Grid>
        </Border>
    </Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader ([xml]$modalXaml)
    $modal = [Windows.Markup.XamlReader]::Load($reader)
    $modal.Owner = $OwnerWindow 

    $TokensPanel = $modal.FindName("TokensPanel")
    $script:ActiveToggles = @() # Usando escopo de script para garantir acesso no clique

    # --- Passo 1: Cria todos os Toggles primeiro ---
    foreach ($val in $Item.Values) {
        $tb = [System.Windows.Controls.Primitives.ToggleButton]::new()
        $tb.Tag = $val.Command

        # Cria um StackPanel para conter o Título e a Descrição
        $stack = [System.Windows.Controls.StackPanel]::new()
        $stack.HorizontalAlignment = 'Center'
        $stack.VerticalAlignment = 'Center'
        
        # Título do Valor
        $lblTitle = [System.Windows.Controls.TextBlock]::new()
        $lblTitle.Text = $val.Label
        $lblTitle.FontWeight = [System.Windows.FontWeights]::SemiBold
        $lblTitle.FontSize = 13.5
        $lblTitle.HorizontalAlignment = 'Center'
        $null = $stack.Children.Add($lblTitle)
        
        # Descrição do Valor (se existir no JSON)
        if ($null -ne $val.Description -and -not [string]::IsNullOrWhiteSpace($val.Description)) {
            $lblDesc = [System.Windows.Controls.TextBlock]::new()
            $lblDesc.Text = $val.Description
            $lblDesc.FontSize = 11.5
            $lblDesc.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#9EA7B8')
            $lblDesc.HorizontalAlignment = 'Center'
            $lblDesc.Margin = [System.Windows.Thickness]::new(0,3,0,0)
            $null = $stack.Children.Add($lblDesc)
        }

        # Define o StackPanel completo como conteúdo do botão
        $tb.Content = $stack
        
        $script:ActiveToggles += $tb
        $null = $TokensPanel.Children.Add($tb)
    }

    # --- Passo 2: Define os handlers de clique (Mata o Bug de Múltipla Seleção) ---
    foreach ($currentTb in $script:ActiveToggles) {
        $currentTb.Add_Click({
            param($sender, $e)
            
            # Se o usuário clicou para desativar o ÚNICO selecionado -> forçamos ligar de novo
            if ($sender.IsChecked -eq $false) {
                $sender.IsChecked = $true
                return
            }

            # Desativa TODOS os outros toggles na lista
            foreach ($otherTbx in $script:ActiveToggles) {
                if ($otherTbx -ne $sender) {
                    $otherTbx.IsChecked = $false
                }
            }
        })
    }

    # Marca a opção salva na memória OU a primeira opção por padrão
    $hasSelection = $false
    foreach ($btnToggle in $script:ActiveToggles) {
        if ($btnToggle.Tag -eq $Item.SavedValue) {
            $btnToggle.IsChecked = $true
            $hasSelection = $true
            break
        }
    }
    if (-not $hasSelection -and $script:ActiveToggles.Count -gt 0) { 
        $script:ActiveToggles[0].IsChecked = $true 
    }

    $script:SelectedCommandResult = $null
    
    $modal.FindName("BtnCancel").Add_Click({ 
        $modal.DialogResult = $false 
    })
    
    $modal.FindName("BtnApply").Add_Click({ 
        # Pega estritamente o primeiro botão marcado para evitar retorno de Array
        $selectedTb = ($script:ActiveToggles | Where-Object IsChecked -eq $true) | Select-Object -First 1
        
        if ($selectedTb) {
            $script:SelectedCommandResult = [string]$selectedTb.Tag
            $modal.DialogResult = $true 
        } else {
            $modal.DialogResult = $false
        }
    })

    if ($modal.ShowDialog() -eq $true) {
        return $script:SelectedCommandResult
    }
    return $null
}

# --- Filtro Universal de Compatibilidade de Hardware ---
function Get-CompatibleItems {
    param([array]$Items)
    if ($null -eq $Items -or $Items.Count -eq 0) { return @() }

    $filtered = @()
    foreach ($item in $Items) {
        $reqGpu = [string]$item.gpu
        $reqGpu = $reqGpu.Trim()
        
        # 1. Se NÃO tiver restrição no JSON (vazio ou "Todas") -> Passa direto!
        if ([string]::IsNullOrWhiteSpace($reqGpu) -or $reqGpu -match "^(?i)Todas?$") {
            $filtered += $item
            continue
        }
        
        # 2. Se TIVER restrição, tem que ser a exata mesma marca que detectamos no sistema
        if ($reqGpu -match "(?i)$($global:PulseDetectedBrand)") {
            $filtered += $item
        }
    }
    
    return $filtered
}

# --- Atualização da lista de Geral ---
function Update-GeralItems {
    $selectedTab = $script:Tabs_Geral.SelectedItem
    if ($null -eq $selectedTab) { return }
    $filtered = @($script:Opts_Geral | Where-Object { $_.TabKey -eq $selectedTab.Tag })
    Set-ListOrEmpty -Panel $script:Items_Geral -Scroll $script:Scroll_Geral -MsgBlock $script:Msg_Geral -Items $filtered
}

# --- Atualização da lista de Hardware ---
function Update-HardwareItems {
    $selectedTab = $script:Tabs_Hardware.SelectedItem
    if ($null -eq $selectedTab) { return }
    $filtered = @($script:Opts_Hardware | Where-Object { $_.TabKey -eq $selectedTab.Tag })
    Set-ListOrEmpty -Panel $script:Items_Hardware -Scroll $script:Scroll_Hardware -MsgBlock $script:Msg_Hardware -Items $filtered
}

# --- Carrega páginas sem abas (Internet, Limpeza, Restaurar) ---
function Load-TablessPages {
    Set-ListOrEmpty -Panel $script:Items_Internet -Scroll $script:Scroll_Internet -MsgBlock $script:Msg_Internet -Items @($script:Opts_Internet)
    Set-ListOrEmpty -Panel $script:Items_Restaurar -Scroll $script:Scroll_Restaurar -MsgBlock $script:Msg_Restaurar -Items @($script:Opts_Restaurar)
}

# --- Preenche os Toggle Cards da aba Limpeza ---
function Load-LimpezaItems {
    $script:LimpezaGrid.Children.Clear()
    
    if ($script:Opts_Limpeza.Count -gt 0) {
        foreach ($item in $script:Opts_Limpeza) {
            $tb = [System.Windows.Controls.Primitives.ToggleButton]::new()
            $tb.Style = $window.Resources['LimpezaCardToggleStyle']
            
            $grid = [System.Windows.Controls.Grid]::new()
            $grid.VerticalAlignment = 'Center'
            
            $r0 = [System.Windows.Controls.RowDefinition]::new(); $r0.Height = 'Auto'
            $r1 = [System.Windows.Controls.RowDefinition]::new(); $r1.Height = 'Auto'
            $grid.RowDefinitions.Add($r0)
            $grid.RowDefinitions.Add($r1)
            
            $tbName = [System.Windows.Controls.TextBlock]::new()
            $tbName.Text = $item.Name; $tbName.FontSize = 14; $tbName.FontWeight = [System.Windows.FontWeights]::SemiBold
            $tbName.Foreground = $window.Resources['PanelPrimaryText']
            $tbName.VerticalAlignment = 'Center'; $tbName.TextTrimming = 'CharacterEllipsis'
            $tbName.Margin = [System.Windows.Thickness]::new(0,0,14,0)
            [System.Windows.Controls.Grid]::SetRow($tbName, 0)
            
            $tbDesc = [System.Windows.Controls.TextBlock]::new()
            $tbDesc.Text = $item.Description; $tbDesc.FontSize = 12
            $tbDesc.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#6F7581')
            $tbDesc.VerticalAlignment = 'Center'; $tbDesc.TextTrimming = 'CharacterEllipsis'
            $tbDesc.Margin = [System.Windows.Thickness]::new(0,6,14,0)
            [System.Windows.Controls.Grid]::SetRow($tbDesc, 1)

            $null = $grid.Children.Add($tbName)
            $null = $grid.Children.Add($tbDesc)
            
            $tb.Content = $grid
            $tb.Tag = @{ ApplyBat = $item.ApplyBat; ApplyParam = $item.ApplyParam; Perfil = [string]$item.limpeza }
            
            $tb.Add_Click({
                $temSelecionado = $false
                foreach ($child in $script:LimpezaGrid.Children) {
                    if ($child.IsChecked -eq $true) { $temSelecionado = $true; break }
                }
                $script:BtnIniciarLimpeza.IsEnabled = $temSelecionado
            })
            
            $null = $script:LimpezaGrid.Children.Add($tb)
        }
    }
}

# --- Define a visibilidade das abas dinâmicas do Pulse Mode ---
function Init-PulseModeTabs {
    $script:Tab_Pulse_Geral.Visibility = if (@($script:Opts_Geral | Where-Object { $_.pulsemode -match "(?i)sim" }).Count -gt 0) { 'Visible' } else { 'Collapsed' }
    $script:Tab_Pulse_Hardware.Visibility = if (@($script:Opts_Hardware | Where-Object { $_.pulsemode -match "(?i)sim" }).Count -gt 0) { 'Visible' } else { 'Collapsed' }
    $script:Tab_Pulse_Internet.Visibility = if (@($script:Opts_Internet | Where-Object { $_.pulsemode -match "(?i)sim" }).Count -gt 0) { 'Visible' } else { 'Collapsed' }
}

# --- Atualiza a lista da aba ativa no Pulse Mode ---
function Update-PulseModeItems {
    $selectedTab = $script:Tabs_PulseMode.SelectedItem
    if ($null -eq $selectedTab) { return }
    $tabKey = $selectedTab.Tag

    $script:PulseWarningBox.Visibility = if ($tabKey -eq "pulsemode") { 'Visible' } else { 'Collapsed' }

    $filtered = @()
    if ($tabKey -eq "pulsemode" -or $tabKey -eq "pulse_latencia") {
        $filtered = @($script:Opts_PulseMode | Where-Object { $_.TabKey -eq $tabKey })
    } elseif ($tabKey -eq "pulse_dyn_geral") {
        $filtered = @($script:Opts_Geral | Where-Object { $_.pulsemode -match "(?i)sim" })
    } elseif ($tabKey -eq "pulse_dyn_hardware") {
        $filtered = @($script:Opts_Hardware | Where-Object { $_.pulsemode -match "(?i)sim" })
    } elseif ($tabKey -eq "pulse_dyn_internet") {
        $filtered = @($script:Opts_Internet | Where-Object { $_.pulsemode -match "(?i)sim" })
    }

    Set-ListOrEmpty -Panel $script:Items_PulseMode -Scroll $script:Scroll_PulseMode -MsgBlock $script:Msg_PulseMode -Items $filtered
}

# --- Lógica do Dashboard Pulse Mode (Sanfona e Mestre) ---
function Update-MasterPulseToggleState {
    [bool]$allOn = ($script:TglPulseModeGeral.IsChecked -eq $true -and $script:TglPulseModeHardware.IsChecked -eq $true -and $script:TglPulseModeInternet.IsChecked -eq $true)
    $script:TglPulseModeMaster.IsChecked = $allOn
    $script:LedPulseModeMaster.Background = if ($allOn) { $window.Resources["ColorAccent"] } else { [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#3A3B4A') }
}

# Flip Visual Dinâmico para o Dashboard
function Sync-DashboardVisuals {
    foreach ($card in $script:Items_PulseMode.Children) {
        if ($null -ne $card.Tag) {
            $item = $card.Tag.Item
            $toggle = $card.Tag.Toggle
            $btnEdit = $card.Tag.BtnEdit

            $toggle.IsChecked = $item.IsChecked 

            if ($item.IsChecked -eq $true -and $null -ne $item.Values -and $item.Values.Count -gt 0) {
                $btnEdit.Visibility = 'Visible'
            } else {
                $btnEdit.Visibility = 'Collapsed'
            }
        }
    }
}

$script:TglPulseSubGeral.Add_Click({
    if ($script:TglPulseModeGeral.IsChecked -ne $this.IsChecked) {
        $script:TglPulseModeGeral.IsChecked = $this.IsChecked
        $script:TglPulseModeGeral.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
        Sync-DashboardVisuals
    }
})

$script:TglPulseSubHardware.Add_Click({
    if ($script:TglPulseModeHardware.IsChecked -ne $this.IsChecked) {
        $script:TglPulseModeHardware.IsChecked = $this.IsChecked
        $script:TglPulseModeHardware.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
        Sync-DashboardVisuals
    }
})

$script:TglPulseSubInternet.Add_Click({
    if ($script:TglPulseModeInternet.IsChecked -ne $this.IsChecked) {
        $script:TglPulseModeInternet.IsChecked = $this.IsChecked
        $script:TglPulseModeInternet.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
        Sync-DashboardVisuals
    }
})

$script:TglPulseModeMaster.Add_Click({
    $modoAtivo = $this.IsChecked
    $this.IsEnabled = $false
    $this.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)

    $todosItensPulse = @($script:Opts_PulseMode) + 
                       @($script:Opts_Geral | Where-Object { $_.pulsemode -match "sim" }) +
                       @($script:Opts_Hardware | Where-Object { $_.pulsemode -match "sim" }) +
                       @($script:Opts_Internet | Where-Object { $_.pulsemode -match "sim" })

    if ($modoAtivo) {
        $itensComValores = @()
        foreach ($i in $todosItensPulse) { if ($null -ne $i.Values -and $i.Values.Count -gt 0) { $itensComValores += $i } }

        $configEscolhida = @{}
        if ($itensComValores.Count -gt 0) {
            $resModal = Show-PulseConfigModal -ItemsWithValues $itensComValores -OwnerWindow $window
            if ($null -eq $resModal) { 
                $this.IsChecked = $false
                $this.IsEnabled = $true
                return
            }
            $configEscolhida = $resModal
        }

        foreach ($item in $todosItensPulse) {
            $item.IsChecked = $true
            $global:PulseState[[string]$item.Id] = $true
            
            $batAbs = ""
            $param = ""

            if ($configEscolhida.ContainsKey($item.Id)) {
                $cmdFull = $configEscolhida[$item.Id].Trim()
                
                # SALVA A ESCOLHA FEITA PELO PULSE MODE
                $item.SavedValue = $cmdFull
                $global:PulseState["$($item.Id)_Value"] = $cmdFull
                
                $lastSpace = $cmdFull.LastIndexOf(' ')
                if ($lastSpace -ge 0) {
                    $batRel = $cmdFull.Substring(0, $lastSpace).TrimStart('.').TrimStart('\').TrimStart('/')
                    $param  = $cmdFull.Substring($lastSpace + 1)
                } else {
                    $batRel = $cmdFull.TrimStart('.').TrimStart('\').TrimStart('/')
                    $param  = ""
                }
                $batAbs = Join-Path $script:BaseDir $batRel
            } else {
                $batAbs = $item.ApplyBat
                $param = $item.ApplyParam
            }
            
            if (-not [string]::IsNullOrWhiteSpace($batAbs) -and (Test-Path $batAbs)) {
                Add-PulseJob -BatPath $batAbs -Param $param -OptName $item.Name -Action "Aplicar"
            }
        }
    } else {
        foreach ($item in $todosItensPulse) {
            $item.IsChecked = $false
            $global:PulseState[[string]$item.Id] = $false
            
            $batAbs = $item.RevertBat
            $param = $item.RevertParam
            
            if (-not [string]::IsNullOrWhiteSpace($batAbs) -and (Test-Path $batAbs)) {
                Add-PulseJob -BatPath $batAbs -Param $param -OptName $item.Name -Action "Reverter"
            }
        }
    }

    $toggles = @($script:TglPulseSubGeral, $script:TglPulseSubHardware, $script:TglPulseSubInternet)
    foreach ($tgl in $toggles) {
        if ($tgl.IsChecked -ne $modoAtivo) {
            $tgl.IsChecked = $modoAtivo
            $tgl.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
        }
    }

    Save-PulseState
    Sync-DashboardVisuals
    $this.IsEnabled = $true
})

# --- Interruptor Mestre: Pulse Mode (Geral) ---
$script:TglPulseModeGeral.Add_Click({
    [bool]$modoAtivo = if ($this.IsChecked -eq $true) { $true } else { $false }
    $script:TglPulseModeGeral.IsEnabled = $false
    $script:TglPulseModeGeral.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)

    foreach ($item in $script:Opts_Geral) {
        [bool]$estadoAtual = if ($item.IsChecked -eq $true) { $true } else { $false }
        
        if ($item.pulsemode -match "(?i)sim" -and $estadoAtual -ne $modoAtivo) {
            $item.IsChecked = $modoAtivo
            $global:PulseState[[string]$item.Id] = $modoAtivo 
            
            $bat = if ($modoAtivo) { $item.ApplyBat } else { $item.RevertBat }
            $param = if ($modoAtivo) { $item.ApplyParam } else { $item.RevertParam }
            
            if (-not [string]::IsNullOrWhiteSpace($bat) -and (Test-Path $bat)) {
                $action = if ($modoAtivo) { "Aplicar" } else { "Reverter" }
                Add-PulseJob -BatPath $bat -Param $param -OptName $item.Name -Action $action
            }
        }
    }
    
    foreach ($card in $script:Items_Geral.Children) {
        if ($null -ne $card.Tag -and $card.Tag.Item.pulsemode -match "(?i)sim") {
            $card.Tag.Toggle.IsChecked = $modoAtivo
        }
    }
    
    $global:PulseState["Master_Geral"] = $modoAtivo
    Save-PulseState 
    
    $script:LedPulseModeGeral.Background = if ($modoAtivo) { $window.Resources["ColorAccent"] } else { [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#3A3B4A') }
    $script:TglPulseSubGeral.IsChecked = $modoAtivo
    $script:LedPulseSubGeral.Background = if ($modoAtivo) { $window.Resources["ColorAccent"] } else { [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#3A3B4A') }
    Update-MasterPulseToggleState
    $script:TglPulseModeGeral.IsEnabled = $true
})

# --- Interruptor Mestre: Pulse Mode (Hardware) ---
$script:TglPulseModeHardware.Add_Click({
    [bool]$modoAtivo = if ($this.IsChecked -eq $true) { $true } else { $false }
    $script:TglPulseModeHardware.IsEnabled = $false
    $script:TglPulseModeHardware.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)

    foreach ($item in $script:Opts_Hardware) {
        [bool]$estadoAtual = if ($item.IsChecked -eq $true) { $true } else { $false }
        
        if ($item.pulsemode -match "(?i)sim" -and $estadoAtual -ne $modoAtivo) {
            $item.IsChecked = $modoAtivo
            $global:PulseState[[string]$item.Id] = $modoAtivo
            
            $bat = if ($modoAtivo) { $item.ApplyBat } else { $item.RevertBat }
            $param = if ($modoAtivo) { $item.ApplyParam } else { $item.RevertParam }
            
            if (-not [string]::IsNullOrWhiteSpace($bat) -and (Test-Path $bat)) {
                $action = if ($modoAtivo) { "Aplicar" } else { "Reverter" }
                Add-PulseJob -BatPath $bat -Param $param -OptName $item.Name -Action $action
            }
        }
    }
    
    foreach ($card in $script:Items_Hardware.Children) {
        if ($null -ne $card.Tag -and $card.Tag.Item.pulsemode -match "(?i)sim") {
            $card.Tag.Toggle.IsChecked = $modoAtivo
        }
    }
    
    $global:PulseState["Master_Hardware"] = $modoAtivo
    Save-PulseState 
    
    $script:LedPulseModeHardware.Background = if ($modoAtivo) { $window.Resources["ColorAccent"] } else { [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#3A3B4A') }
    $script:TglPulseSubHardware.IsChecked = $modoAtivo
    $script:LedPulseSubHardware.Background = if ($modoAtivo) { $window.Resources["ColorAccent"] } else { [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#3A3B4A') }
    Update-MasterPulseToggleState
    $script:TglPulseModeHardware.IsEnabled = $true
})

# --- Interruptor Mestre: Pulse Mode (Internet) ---
$script:TglPulseModeInternet.Add_Click({
    [bool]$modoAtivo = if ($this.IsChecked -eq $true) { $true } else { $false }
    $script:TglPulseModeInternet.IsEnabled = $false
    $script:TglPulseModeInternet.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)

    foreach ($item in $script:Opts_Internet) {
        [bool]$estadoAtual = if ($item.IsChecked -eq $true) { $true } else { $false }
        
        if ($item.pulsemode -match "(?i)sim" -and $estadoAtual -ne $modoAtivo) {
            $item.IsChecked = $modoAtivo
            $global:PulseState[[string]$item.Id] = $modoAtivo
            
            $bat = if ($modoAtivo) { $item.ApplyBat } else { $item.RevertBat }
            $param = if ($modoAtivo) { $item.ApplyParam } else { $item.RevertParam }
            
            if (-not [string]::IsNullOrWhiteSpace($bat) -and (Test-Path $bat)) {
                $action = if ($modoAtivo) { "Aplicar" } else { "Reverter" }
                Add-PulseJob -BatPath $bat -Param $param -OptName $item.Name -Action $action
            }
        }
    }

    foreach ($card in $script:Items_Internet.Children) {
        if ($null -ne $card.Tag -and $card.Tag.Item.pulsemode -match "(?i)sim") {
            $card.Tag.Toggle.IsChecked = $modoAtivo
        }
    }

    $global:PulseState["Master_Internet"] = $modoAtivo
    Save-PulseState 
    
    $script:LedPulseModeInternet.Background = if ($modoAtivo) { $window.Resources["ColorAccent"] } else { [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#3A3B4A') }
    $script:TglPulseSubInternet.IsChecked = $modoAtivo
    $script:LedPulseSubInternet.Background = if ($modoAtivo) { $window.Resources["ColorAccent"] } else { [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#3A3B4A') }
    Update-MasterPulseToggleState
    $script:TglPulseModeInternet.IsEnabled = $true
})

# --- Evento de Troca de Aba no Pulse Mode ---
$script:Tabs_PulseMode.Add_SelectionChanged({
    param($s, $e)
    if ($e.Source -ne $s) { return }
    Update-PulseModeItems
})

function Show-PulseConfigModal {
    param([array]$ItemsWithValues, [System.Windows.Window]$OwnerWindow)

    $modalXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Width="560" Height="680" WindowStartupLocation="CenterOwner"
            WindowStyle="None" AllowsTransparency="True" Background="Transparent" ShowInTaskbar="False">
        
        <Window.Resources>
            <SolidColorBrush x:Key="ColorAccent" Color="#F52C42"/>
            
            <Style TargetType="ToggleButton">
                <Setter Property="Foreground" Value="#F4F4F4"/>
                <Setter Property="Background" Value="#191923"/>
                <Setter Property="BorderBrush" Value="#242436"/>
                <Setter Property="BorderThickness" Value="1.5"/>
                <Setter Property="HorizontalAlignment" Value="Stretch"/>
                <Setter Property="Padding" Value="16,8"/>
                <Setter Property="Margin" Value="0,0,0,10"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="ToggleButton">
                            <Border x:Name="Bd" Background="{TemplateBinding Background}" 
                                    BorderBrush="{TemplateBinding BorderBrush}" 
                                    BorderThickness="{TemplateBinding BorderThickness}" 
                                    CornerRadius="8" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsChecked" Value="True">
                                    <Setter TargetName="Bd" Property="BorderBrush" Value="{StaticResource ColorAccent}"/>
                                    <Setter TargetName="Bd" Property="BorderThickness" Value="1.5"/>
                                    <Setter TargetName="Bd" Property="Background" Value="#1F151B"/>
                                </Trigger>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="Bd" Property="Background" Value="#222235"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

            <Style TargetType="ScrollBar">
                <Setter Property="Background" Value="Transparent" />
                <Setter Property="Width" Value="5" />
                <Setter Property="BorderThickness" Value="0" />
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="ScrollBar">
                            <Grid Background="{TemplateBinding Background}">
                                <Track x:Name="PART_Track" IsDirectionReversed="True">
                                    <Track.Thumb>
                                        <Thumb>
                                            <Thumb.Template>
                                                <ControlTemplate TargetType="Thumb">
                                                    <Border x:Name="ThumbBorder" Background="#242436" CornerRadius="4" Margin="10,0,0,0"/>
                                                    <ControlTemplate.Triggers>
                                                        <Trigger Property="IsMouseOver" Value="True">
                                                            <Setter TargetName="ThumbBorder" Property="Background" Value="#3A3B4A"/>
                                                        </Trigger>
                                                        <Trigger Property="IsDragging" Value="True">
                                                            <Setter TargetName="ThumbBorder" Property="Background" Value="{StaticResource ColorAccent}"/>
                                                        </Trigger>
                                                    </ControlTemplate.Triggers>
                                                </ControlTemplate>
                                            </Thumb.Template>
                                        </Thumb>
                                    </Track.Thumb>
                                </Track>
                            </Grid>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
        </Window.Resources>
        
        <Border Background="#101019" CornerRadius="12" BorderBrush="#242436" BorderThickness="1" Padding="24">
            <Border.Effect>
                <DropShadowEffect Color="#000000" Direction="270" ShadowDepth="4" BlurRadius="15" Opacity="0.5"/>
            </Border.Effect>
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                
                <TextBlock Grid.Row="0" Text="Configurar Otimizações" FontSize="20" FontWeight="Black" Foreground="#F4F4F4" Margin="0,0,0,8"/>
                <TextBlock Grid.Row="1" Text="Escolha os perfis desejados para aplicar nas otimizações ativadas." FontSize="13" Foreground="#6F7581" Margin="0,0,0,20"/>
                
                <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" Margin="0,0,-10,20" Padding="0,0,10,0">
                    <StackPanel x:Name="ConfigStack"/>
                </ScrollViewer>
                
                <Button x:Name="BtnApply" Grid.Row="3" Content="Aplicar Seleção e Iniciar" Background="#F52C42" Foreground="#F4F4F4" BorderThickness="0" Cursor="Hand" FontWeight="SemiBold" Height="45" FontSize="15">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="BtnBorder" Background="{TemplateBinding Background}" CornerRadius="8">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="BtnBorder" Property="Opacity" Value="0.9"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </Grid>
        </Border>
    </Window>
"@
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$modalXaml)
    $modal = [Windows.Markup.XamlReader]::Load($reader)
    $modal.Owner = $OwnerWindow
    
    $stack = $modal.FindName("ConfigStack")
    $selections = @{}

    foreach ($item in $ItemsWithValues) {
        # 1. Título da Otimização
        $title = [System.Windows.Controls.TextBlock]::new()
        $title.Text = $item.Name
        $title.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#C9CBD6')
        $title.FontWeight = [System.Windows.FontWeights]::ExtraBold
        $title.FontSize = 17
        $title.Margin = [System.Windows.Thickness]::new(0,5,0,12)
        $null = $stack.Children.Add($title)

        # 2. Agrupador visual (StackPanel) exclusivo para esta otimização
        $optGroupPanel = [System.Windows.Controls.StackPanel]::new()
        $optGroupPanel.HorizontalAlignment = 'Stretch'

        # 3. Criação dos botões de valor
        foreach ($val in $item.Values) {
            $btn = [System.Windows.Controls.Primitives.ToggleButton]::new()
            $btn.Tag = $val.Command
            
            # --- CONSTRUÇÃO DO CONTEÚDO (Texto + Descrição) ---
            $btnContentStack = [System.Windows.Controls.StackPanel]::new()
            $btnContentStack.HorizontalAlignment = 'Center'
            $btnContentStack.VerticalAlignment = 'Center'
            
            $lblTitle = [System.Windows.Controls.TextBlock]::new()
            $lblTitle.Text = $val.Label
            $lblTitle.FontWeight = [System.Windows.FontWeights]::SemiBold
            $lblTitle.FontSize = 13.5
            $lblTitle.HorizontalAlignment = 'Center'
            $null = $btnContentStack.Children.Add($lblTitle)
            
            if ($null -ne $val.Description -and -not [string]::IsNullOrWhiteSpace($val.Description)) {
                $lblDesc = [System.Windows.Controls.TextBlock]::new()
                $lblDesc.Text = $val.Description
                $lblDesc.FontSize = 11.5
                $lblDesc.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#9EA7B8')
                $lblDesc.HorizontalAlignment = 'Center'
                $lblDesc.Margin = [System.Windows.Thickness]::new(0,3,0,0)
                $null = $btnContentStack.Children.Add($lblDesc)
            }

            $btn.Content = $btnContentStack

            # --- LÓGICA À PROVA DE FALHAS (Visual Tree) ---
            $btn.Add_Click({
                param($sender, $e)
                
                # Se tentar desmarcar a única opção ativa, força a ficar ligada
                if ($sender.IsChecked -eq $false) { 
                    $sender.IsChecked = $true
                    return 
                }

                # Procura a caixa "Pai" e desmarca os "Irmãos"
                $parent = $sender.Parent
                foreach ($sibling in $parent.Children) {
                    if ($sibling -is [System.Windows.Controls.Primitives.ToggleButton] -and $sibling -ne $sender) {
                        $sibling.IsChecked = $false
                    }
                }
                
                # Salva a nova escolha baseada no ID do Item e no Tag do Botão
                $selections[$item.Id] = $sender.Tag
            }.GetNewClosure())
            
            $null = $optGroupPanel.Children.Add($btn)
        }
        
        # 4. Força a seleção do botão salvo na memória ou o primeiro botão
        $hasSelection = $false
        foreach ($btnToggle in $optGroupPanel.Children) {
            if ($btnToggle.Tag -eq $item.SavedValue) {
                $btnToggle.IsChecked = $true
                $selections[$item.Id] = $btnToggle.Tag
                $hasSelection = $true
                break
            }
        }
        if (-not $hasSelection -and $optGroupPanel.Children.Count -gt 0) {
            $firstBtn = $optGroupPanel.Children[0]
            $firstBtn.IsChecked = $true
            $selections[$item.Id] = $firstBtn.Tag
        }

        # Adiciona o grupo de botões à tela
        $null = $stack.Children.Add($optGroupPanel)
        
        # 5. Divisor Horizontal (Apenas estético)
        $sep = [System.Windows.Controls.Border]::new()
        $sep.Height = 1
        $sep.Background = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#242436')
        $sep.Margin = [System.Windows.Thickness]::new(0,5,0,15)
        $null = $stack.Children.Add($sep)
    }

    # Evento de Conclusão do Modal
    $modal.FindName("BtnApply").Add_Click({ $modal.DialogResult = $true })
    
    if ($modal.ShowDialog() -eq $true) { 
        return $selections 
    }
    
    return $null
}

# --- Evento do Botão Iniciar Limpeza ---
$script:BtnIniciarLimpeza.Add_Click({
    # 1. Feedback visual imediato: Muda o texto e trava o botão
    $script:BtnIniciarLimpeza.Content = "Limpando..."
    $script:BtnIniciarLimpeza.IsEnabled = $false
    
    # Truque do WPF: Força a interface a atualizar o visual do botão ANTES de travar o script na limpeza
    $script:BtnIniciarLimpeza.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)

    $limpezasExecutadas = 0
    $itemsParaDesmarcar = @()
    
    foreach ($child in $script:LimpezaGrid.Children) {
        if ($child.IsChecked -eq $true) {
            $dadosExecucao = $child.Tag
            $bat = $dadosExecucao.ApplyBat
            $param = $dadosExecucao.ApplyParam
            
            if (-not [string]::IsNullOrWhiteSpace($bat) -and (Test-Path $bat)) {
                $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', "`"$bat`"", $param) -WindowStyle Hidden -Verb RunAs -PassThru
                
                # Mantém o painel respirando enquanto limpa o sistema
                while (-not $proc.HasExited) {
                    Invoke-WpfEvents
                    Start-Sleep -Milliseconds 50
                }
                
                $limpezasExecutadas++
            }
            
            # Adiciona o card na fila para ser desmarcado depois
            $itemsParaDesmarcar += $child
        }
    }
    
    # 2. A Limpeza acabou. Desmarca todos os cards selecionados.
    foreach ($item in $itemsParaDesmarcar) {
        $item.IsChecked = $false
    }
    
    # 3. Restaura o botão para o estado original
    $script:BtnIniciarLimpeza.Content = "Iniciar Limpeza"
    
    # 4. Exibe a mensagem SÓ AGORA, com o processo totalmente concluído
    if ($limpezasExecutadas -gt 0) {
        [System.Windows.MessageBox]::Show(
            "Limpeza concluída com sucesso! $limpezasExecutadas tarefa(s) finalizada(s).",
            "Painel Pulse", 'OK', 'Information'
        ) | Out-Null
    }
})

# --- Lógica dos Perfis de Limpeza ---
function Update-LimpezaBtnMasterState {
    $temSelecionado = $false
    foreach ($child in $script:LimpezaGrid.Children) {
        if ($child.IsChecked -eq $true) { $temSelecionado = $true; break }
    }
    $script:BtnIniciarLimpeza.IsEnabled = $temSelecionado
}

$script:BtnLimpezaNenhuma.Add_Click({
    foreach ($child in $script:LimpezaGrid.Children) {
        $child.IsChecked = $false
    }
    Update-LimpezaBtnMasterState
})

$script:BtnLimpezaRecomendada.Add_Click({
    foreach ($child in $script:LimpezaGrid.Children) {
        # Transforma a String (Texto) em Array (Matriz) e verifica se contém o "2"
        $perfis = $child.Tag.Perfil -split ',' | ForEach-Object { $_.Trim() }
        $child.IsChecked = ($perfis -contains '2')
    }
    Update-LimpezaBtnMasterState
})

$script:BtnLimpezaTudo.Add_Click({
    foreach ($child in $script:LimpezaGrid.Children) {
        $child.IsChecked = $true
    }
    Update-LimpezaBtnMasterState
})

# --- Detecção de hardware e Contagem de Apps após renderizar ---
$window.Add_ContentRendered({
    # Primeiro carrega os números do Dashboard imediatamente
    Refresh-DashboardCounts
    
    # Depois processa o hardware para a tela de configurações
    $hw = Detect-PulseHardware
    $window.Dispatcher.Invoke({
        $window.FindName('LblDeviceType').Text = $hw.DeviceType
        $window.FindName('ValOS').Text         = $hw.OS
        $window.FindName('ValCPU').Text        = $hw.CPU
        $window.FindName('ValGPU').Text        = $hw.GPU
        $window.FindName('ValRAM').Text        = $hw.RAM
        $window.FindName('ValStorage').Text    = $hw.Storage
    })
})

# --- Navegação do menu lateral ---
$script:NavMenu.Add_SelectionChanged({
    param($s, $e)
    if ($e.Source -ne $s) { return }

    $script:Page_Inicio.Visibility      = 'Collapsed'
    $script:Page_Restaurar.Visibility   = 'Collapsed'
    $script:Page_Geral.Visibility       = 'Collapsed'
    $script:Page_Hardware.Visibility    = 'Collapsed'
    $script:Page_Internet.Visibility    = 'Collapsed'
    $script:Page_Limpeza.Visibility     = 'Collapsed'
    $script:Page_PulseMode.Visibility   = 'Collapsed'

    $selectedItem = $script:NavMenu.SelectedItem
    if ($null -ne $selectedItem) {
        switch ($selectedItem.Tag) {
            'inicio'      { $script:Page_Inicio.Visibility      = 'Visible' }
            'pulsemode'   { $script:Page_PulseMode.Visibility   = 'Visible' }
            'restaurar'   { $script:Page_Restaurar.Visibility   = 'Visible' }
            'geral'       { $script:Page_Geral.Visibility       = 'Visible' }
            'hardware'    { $script:Page_Hardware.Visibility    = 'Visible' }
            'internet'    { $script:Page_Internet.Visibility    = 'Visible' }
            'limpeza'     { $script:Page_Limpeza.Visibility     = 'Visible' }
        }
    }
})

# --- Evento de Expandir/Recolher o Menu Sanfona do Pulse Mode ---
$script:BtnExpandPulse.Add_Click({
    if ($this.IsChecked) {
        $script:PanelPulseExpanded.Visibility = 'Visible'
    } else {
        $script:PanelPulseExpanded.Visibility = 'Collapsed'
    }
})

# --- Troca de aba: Geral ---
$script:Tabs_Geral.Add_SelectionChanged({
    param($s, $e)
    if ($e.Source -ne $s) { return }
    Update-GeralItems
})

# --- Troca de aba: Hardware ---
$script:Tabs_Hardware.Add_SelectionChanged({
    param($s, $e)
    if ($e.Source -ne $s) { return }
    Update-HardwareItems
})

# --- Botão: Fazer Backup ---
$script:BtnFazerBackup.Add_Click({
    $script:BtnFazerBackup.Content = "Aguarde..."
    $script:BtnFazerBackup.IsEnabled = $false
    # Força a UI a atualizar o botão antes do travamento da operação
    $script:BtnFazerBackup.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)

    try {
        Write-PulseLog "Iniciando processo de backup (Ponto de Restauração e Registro)."
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH-mm-ss'
        $backupName = "Painel Pulse $timestamp"

        # 1. Quebra a trava de 24 horas do Windows para Pontos de Restauração
        $SysRestoreReg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
        if (Test-Path $SysRestoreReg) {
            Set-ItemProperty -Path $SysRestoreReg -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        }

        # 2. Ativa a proteção e cria o ponto (Usando 'Stop' para cair no Catch se houver erro real)
        Write-PulseLog "Verificando/Ativando proteção do sistema no drive $env:SystemDrive\"
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop

        Write-PulseLog "Criando Ponto de Restauração com nome: $backupName"
        Checkpoint-Computer -Description $backupName -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop

        # 3. Backup Completo do Registro
        $regPath = Join-Path $script:BackupDir "$backupName.reg"
        Write-PulseLog "Exportando Registro do Windows para: $regPath"
        
        $proc = Start-Process -FilePath "regedit.exe" -ArgumentList "/e `"$regPath`"" -Wait -PassThru -WindowStyle Hidden
        
        Write-PulseLog "Backup concluído com sucesso."
        
        # Altera visualmente o botão para o estilo secundário, indicando que já foi feito
        $script:BtnFazerBackup.Style = $window.Resources['SecondaryButtonStyle']

        [System.Windows.MessageBox]::Show(
            "Ponto de Restauração e Backup do Registro criados com sucesso!`n`nArquivos salvos em:`nDocumentos\Painel Pulse\Backups",
            "Backup Concluído", 'OK', 'Information'
        ) | Out-Null
    } catch {
        Write-PulseLog "ERRO ao tentar realizar o backup: $($_.Exception.Message)"
        [System.Windows.MessageBox]::Show(
            "Falha ao criar o backup.`n`nDetalhe: $($_.Exception.Message)`n`nVerifique se o painel foi executado como Administrador.",
            "Erro de Backup", 'OK', 'Error'
        ) | Out-Null
    } finally {
        $script:BtnFazerBackup.Content = "Fazer Backup"
        $script:BtnFazerBackup.IsEnabled = $true
    }
})

# --- Botão: Pesquisar Aplicativo ---
$script:BtnSearchApp.Add_Click({
    $query = $script:TxtSearchApp.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($query)) { return }

    $resultados = Show-WingetSearchModal -Query $query -OwnerWindow $window

    if ($null -ne $resultados) {
        # O @() garante que o PowerShell trate o resultado como lista, mesmo se for só 1 item
        foreach ($app in @($resultados)) {
            $jaExiste = $false
            foreach ($child in $script:SelectedAppsPanel.Children) {
                if ($child.Tag.Id -eq $app.Id) { $jaExiste = $true; break }
            }
            if (-not $jaExiste) {
                Add-SelectedAppToken -AppName $app.Name -AppId $app.Id
            }
        }
        $script:TxtSearchApp.Text = "" 
    }
})

# --- Botão: Restaurar Sistema ---
$script:BtnRestaurar.Add_Click({
    Write-PulseLog "Usuário acionou o atalho de Restauração do Sistema."
    Start-Process "rstrui.exe"
})

# --- Botão: Abrir Log ---
$script:BtnAbrirLog.Add_Click({
    Write-PulseLog "Usuário solicitou a abertura do arquivo de Log."
    Start-Process "notepad.exe" $script:LogFile
})

# --- FUNÇÃO DE RESPIRAÇÃO PARA WPF ---
function Invoke-WpfEvents {
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    $dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    $dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [Action]{ $frame.Continue = $false }) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}

# --- Botão: Instalar Aplicativos Selecionados ---
$script:BtnInstallApps.Add_Click({
    $script:BtnInstallApps.Content = "Instalando..."
    $script:BtnInstallApps.IsEnabled = $false
    
    Invoke-WpfEvents

    $instalados = 0
    $falhas = 0

    foreach ($child in $script:SelectedAppsPanel.Children) {
        $tag = $child.Tag
        
        if ($tag.Status -eq "Installed") { continue } 

        $appId = $tag.Id
        $appName = $tag.Name
        $icon = $tag.IconElement
        $btnRemove = $tag.RemoveElement

        $child.BorderBrush = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#0078D4')
        $icon.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#0078D4')
        
        Invoke-WpfEvents

        Write-PulseLog "Iniciando instalação do aplicativo: $appName ($appId)"

        # Inicia a instalação e pega o controle do processo (-PassThru)
        $proc = Start-Process -FilePath "winget" -ArgumentList "install --id `"$appId`" --exact --silent --accept-package-agreements --accept-source-agreements" -PassThru -WindowStyle Hidden
        
        # Mantém a janela viva enquanto instala
        while (-not $proc.HasExited) {
            Invoke-WpfEvents
            Start-Sleep -Milliseconds 100
        }
        
        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq -1978335189) {
            $tag.Status = "Installed"
            $child.Background = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#12231A')
            $child.BorderBrush = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#23D160')
            
            $icon.Text = [char]0xE73E # Ícone de Check
            $icon.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#23D160')
            
            $btnRemove.Visibility = 'Collapsed'
            $instalados++
            Write-PulseLog "Instalação concluída com sucesso: $appName"
        } else {
            $tag.Status = "Failed"
            $child.Background = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#2B1C14')
            $child.BorderBrush = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#FF8C00')
            
            $icon.Text = [char]0xE7BA # Ícone de Aviso/Erro
            $icon.Foreground = [System.Windows.Media.SolidColorBrush][System.Windows.Media.ColorConverter]::ConvertFromString('#FF8C00')
            
            $falhas++
            Write-PulseLog "Falha na instalação: $appName (ExitCode: $($proc.ExitCode))"
        }
        
        Invoke-WpfEvents
    }

    $script:BtnInstallApps.Content = "Instalar Selecionados"
    
    if ($falhas -gt 0) {
        $script:BtnInstallApps.IsEnabled = $true 
    }

    [System.Windows.MessageBox]::Show(
        "Fila de instalação finalizada!`n`nSucesso: $instalados`nFalhas: $falhas",
        "Instalador de Pacotes", 'OK', 'Information'
    ) | Out-Null
})

# --- Carga inicial das listas ---
Update-GeralItems
Update-HardwareItems
Load-TablessPages
Load-LimpezaItems
Init-PulseModeTabs
Update-PulseModeItems
Update-MasterPulseToggleState

$window.Add_Closing({
    Write-PulseLog "Painel Pulse encerrado. Iniciando limpeza de arquivos temporários."
    $global:PulseQueueTimer.Stop()

    $dirToDelete = $script:BaseDir
    Start-Process powershell -ArgumentList "-WindowStyle Hidden -Command `"Start-Sleep -Seconds 3; Remove-Item -Path '$dirToDelete' -Recurse -Force -ErrorAction SilentlyContinue`"" -WindowStyle Hidden
})

$window.ShowDialog() | Out-Null
