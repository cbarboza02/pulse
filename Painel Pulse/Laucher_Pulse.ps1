#Requires -Version 5.1
$RepoBase = "https://raw.githubusercontent.com/cbarboza02/pulse/main/Painel%20Pulse"
$Base     = Join-Path $env:TEMP "Painel Pulse"
$JsonDir  = Join-Path $Base "json"
$CmdsDir  = Join-Path $Base "comandos"
$PS1Path  = Join-Path $Base "Painel_Pulse.ps1"
$EXEPath  = Join-Path $Base "Painel Pulse.exe"
$IconPath  = Join-Path $Base "pulseicon.ico"
$TempPs1     = Join-Path $env:TEMP "temp_painel_pulse.ps1"
$TempIcon    = Join-Path $env:TEMP "temp_pulseicon.ico"
$JsonFiles = @(
    "pulse_geral.json",
    "pulse_hardware.json",
    "pulse_internet.json",
    "pulse_limpeza.json",
    "pulse_pulsemode.json",
    "pulse_restaurar.json",
    "pulse_reparar.json"
)

# FUNÇÃO DE MENSAGEM DE ERRO
# ==========================================
function Show-Erro {
    param([string]$Mensagem)
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        $Mensagem,
        "Painel Pulse",
        'OK',
        'Error'
    ) | Out-Null
}

# VERIFICA CONEXÃO COM A INTERNET
# ==========================================
try {
    $req = [System.Net.WebRequest]::Create("https://raw.githubusercontent.com")
    $req.Timeout = 5000
    $req.GetResponse() | Out-Null
} catch {
    Show-Erro "Sem conexão com a internet.`nVerifique sua conexão e tente novamente."
    exit 1
}

# CRIA ESTRUTURA DE PASTAS EM %TEMP%
# ==========================================
foreach ($dir in @($Base, $JsonDir, $CmdsDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# FUNÇÃO DE DOWNLOAD
# ==========================================
function Download-Arquivo {
    param([string]$Url, [string]$Destino)
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destino -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# BAIXA O Painel_Pulse.ps1 E O pulseicon.ico
# ==========================================
$ok = Download-Arquivo -Url "$RepoBase/Painel_Pulse.ps1" -Destino $TempPs1
$content = Get-Content -Path $TempPs1 -Raw -Encoding UTF8
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($TempPs1, $content, $utf8Bom)

$ok = Download-Arquivo -Url "$RepoBase/pulseicon.ico" -Destino $TempIcon

# CONVERTE O .PS1 PARA .EXE
# ==========================================
$content = Get-Content $TempPs1 -Raw -Encoding UTF8
$content = $content -replace '^#Requires.*\r?\n', ''
$tempPath = Join-Path $env:TEMP "build_painel_pulse.ps1"
[System.IO.File]::WriteAllText($tempPath, $content, [System.Text.UTF8Encoding]::new($true))

Invoke-PS2EXE $TempPs1 $EXEPath -noConsole -title "Painel Pulse" -company "PulseOS" -iconFile $TempIcon *>&1 | Out-Null

Remove-Item $tempPath -Force -ErrorAction SilentlyContinue

# REMOVE OS ARQUIVOS TEMPORÁRIOS
# ==========================================
Remove-Item $TempPs1 -Force -ErrorAction SilentlyContinue
    if (Test-Path $TempIcon) { 
        Remove-Item $TempIcon -Force -ErrorAction SilentlyContinue 
    }

# BAIXA OS ARQUIVOS JSON
# ==========================================
foreach ($json in $JsonFiles) {
    $url     = "$RepoBase/json/$json"
    $destino = Join-Path $JsonDir $json
    $ok      = Download-Arquivo -Url $url -Destino $destino

    if (-not $ok -or -not (Test-Path $destino)) {
        if (Test-Path $Base) { Remove-Item -Path $Base -Recurse -Force -ErrorAction SilentlyContinue }
        Show-Erro "Falha ao baixar o arquivo '$json'.`nVerifique sua conexão e tente novamente."
        exit 1
    }
}

# EXECUTA O PAINEL COMO ADMINISTRADOR
# ==========================================
Start-Process -FilePath $EXEPath
