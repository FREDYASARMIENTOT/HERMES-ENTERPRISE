<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : UseCaseOrchestrator.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Orquestador de Use Cases — entry point que auto-registra y ejecuta use cases.
    Ciclo: Initialize → ResolveUseCase → GetEngine → GetProvider → Execute → Return
====================================================================================================
#>

Set-StrictMode -Version Latest

# ── Global imports (outside function scope so definitions are global) ─────
$basePath = Split-Path -Parent $PSScriptRoot

# Engine contracts and resolver
. (Join-Path $basePath "Engine\EngineResolver.ps1")

# Engine implementations (7 core engines)
. (Join-Path $basePath "Engine\BootstrapEngine.ps1")
. (Join-Path $basePath "Engine\DiscoveryEngine.ps1")
. (Join-Path $basePath "Engine\ConfigEngine.ps1")
. (Join-Path $basePath "Engine\DependencyEngine.ps1")
. (Join-Path $basePath "Engine\RuntimeEngine.ps1")
. (Join-Path $basePath "Engine\ProviderEngine.ps1")
. (Join-Path $basePath "Engine\KernelEngine.ps1")

# Provider Infrastructure
. (Join-Path $basePath "Providers\ProviderBase.ps1")
. (Join-Path $basePath "Providers\ProviderExecutionContext.ps1")
. (Join-Path $basePath "Providers\ProviderFactory.ps1")
. (Join-Path $basePath "Providers\ProviderRegistry.ps1")
. (Join-Path $basePath "Providers\ProviderResolver.ps1")

# Provider implementations (7 core providers)
. (Join-Path $basePath "Providers\CapabilityProvider.ps1")
. (Join-Path $basePath "Providers\ConfigurationProvider.ps1")
. (Join-Path $basePath "Providers\DependencyProvider.ps1")
. (Join-Path $basePath "Providers\FileSystemProvider.ps1")
. (Join-Path $basePath "Providers\GitHubProvider.ps1")
. (Join-Path $basePath "Providers\RuntimeProvider.ps1")
. (Join-Path $basePath "Providers\WorkspaceProvider.ps1")

# Capability / UseCase infrastructure
. (Join-Path $basePath "Capabilities\UseCaseLibrary.ps1")
. (Join-Path $basePath "Capabilities\UseCaseRegistry.ps1")
. (Join-Path $basePath "Capabilities\UseCaseContext.ps1")
. (Join-Path $basePath "Capabilities\CapabilityRegistrar.ps1")
. (Join-Path $basePath "Capabilities\CapabilityRegistry.ps1")

function Initialize-UseCaseOrchestrator {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    Write-Verbose "[UseCaseOrchestrator] Initializing..."

    # ── Step 1: Populate Engine Registry ──────────────────────────────────────
    $engines = @(
        (New-BootstrapEngine -Id "engine-bootstrap" -Name "BootstrapEngine"),
        (New-DiscoveryEngine -Id "engine-discovery" -Name "DiscoveryEngine"),
        (New-ConfigEngine -Id "engine-config" -Name "ConfigEngine"),
        (New-DependencyEngine -Id "engine-dependency" -Name "DependencyEngine"),
        (New-RuntimeEngine -Id "engine-runtime" -Name "RuntimeEngine"),
        (New-ProviderEngine -Id "engine-provider" -Name "ProviderEngine"),
        (New-KernelEngine -Id "engine-kernel" -Name "KernelEngine")
    )

    foreach ($e in $engines) {
        Register-Engine -Engine $e
    }

    # ── Step 5: Populate Capability Registry ─────────────────────────────────
    Initialize-CapabilityRegistrar | Out-Null

    # ── Step 6: Populate UseCase Registry ────────────────────────────────────
    Initialize-UseCaseRegistry | Out-Null

    # ── Step 7: Return status ─────────────────────────────────────────────────
    $capMappings = $null
    $useCases    = $null
    if (Get-Command Get-AllCapabilityMappings -ErrorAction SilentlyContinue) {
        $capMappings = (Get-AllCapabilityMappings).Count
    }
    if (Get-Command Get-AllUseCases -ErrorAction SilentlyContinue) {
        $useCases = (Get-AllUseCases).Count
    }

    Write-Verbose "[UseCaseOrchestrator] Initialization complete"

    return @{
        EnginesRegistered     = $engines.Count
        CapabilitiesMapped    = $capMappings
        UseCasesRegistered    = $useCases
        Status                = 'Initialized'
    }
}

function Invoke-UseCaseOrchestrator {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UseCaseIdOrName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$InputParameters
    )

    # 1. Resolve the use case
    $useCase = Resolve-UseCase -UseCaseIdOrName $UseCaseIdOrName
    if (-not $useCase) {
        return @{
            Success = $false
            Error   = "UseCase '$UseCaseIdOrName' not found in registry"
            Step    = 'ResolveUseCase'
        }
    }

    # 2. Build UseCaseContext
    $context = [pscustomobject]@{
        UseCase         = $useCase
        InputParameters = $InputParameters
        Container       = $null
    }

    # 3. Resolve Engine
    $engine = Resolve-Engine -EngineIdOrName $useCase.EngineType
    if (-not $engine) {
        return @{
            Success = $false
            Error   = "Engine '$($useCase.EngineType)' not found for use case '$UseCaseIdOrName'"
            Step    = 'ResolveEngine'
        }
    }

    # 4. Execute engine
    $engineResult = Invoke-UseCaseEngine -Engine $engine -UseCaseContext $context

    # 5. Ensure Success property is present for consistency
    if ($engineResult -is [hashtable] -and -not $engineResult.ContainsKey('Success')) {
        $engineResult['Success'] = ($engineResult['Status'] -eq 'Completed')
    }

    return $engineResult
}

function Invoke-UseCaseEngine {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Engine,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext
    )

    switch ($Engine.EngineType) {
        'Bootstrap'   { return Invoke-BootstrapEngine -Engine $Engine -UseCaseContext $UseCaseContext }
        'Discovery'   { return Invoke-DiscoveryEngine -Engine $Engine -UseCaseContext $UseCaseContext }
        'Config'      { return Invoke-ConfigEngine -Engine $Engine -UseCaseContext $UseCaseContext }
        'Dependency'  { return Invoke-DependencyEngine -Engine $Engine -UseCaseContext $UseCaseContext }
        'Runtime'     { return Invoke-RuntimeEngine -Engine $Engine -UseCaseContext $UseCaseContext }
        'Provider'    { return Invoke-ProviderEngine -Engine $Engine -UseCaseContext $UseCaseContext }
        'Kernel'      { return Invoke-KernelEngine -Engine $Engine -UseCaseContext $UseCaseContext }
        default {
            return @{
                Success = $false
                Error   = "Unknown engine type: $($Engine.EngineType)"
                Step    = 'InvokeEngine'
            }
        }
    }
}