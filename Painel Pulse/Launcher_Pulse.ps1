#Requires -Version 5.1
# ==========================================
# LAUNCHER PULSE
# ==========================================
$Script:LauncherVersion = "V1.0.3"

# ==========================================
# CONFIGURACOES GERAIS
# ==========================================
$RepoBase = "https://raw.githubusercontent.com/cbarboza02/pulse/main/Painel%20Pulse"
$LauncherScriptUrl = "$RepoBase/Launcher_Pulse.ps1"
$PanelScriptUrl    = "$RepoBase/Painel_Pulse.ps1"
$VerifierScriptUrl = "$RepoBase/verificar_pulseos.ps1"
$IconUrl           = "$RepoBase/pulseicon.ico"

$InstallDir           = "C:\Painel Pulse"
$InstalledLauncherExe = Join-Path $InstallDir "Painel Pulse.exe"

$Base     = Join-Path $env:TEMP "Painel Pulse"
$JsonDir  = Join-Path $Base "json"
$CmdsDir  = Join-Path $Base "comandos"
$EXEPath  = Join-Path $Base "Painel Pulse.exe"
$LogPath  = Join-Path $env:TEMP "Launcher_Pulse.log"

$TempPanelPs1       = Join-Path $env:TEMP "temp_painel_pulse.ps1"
$TempPanelBuildPs1  = Join-Path $env:TEMP "build_painel_pulse.ps1"
$TempPanelIcon      = Join-Path $env:TEMP "temp_pulseicon.ico"
$TempVerifierPs1    = Join-Path $env:TEMP "verificar_pulseos.ps1"

$TempLauncherPs1    = Join-Path $env:TEMP "Launcher_Pulse.remote.ps1"
$TempLauncherBuild  = Join-Path $env:TEMP "Launcher_Pulse.build.ps1"
$TempLauncherExe    = Join-Path $env:TEMP "Painel Pulse.update.exe"
$TempLauncherIcon   = Join-Path $env:TEMP "Launcher_Pulse.update.ico"
$UpdateHelperPath   = Join-Path $env:TEMP "PulseOS_Launcher_Update_Helper.ps1"

$JsonFiles = @(
    "pulse_geral.json",
    "pulse_hardware.json",
    "pulse_internet.json",
    "pulse_limpeza.json",
    "pulse_pulsemode.json",
    "pulse_restaurar.json",
    "pulse_reparar.json"
)

# ==========================================
# FUNCOES AUXILIARES
# ==========================================
function Write-Log {
    param([string]$Mensagem)
    try {
        $linha = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Mensagem
        Add-Content -Path $LogPath -Value $linha -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {}
}

function Show-Erro {
    param([string]$Mensagem)
    Write-Log "ERRO: $Mensagem"
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
        [System.Windows.MessageBox]::Show(
            $Mensagem,
            "Painel Pulse",
            'OK',
            'Error'
        ) | Out-Null
    } catch {
        try { Write-Error $Mensagem } catch {}
    }
}

function Show-Info {
    param([string]$Mensagem)
    Write-Log "INFO: $Mensagem"
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
        [System.Windows.MessageBox]::Show(
            $Mensagem,
            "Painel Pulse",
            'OK',
            'Information'
        ) | Out-Null
    } catch {}
}

function Initialize-Tls {
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    } catch {}
}

function Ensure-Directory {
    param([string]$Path)
    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
        return $true
    } catch {
        Write-Log "Falha ao criar pasta '$Path': $($_.Exception.Message)"
        return $false
    }
}

function Download-Arquivo {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Destino
    )

    try {
        $parent = Split-Path -Parent $Destino
        if ($parent) { Ensure-Directory -Path $parent | Out-Null }

        Invoke-WebRequest -Uri $Url -OutFile $Destino -UseBasicParsing -ErrorAction Stop
        if (-not (Test-Path -LiteralPath $Destino)) { return $false }
        return $true
    } catch {
        Write-Log "Falha ao baixar '$Url': $($_.Exception.Message)"
        return $false
    }
}

function Get-RemoteText {
    param([Parameter(Mandatory = $true)][string]$Url)

    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -ErrorAction Stop
        return [string]$response.Content
    } catch {
        Write-Log "Falha ao ler texto remoto '$Url': $($_.Exception.Message)"
        return $null
    }
}

