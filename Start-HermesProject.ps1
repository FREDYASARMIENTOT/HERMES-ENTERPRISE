<#
Objective: Shim entrypoint for Hermes Enterprise. Delegates to motor\bootstrap\Start-HermesProject.ps1
Parameters: NombreProyecto, ProvisionTarget, GitHubUser, AbrirVSCode, EjecutarPruebas, Modo, WorkspaceRoot, Sandbox
Behavior: resolves WorkspaceRoot via HermesPathResolver and invokes bootstrap in-process preserving PSBoundParameters
#>
param(
    [Parameter(Mandatory=$false)][string]$NombreProyecto = 'ProyectoTest025',
    [ValidateSet('Local','GitHub')][string]$ProvisionTarget = 'Local',
    [string]$GitHubUser = '',
    [switch]$AbrirVSCode,
    [switch]$EjecutarPruebas,
    [ValidateSet('Desarrollo','Produccion')][string]$Modo = 'Desarrollo',
    [string]$WorkspaceRoot = $null,
    [switch]$Sandbox
)

# Determine script paths
$scriptPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) -ChildPath 'motor\bootstrap\Start-HermesProject.ps1'
$configPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) -ChildPath 'Hermes.config.json'
$resolverModule = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) -ChildPath 'tools\HermesPathResolver.psm1'

if (Test-Path $resolverModule) {
    try {
        # Try function-based API first (works in all PowerShell execution contexts)
        Import-Module $resolverModule -Force -ErrorAction Stop
        if (Get-Command Get-HermesPaths -ErrorAction SilentlyContinue) {
            $paths = Get-HermesPaths -ConfigPath $configPath
            $WorkspaceRoot = $paths.WorkspaceRoot
            $SandboxRoot = $paths.SandboxRoot
        } else {
            # Fallback to class-based API
            $resolver = [HermesPathResolver]::new($configPath)
            $WorkspaceRoot = $resolver.GetWorkspaceRoot()
            $SandboxRoot = $resolver.GetSandboxRoot()
        }
    } catch {
        # Ultimate fallback: direct JSON parsing
        Write-Warning "Failed to load HermesPathResolver: $($_.Exception.Message). Using direct JSON parsing."
        $json = Get-Content $configPath -Raw | ConvertFrom-Json
        $WorkspaceRoot = $json.WorkspaceRoot
        $SandboxRoot = $json.SandboxRoot
    }
} else {
    Write-Error "HermesPathResolver module not found at $resolverModule"
    throw
}

if ($Sandbox.IsPresent) {
    $WorkspaceRoot = $SandboxRoot
}

# Ensure NombreProyecto is always present (the default needs to be passed explicitly)
if (-not $PSBoundParameters.ContainsKey('NombreProyecto')) {
    $PSBoundParameters['NombreProyecto'] = $NombreProyecto
}
$PSBoundParameters['WorkspaceRoot'] = $WorkspaceRoot
$PSBoundParameters['Sandbox'] = $Sandbox.IsPresent

# Expose parameters for callers
$exposed = @{ NombreProyecto=$NombreProyecto; ProvisionTarget=$ProvisionTarget; GitHubUser=$GitHubUser; AbrirVSCode=$AbrirVSCode.IsPresent; EjecutarPruebas=$EjecutarPruebas.IsPresent; Modo=$Modo; WorkspaceRoot=$WorkspaceRoot; Sandbox=$Sandbox.IsPresent }
Set-Variable -Name "StartHermes_Params" -Value $exposed -Scope Global

# Invoke bootstrap in-process
if (Test-Path $scriptPath) {
    try {
        & $scriptPath @PSBoundParameters
    } catch {
        Write-Error "Bootstrap invocation failed: $($_.Exception.Message)"
        throw
    }
} else {
    Write-Host "[SHIM] bootstrap script not found at $scriptPath"
}
