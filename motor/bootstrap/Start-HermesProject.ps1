param(
    [Parameter(Mandatory=$true)][string]$NombreProyecto,
    [ValidateSet('Local','GitHub')][string]$ProvisionTarget = 'Local',
    [string]$GitHubUser = '',
    [switch]$AbrirVSCode,
    [switch]$EjecutarPruebas,
    [ValidateSet('Desarrollo','Produccion')][string]$Modo = 'Desarrollo',
    [string]$WorkspaceRoot = $null,
    [switch]$Sandbox
)

# Kernel Entrypoint - consolidated
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Ensure .hermes exists (in project root, 2 levels up from motor/bootstrap)
$hermesDir = Join-Path -Path $repoRoot -ChildPath '..\..\.hermes'
if (-not (Test-Path $hermesDir)) { New-Item -ItemType Directory -Path $hermesDir | Out-Null }
$bootstrapPath = Join-Path -Path $hermesDir -ChildPath 'BOOTSTRAP_CONTEXT.json'
# Cargar contexto de bootstrap si existe
if (Test-Path $bootstrapPath) {
    $json = Get-Content $bootstrapPath -Raw | ConvertFrom-Json
    Write-Host "[Start-HermesProject] Contexto cargado: $($json.sprint) - $($json.objetivo)"
    if ($json.ultimo_paso) {
        Write-Host "[Start-HermesProject] Reanudando desde: $($json.ultimo_paso)"
    }
} else {
    $initial = @{ sprint='A.27'; objetivo='Provision full'; estado='IN_PROGRESS'; ultimo_paso=$null; last_updated=(Get-Date).ToString('o') }
    $initial | ConvertTo-Json | Out-File -FilePath $bootstrapPath -Encoding utf8
    Write-Host "[Start-HermesProject] Contexto inicial creado"
}

    # Persist context of invocation
    $context = @{ NombreProyecto=$NombreProyecto; ProvisionTarget=$ProvisionTarget; GitHubUser=$GitHubUser; AbrirVSCode=$AbrirVSCode.IsPresent; EjecutarPruebas=$EjecutarPruebas.IsPresent; Modo=$Modo; WorkspaceRoot=$WorkspaceRoot; Sandbox=$Sandbox.IsPresent }
$context | ConvertTo-Json | Out-File -FilePath (Join-Path $hermesDir 'LAST_INVOCATION.json') -Encoding utf8

# Call Engine
$enginePath = Join-Path -Path $repoRoot -ChildPath '..\..\tools\EnterprisePipeline.ps1'
if (Test-Path $enginePath) { & $enginePath -Contexto $context } else { Write-Host "[Start-HermesProject] Engine not found at $enginePath" }