function Get-LauncherVersionFromContent {
    param([string]$Content)

    if ([string]::IsNullOrWhiteSpace($Content)) { return $null }

    $match = [regex]::Match($Content, '(?im)^\s*\$Script:LauncherVersion\s*=\s*["'']([^"'']+)["'']')
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }

    $fallback = [regex]::Match($Content, '(?im)^\s*#\s*PulseOS-Launcher-Version\s*:\s*([A-Za-z0-9._-]+)\s*$')
    if ($fallback.Success) {
        return $fallback.Groups[1].Value.Trim()
    }

    return $null
}

function Test-IsAdmin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Ensure-PS2EXE {
    function Test-PS2EXEAvailable {
        try {
            $cmd = Get-Command Invoke-PS2EXE -ErrorAction SilentlyContinue
            if ($null -ne $cmd) {
                Write-Log "PS2EXE encontrado: $($cmd.Source)"
                return $true
            }
        } catch {}

        try {
            Import-Module ps2exe -Force -ErrorAction SilentlyContinue
            $cmd = Get-Command Invoke-PS2EXE -ErrorAction SilentlyContinue
            if ($null -ne $cmd) {
                Write-Log "PS2EXE importado com sucesso: $($cmd.Source)"
                return $true
            }
        } catch {
            Write-Log "Falha ao importar PS2EXE existente: $($_.Exception.Message)"
        }

        return $false
    }

    function Add-PulseModulePaths {
        try {
            $candidatePaths = @(
                (Join-Path ([Environment]::GetFolderPath('MyDocuments')) "WindowsPowerShell\Modules"),
                (Join-Path ([Environment]::GetFolderPath('MyDocuments')) "PowerShell\Modules"),
                (Join-Path $env:ProgramFiles "WindowsPowerShell\Modules"),
                (Join-Path $env:ProgramFiles "PowerShell\Modules")
            ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

            $current = @($env:PSModulePath -split ';' | Where-Object { $_ })
            foreach ($path in $candidatePaths) {
                if ($current -notcontains $path) {
                    $env:PSModulePath = "$env:PSModulePath;$path"
                }
            }
        } catch {}
    }

    if (Test-PS2EXEAvailable) { return $true }

    Add-PulseModulePaths
    if (Test-PS2EXEAvailable) { return $true }

    try {
        Initialize-Tls
        Add-PulseModulePaths

        $ProgressPreference = 'SilentlyContinue'
        $ConfirmPreference = 'None'

        Write-Log "PS2EXE nao encontrado. Tentando instalar automaticamente..."

        if (-not (Get-Command Install-Module -ErrorAction SilentlyContinue)) {
            Write-Log "Install-Module nao esta disponivel neste Windows/PowerShell."
            return $false
        }

        try {
            $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
            if ($null -eq $nugetProvider) {
                Write-Log "Provider NuGet nao encontrado. Instalando..."
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            Import-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Log "Falha ao preparar provider NuGet: $($_.Exception.Message)"
        }

        try {
            $repo = Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue
            if ($null -eq $repo) {
                Write-Log "Repositorio PSGallery nao encontrado. Registrando repositorio padrao..."
                Register-PSRepository -Default -ErrorAction Stop
            }

            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue
        }
        catch {
            Write-Log "Falha ao preparar PSGallery: $($_.Exception.Message)"
        }

        $installScopes = @("CurrentUser")
        if (Test-IsAdmin) {
            $installScopes += "AllUsers"
        }

        foreach ($scope in $installScopes) {
            try {
                Write-Log "Tentando instalar PS2EXE no escopo $scope..."
                Install-Module `
                    -Name ps2exe `
                    -Repository PSGallery `
                    -Scope $scope `
                    -Force `
                    -AllowClobber `
                    -SkipPublisherCheck `
                    -Confirm:$false `
                    -ErrorAction Stop | Out-Null

                Add-PulseModulePaths

                try {
                    Import-Module ps2exe -Force -ErrorAction Stop
                } catch {
                    Write-Log "Modulo instalado, mas falhou ao importar no escopo $($scope): $($_.Exception.Message)"
                }

                if (Test-PS2EXEAvailable) {
                    Write-Log "PS2EXE instalado/carregado com sucesso no escopo $scope."
                    return $true
                }
            }
            catch {
                Write-Log "Falha ao instalar PS2EXE no escopo $($scope): $($_.Exception.Message)"
            }
        }
    }
    catch {
        Write-Log "Falha geral ao instalar/carregar PS2EXE: $($_.Exception.Message)"
    }

    Add-PulseModulePaths
    if (Test-PS2EXEAvailable) { return $true }

    Show-Erro "PS2EXE nao foi encontrado e a instalacao automatica falhou.`nVerifique a conexao com a internet, PSGallery/PowerShellGet e tente novamente."
    return $false
}

function New-BuildScript {
    param(
        [Parameter(Mandatory = $true)][string]$InputPs1,
        [Parameter(Mandatory = $true)][string]$OutputPs1
    )

    try {
        $content = Get-Content -LiteralPath $InputPs1 -Raw -Encoding UTF8 -ErrorAction Stop
        $content = $content -replace '(?m)^\s*#Requires[^\r\n]*(\r?\n)?', ''
        $utf8Bom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($OutputPs1, $content, $utf8Bom)
        return $true
    } catch {
        Write-Log "Falha ao preparar script para conversao '$InputPs1': $($_.Exception.Message)"
        return $false
    }
}

function Convert-PS1ToExe {
    param(
        [Parameter(Mandatory = $true)][string]$InputPs1,
        [Parameter(Mandatory = $true)][string]$OutputExe,
        [string]$IconFile,
        [string]$Title = "Painel Pulse"
    )

    if (-not (Ensure-PS2EXE)) { return $false }
    if (-not (Test-Path -LiteralPath $InputPs1)) { return $false }

    try {
        if (Test-Path -LiteralPath $OutputExe) {
            Remove-Item -LiteralPath $OutputExe -Force -ErrorAction SilentlyContinue
        }

        $params = @{
            inputFile  = $InputPs1
            outputFile = $OutputExe
            noConsole  = $true
            title      = $Title
            company    = "PulseOS"
        }

        if ($IconFile -and (Test-Path -LiteralPath $IconFile)) {
            $params.iconFile = $IconFile
        }

        Invoke-PS2EXE @params *>&1 | Out-Null

        if (-not (Test-Path -LiteralPath $OutputExe)) {
            Write-Log "PS2EXE terminou, mas o arquivo nao foi criado: $OutputExe"
            return $false
        }

        return $true
    } catch {
        Write-Log "Falha ao converter '$InputPs1' para '$OutputExe': $($_.Exception.Message)"
        return $false
    }
}

function Start-LauncherReplacement {
    param(
        [Parameter(Mandatory = $true)][string]$NewExe,
        [Parameter(Mandatory = $true)][string]$TargetExe
    )

    try {
        $helper = @'
param(
    [int]$ParentPid,
    [string]$Source,
    [string]$Target
)

$ErrorActionPreference = "SilentlyContinue"

try {
    Wait-Process -Id $ParentPid -Timeout 90
} catch {}

Start-Sleep -Milliseconds 700

try {
    $targetDir = Split-Path -Parent $Target
    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    Copy-Item -LiteralPath $Source -Destination $Target -Force
    Start-Sleep -Milliseconds 500
    Start-Process -FilePath $Target | Out-Null

    Remove-Item -LiteralPath $Source -Force -ErrorAction SilentlyContinue
} catch {
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
        [System.Windows.MessageBox]::Show(
            "Falha ao atualizar o Painel Pulse:`n$($_.Exception.Message)",
            "Painel Pulse",
            'OK',
            'Error'
        ) | Out-Null
    } catch {}
}
'@

        $utf8Bom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($UpdateHelperPath, $helper, $utf8Bom)

        $powershellExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$UpdateHelperPath`" -ParentPid $PID -Source `"$NewExe`" -Target `"$TargetExe`""

        if (Test-IsAdmin) {
            Start-Process -FilePath $powershellExe -ArgumentList $arguments -WindowStyle Hidden | Out-Null
        } else {
            Start-Process -FilePath $powershellExe -ArgumentList $arguments -Verb RunAs | Out-Null
        }

        return $true
    } catch {
        Show-Erro "Falha ao iniciar a atualizacao do Painel Pulse.`n$($_.Exception.Message)"
        return $false
    }
}

function Test-Internet {
    try {
        $req = [System.Net.WebRequest]::Create("https://raw.githubusercontent.com")
        $req.Timeout = 5000
        $resp = $req.GetResponse()
        if ($resp) { $resp.Close() }
        return $true
    } catch {
        return $false
    }
}

# ==========================================
# TRAVA DE EXCLUSIVIDADE (PULSE OS)
# ==========================================
function Test-PulseOSExclusive {
    $RegPath = "HKLM:\SOFTWARE\PulseOS"
    $RegName = "SystemID"
    $ExpectedID = "PULSE-CORE"

    try {
        $val = (Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction Stop).$RegName
        if ($val -eq $ExpectedID) { return $true }
    } catch {}

    return $false
}

# ==========================================
# AUTO-UPDATE DO LAUNCHER
# ==========================================
function Update-LauncherIfNeeded {
    try {
        Write-Log "Verificando atualizacao do Launcher Pulse. Versao local: $Script:LauncherVersion"

        $remoteContent = Get-RemoteText -Url $LauncherScriptUrl
        if ([string]::IsNullOrWhiteSpace($remoteContent)) {
            Write-Log "Nao foi possivel verificar a versao remota do launcher. Continuando com a versao local."
            return $false
        }

        $remoteVersion = Get-LauncherVersionFromContent -Content $remoteContent
        if ([string]::IsNullOrWhiteSpace($remoteVersion)) {
            Write-Log "Versao remota nao encontrada em Launcher_Pulse.ps1. Continuando com a versao local."
            return $false
        }

        Write-Log "Versao remota do launcher: $remoteVersion"

        if ($remoteVersion.Trim().ToUpperInvariant() -eq $Script:LauncherVersion.Trim().ToUpperInvariant()) {
            Write-Log "Launcher Pulse ja esta atualizado."
            return $false
        }

        Write-Log "Nova versao encontrada. Atualizando Launcher Pulse de $Script:LauncherVersion para $remoteVersion."

        $utf8Bom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($TempLauncherPs1, $remoteContent, $utf8Bom)

        Download-Arquivo -Url $IconUrl -Destino $TempLauncherIcon | Out-Null

        if (-not (New-BuildScript -InputPs1 $TempLauncherPs1 -OutputPs1 $TempLauncherBuild)) {
            Show-Erro "Nao foi possivel preparar a nova versao do Painel Pulse."
            return $false
        }

        if (-not (Convert-PS1ToExe -InputPs1 $TempLauncherBuild -OutputExe $TempLauncherExe -IconFile $TempLauncherIcon -Title "Painel Pulse")) {
            Show-Erro "Nao foi possivel converter a nova versao do Painel Pulse para .exe."
            return $false
        }

        if (-not (Start-LauncherReplacement -NewExe $TempLauncherExe -TargetExe $InstalledLauncherExe)) {
            return $false
        }

        Show-Info "Uma nova versao do Painel Pulse foi encontrada.`nO launcher sera atualizado e aberto novamente."
        exit 0
    } catch {
        Write-Log "Falha inesperada no auto-update do launcher: $($_.Exception.Message)"
        return $false
    }
}


# ==========================================
# VERIFICADOR DE ESTADO DO PULSEOS
# ==========================================
function Invoke-PulseStateVerifier {
    try {
        Write-Log "Baixando verificar_pulseos.ps1..."

        if (Test-Path -LiteralPath $TempVerifierPs1) {
            Remove-Item -LiteralPath $TempVerifierPs1 -Force -ErrorAction SilentlyContinue
        }

        if (-not (Download-Arquivo -Url $VerifierScriptUrl -Destino $TempVerifierPs1) -or -not (Test-Path -LiteralPath $TempVerifierPs1)) {
            Write-Log "Falha ao baixar verificar_pulseos.ps1. O Painel sera aberto com o PulseState.json existente, se houver."
            return $false
        }

        $powershellExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$TempVerifierPs1`""

        Write-Log "Executando verificar_pulseos.ps1..."
        $process = Start-Process -FilePath $powershellExe -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru -ErrorAction Stop

        if (($null -ne $process.ExitCode) -and ($process.ExitCode -ne 0)) {
            Write-Log "verificar_pulseos.ps1 finalizou com codigo $($process.ExitCode)."
            return $false
        }

        Write-Log "verificar_pulseos.ps1 executado com sucesso."
        return $true
    }
    catch {
        Write-Log "Falha ao executar verificar_pulseos.ps1: $($_.Exception.Message)"
        return $false
    }
    finally {
        if (Test-Path -LiteralPath $TempVerifierPs1) {
            Remove-Item -LiteralPath $TempVerifierPs1 -Force -ErrorAction SilentlyContinue
        }
    }
}

# ==========================================
# INICIO DA EXECUCAO
# ==========================================
Initialize-Tls
Write-Log "Launcher Pulse iniciado. Versao: $Script:LauncherVersion"

if (-not (Test-PulseOSExclusive)) {
    Show-Erro "Ferramenta nao autorizada. Este utilitario e exclusivo do PulseOS."
    exit 1
}

if (-not (Test-Internet)) {
    Show-Erro "Sem conexao com a internet.`nVerifique sua conexao e tente novamente."
    exit 1
}

Update-LauncherIfNeeded | Out-Null

# ==========================================
# CRIA ESTRUTURA DE PASTAS EM %TEMP%
# ==========================================
foreach ($dir in @($Base, $JsonDir, $CmdsDir)) {
    if (-not (Ensure-Directory -Path $dir)) {
        Show-Erro "Falha ao criar a pasta:`n$dir"
        exit 1
    }
}

# ==========================================
# BAIXA O PAINEL E O ICONE
# ==========================================
if (-not (Download-Arquivo -Url $PanelScriptUrl -Destino $TempPanelPs1)) {
    Show-Erro "Falha ao baixar o Painel_Pulse.ps1.`nVerifique sua conexao e tente novamente."
    exit 1
}

if (-not (Download-Arquivo -Url $IconUrl -Destino $TempPanelIcon)) {
    Show-Erro "Falha ao baixar o icone do Painel Pulse.`nVerifique sua conexao e tente novamente."
    exit 1
}

# ==========================================
# CONVERTE O PAINEL .PS1 PARA .EXE
# ==========================================
if (-not (New-BuildScript -InputPs1 $TempPanelPs1 -OutputPs1 $TempPanelBuildPs1)) {
    Show-Erro "Falha ao preparar o Painel Pulse para conversao."
    exit 1
}

if (-not (Convert-PS1ToExe -InputPs1 $TempPanelBuildPs1 -OutputExe $EXEPath -IconFile $TempPanelIcon -Title "Painel Pulse")) {
    Show-Erro "Falha ao converter o Painel Pulse para .exe."
    exit 1
}

# ==========================================
# REMOVE ARQUIVOS TEMPORARIOS DE CONVERSAO
# ==========================================
foreach ($tmp in @($TempPanelPs1, $TempPanelBuildPs1, $TempPanelIcon, $TempVerifierPs1, $TempLauncherPs1, $TempLauncherBuild, $TempLauncherIcon)) {
    if (Test-Path -LiteralPath $tmp) {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

# ==========================================
# BAIXA OS ARQUIVOS JSON
# ==========================================
foreach ($json in $JsonFiles) {
    $url = "$RepoBase/json/$json"
    $destino = Join-Path $JsonDir $json

    if (-not (Download-Arquivo -Url $url -Destino $destino) -or -not (Test-Path -LiteralPath $destino)) {
        if (Test-Path -LiteralPath $Base) {
            Remove-Item -Path $Base -Recurse -Force -ErrorAction SilentlyContinue
        }
        Show-Erro "Falha ao baixar o arquivo '$json'.`nVerifique sua conexao e tente novamente."
        exit 1
    }
}

# ==========================================
# ATUALIZA O PULSESTATE ANTES DE ABRIR O PAINEL
# ==========================================
Invoke-PulseStateVerifier | Out-Null

# ==========================================
# EXECUTA O PAINEL
# ==========================================
try {
    Start-Process -FilePath $EXEPath | Out-Null
    Write-Log "Painel Pulse executado: $EXEPath"
} catch {
    Show-Erro "Falha ao executar o Painel Pulse.`n$($_.Exception.Message)"
    exit 1
}
