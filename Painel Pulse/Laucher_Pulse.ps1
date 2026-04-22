#Requires -Version 5.1
$RepoBase = "https://raw.githubusercontent.com/cbarboza02/pulse/main/Painel%20Pulse"
$Base     = Join-Path $env:TEMP "Painel Pulse"
$JsonDir  = Join-Path $Base "json"
$CmdsDir  = Join-Path $Base "comandos"
$PS1Path  = Join-Path $Base "Painel_Pulse.ps1"
$IconPath  = Join-Path $Base "pulseicon.ico"
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

# BAIXA O ARQUIVO PRINCIPAL (.PS1) E O ÍCONE
# ==========================================
$ok = Download-Arquivo -Url "$RepoBase/Painel_Pulse.ps1" -Destino $PS1Path
if (-not $ok -or -not (Test-Path $PS1Path)) {
    if (Test-Path $Base) { Remove-Item -Path $Base -Recurse -Force -ErrorAction SilentlyContinue }
    Show-Erro "Falha ao baixar o arquivo principal.`nVerifique sua conexão e tente novamente."
    exit 1
}
$content = Get-Content -Path $PS1Path -Raw -Encoding UTF8
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($PS1Path, $content, $utf8Bom)

$ok = Download-Arquivo -Url "$RepoBase/pulseicon.ico" -Destino $IconPath
if (-not $ok -or -not (Test-Path $IconPath)) {
    if (Test-Path $Base) { Remove-Item -Path $Base -Recurse -Force -ErrorAction SilentlyContinue }
    Show-Erro "Falha ao baixar o ícone.`nVerifique sua conexão e tente novamente."
    exit 1
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
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PS1Path`"" -Verb RunAs
