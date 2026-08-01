<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : UseCaseLibrary.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Librería concreta de implementaciones de Use Cases del Core.
    Cada Use Case implementa el pipeline completo:
    Input → Validation → Capability → Engine Resolver → Engine → Provider Resolver → Provider → Runtime → Result
====================================================================================================
#>

Set-StrictMode -Version Latest

#---------------------------------------------------------------------------
# USE CASE 1: Bootstrap Workspace
#---------------------------------------------------------------------------
<#
.SYNOPSIS
    Ejecuta el Use Case "Bootstrap Workspace".
.DESCRIPTION
    Inicializa un workspace de HERMES-ENTERPRISE desde cero.
    Pipeline: Input → Validation → capability.workspace.bootstrap → Engine[BootstrapEngine] → Provider[GitHubProvider] → Result
#>
function Invoke-UseCase_BootstrapWorkspace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Container
    )

    $result = [pscustomobject][ordered]@{
        UseCaseName    = 'BootstrapWorkspace'
        Status         = 'Pending'
        ExecutionId    = [guid]::NewGuid().ToString()
        CorrelationId  = $UseCaseContext.Metadata.CorrelationId
        Capability     = 'capability.workspace.bootstrap'
        Engine         = ''
        Provider       = ''
        Start          = [datetime]::UtcNow.ToString('o')
        End            = $null
        Duration       = 0
        Output         = $null
        Errors         = [System.Collections.ArrayList]@()
    }

    try {
        # Validation
        if (-not $UseCaseContext.InputParameters.ContainsKey('WorkspaceName')) {
            throw 'Input parameter "WorkspaceName" is required for BootstrapWorkspace'
        }
        if (-not $UseCaseContext.InputParameters.ContainsKey('RepositoryRoot')) {
            throw 'Input parameter "RepositoryRoot" is required for BootstrapWorkspace'
        }

        # Resolver Engine
        $engineResolver = Get-EngineResolverFromContainer -Container $Container -Capability 'capability.workspace.bootstrap'
        $result.Engine = 'BootstrapEngine'
        $engine = & $engineResolver -UseCaseContext $UseCaseContext -Container $Container

        # Resolver Provider
        $providerResolver = Get-ProviderResolverFromContainer -Container $Container -Capability 'capability.workspace.bootstrap'
        $result.Provider = 'GitHubProvider'
        $providerOutput = & $providerResolver -UseCaseContext $UseCaseContext -Container $Container

        $result.Output = @{
            WorkspacePath  = Join-Path $UseCaseContext.InputParameters.RepositoryRoot $UseCaseContext.InputParameters.WorkspaceName
            BootstrapState = 'Created'
            ProviderResult = $providerOutput
        }
        $UseCaseContext.OutputResults = $result.Output
        $result.Status = 'Completed'
    }
    catch {
        $result.Status = 'Failed'
        $null = $result.Errors.Add($_.Exception.Message)
    }
    finally {
        $endTime = [datetime]::UtcNow
        $result.End = $endTime.ToString('o')
        $result.Duration = [math]::Round(($endTime - [datetime]$result.Start).TotalMilliseconds, 2)
    }

    $UseCaseContext.Status = $result.Status
    $null = $UseCaseContext.PipelineStack.Add("UseCase[BootstrapWorkspace]: $($result.Status)")
    return $result
}

#---------------------------------------------------------------------------
# USE CASE 2: Workspace Discovery
#---------------------------------------------------------------------------
<#
.SYNOPSIS
    Ejecuta el Use Case "Workspace Discovery".
.DESCRIPTION
    Descubre workspaces existentes en el sistema de archivos.
    Pipeline: Input → Validation → capability.workspace.discovery → Engine[DiscoveryEngine] → Provider[FileSystemProvider] → Result
#>
function Invoke-UseCase_WorkspaceDiscovery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Container
    )

    $result = [pscustomobject][ordered]@{
        UseCaseName    = 'WorkspaceDiscovery'
        Status         = 'Pending'
        ExecutionId    = [guid]::NewGuid().ToString()
        CorrelationId  = $UseCaseContext.Metadata.CorrelationId
        Capability     = 'capability.workspace.discovery'
        Engine         = ''
        Provider       = ''
        Start          = [datetime]::UtcNow.ToString('o')
        End            = $null
        Duration       = 0
        Output         = $null
        Errors         = [System.Collections.ArrayList]@()
    }

    try {
        if (-not $UseCaseContext.InputParameters.ContainsKey('SearchRoot')) {
            throw 'Input parameter "SearchRoot" is required for WorkspaceDiscovery'
        }

        $engineResolver = Get-EngineResolverFromContainer -Container $Container -Capability 'capability.workspace.discovery'
        $result.Engine = 'DiscoveryEngine'
        $engine = & $engineResolver -UseCaseContext $UseCaseContext -Container $Container

        $providerResolver = Get-ProviderResolverFromContainer -Container $Container -Capability 'capability.workspace.discovery'
        $result.Provider = 'FileSystemProvider'
        $providerOutput = & $providerResolver -UseCaseContext $UseCaseContext -Container $Container

        $result.Output = @{
            SearchRoot     = $UseCaseContext.InputParameters.SearchRoot
            Workspaces     = $providerOutput.Workspaces
            Count          = $providerOutput.Count
        }
        $UseCaseContext.OutputResults = $result.Output
        $result.Status = 'Completed'
    }
    catch {
        $result.Status = 'Failed'
        $null = $result.Errors.Add($_.Exception.Message)
    }
    finally {
        $endTime = [datetime]::UtcNow
        $result.End = $endTime.ToString('o')
        $result.Duration = [math]::Round(($endTime - [datetime]$result.Start).TotalMilliseconds, 2)
    }

    $UseCaseContext.Status = $result.Status
    $null = $UseCaseContext.PipelineStack.Add("UseCase[WorkspaceDiscovery]: $($result.Status)")
    return $result
}

#---------------------------------------------------------------------------
# USE CASE 3: Configuration Loading
#---------------------------------------------------------------------------
<#
.SYNOPSIS
    Ejecuta el Use Case "Configuration Loading".
.DESCRIPTION
    Carga la configuración del sistema desde archivos de configuración.
    Pipeline: Input → Validation → capability.configuration.load → Engine[ConfigEngine] → Provider[ConfigurationProvider] → Result
#>
function Invoke-UseCase_ConfigurationLoading {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Container
    )

    $result = [pscustomobject][ordered]@{
        UseCaseName    = 'ConfigurationLoading'
        Status         = 'Pending'
        ExecutionId    = [guid]::NewGuid().ToString()
        CorrelationId  = $UseCaseContext.Metadata.CorrelationId
        Capability     = 'capability.configuration.load'
        Engine         = ''
        Provider       = ''
        Start          = [datetime]::UtcNow.ToString('o')
        End            = $null
        Duration       = 0
        Output         = $null
        Errors         = [System.Collections.ArrayList]@()
    }

    try {
        if (-not $UseCaseContext.InputParameters.ContainsKey('ConfigPath')) {
            throw 'Input parameter "ConfigPath" is required for ConfigurationLoading'
        }

        $engineResolver = Get-EngineResolverFromContainer -Container $Container -Capability 'capability.configuration.load'
        $result.Engine = 'ConfigEngine'
        $engine = & $engineResolver -UseCaseContext $UseCaseContext -Container $Container

        $providerResolver = Get-ProviderResolverFromContainer -Container $Container -Capability 'capability.configuration.load'
        $result.Provider = 'ConfigurationProvider'
        $providerOutput = & $providerResolver -UseCaseContext $UseCaseContext -Container $Container

        $result.Output = @{
            ConfigPath    = $UseCaseContext.InputParameters.ConfigPath
            Configuration = $providerOutput.Configuration
            Sections      = $providerOutput.Sections
        }
        $UseCaseContext.OutputResults = $result.Output
        $result.Status = 'Completed'
    }
    catch {
        $result.Status = 'Failed'
        $null = $result.Errors.Add($_.Exception.Message)
    }
    finally {
        $endTime = [datetime]::UtcNow
        $result.End = $endTime.ToString('o')
        $result.Duration = [math]::Round(($endTime - [datetime]$result.Start).TotalMilliseconds, 2)
    }

    $UseCaseContext.Status = $result.Status
    $null = $UseCaseContext.PipelineStack.Add("UseCase[ConfigurationLoading]: $($result.Status)")
    return $result
}

#---------------------------------------------------------------------------
# USE CASE 4: Capability Discovery
#---------------------------------------------------------------------------
<#
.SYNOPSIS
    Ejecuta el Use Case "Capability Discovery".
.DESCRIPTION
    Descubre capacidades disponibles en el sistema.
    Pipeline: Input → Validation → capability.capability.discovery → Engine[DiscoveryEngine] → Provider[CapabilityProvider] → Result
#>
function Invoke-UseCase_CapabilityDiscovery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Container
    )

    $result = [pscustomobject][ordered]@{
        UseCaseName    = 'CapabilityDiscovery'
        Status         = 'Pending'
        ExecutionId    = [guid]::NewGuid().ToString()
        CorrelationId  = $UseCaseContext.Metadata.CorrelationId
        Capability     = 'capability.capability.discovery'
        Engine         = ''
        Provider       = ''
        Start          = [datetime]::UtcNow.ToString('o')
        End            = $null
        Duration       = 0
        Output         = $null
        Errors         = [System.Collections.ArrayList]@()
    }

    try {
        $engineResolver = Get-EngineResolverFromContainer -Container $Container -Capability 'capability.capability.discovery'
        $result.Engine = 'DiscoveryEngine'
        $engine = & $engineResolver -UseCaseContext $UseCaseContext -Container $Container

        $providerResolver = Get-ProviderResolverFromContainer -Container $Container -Capability 'capability.capability.discovery'
        $result.Provider = 'CapabilityProvider'
        $providerOutput = & $providerResolver -UseCaseContext $UseCaseContext -Container $Container

        $result.Output = @{
            Capabilities       = $providerOutput.Capabilities
            Count              = $providerOutput.Count
        }
        $UseCaseContext.OutputResults = $result.Output
        $result.Status = 'Completed'
    }
    catch {
        $result.Status = 'Failed'
        $null = $result.Errors.Add($_.Exception.Message)
    }
    finally {
        $endTime = [datetime]::UtcNow
        $result.End = $endTime.ToString('o')
        $result.Duration = [math]::Round(($endTime - [datetime]$result.Start).TotalMilliseconds, 2)
    }

    $UseCaseContext.Status = $result.Status
    $null = $UseCaseContext.PipelineStack.Add("UseCase[CapabilityDiscovery]: $($result.Status)")
    return $result
}

#---------------------------------------------------------------------------
# USE CASE 5: Dependency Resolution
#---------------------------------------------------------------------------
<#
.SYNOPSIS
    Ejecuta el Use Case "Dependency Resolution".
.DESCRIPTION
    Resuelve dependencias entre módulos del sistema.
    Pipeline: Input → Validation → capability.dependency.resolve → Engine[DependencyEngine] → Provider[DependencyProvider] → Result
#>
function Invoke-UseCase_DependencyResolution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Container
    )

    $result = [pscustomobject][ordered]@{
        UseCaseName    = 'DependencyResolution'
        Status         = 'Pending'
        ExecutionId    = [guid]::NewGuid().ToString()
        CorrelationId  = $UseCaseContext.Metadata.CorrelationId
        Capability     = 'capability.dependency.resolve'
        Engine         = ''
        Provider       = ''
        Start          = [datetime]::UtcNow.ToString('o')
        End            = $null
        Duration       = 0
        Output         = $null
        Errors         = [System.Collections.ArrayList]@()
    }

    try {
        if (-not $UseCaseContext.InputParameters.ContainsKey('ModuleName')) {
            throw 'Input parameter "ModuleName" is required for DependencyResolution'
        }

        $engineResolver = Get-EngineResolverFromContainer -Container $Container -Capability 'capability.dependency.resolve'
        $result.Engine = 'DependencyEngine'
        $engine = & $engineResolver -UseCaseContext $UseCaseContext -Container $Container

        $providerResolver = Get-ProviderResolverFromContainer -Container $Container -Capability 'capability.dependency.resolve'
        $result.Provider = 'DependencyProvider'
        $providerOutput = & $providerResolver -UseCaseContext $UseCaseContext -Container $Container

        $result.Output = @{
            ModuleName        = $UseCaseContext.InputParameters.ModuleName
            Dependencies      = $providerOutput.Dependencies
            ResolvedCount     = $providerOutput.ResolvedCount
        }
        $UseCaseContext.OutputResults = $result.Output
        $result.Status = 'Completed'
    }
    catch {
        $result.Status = 'Failed'
        $null = $result.Errors.Add($_.Exception.Message)
    }
    finally {
        $endTime = [datetime]::UtcNow
        $result.End = $endTime.ToString('o')
        $result.Duration = [math]::Round(($endTime - [datetime]$result.Start).TotalMilliseconds, 2)
    }

    $UseCaseContext.Status = $result.Status
    $null = $UseCaseContext.PipelineStack.Add("UseCase[DependencyResolution]: $($result.Status)")
    return $result
}

#---------------------------------------------------------------------------
# USE CASE 6: Runtime Startup
#---------------------------------------------------------------------------
<#
.SYNOPSIS
    Ejecuta el Use Case "Runtime Startup".
.DESCRIPTION
    Inicia el Runtime del Kernel Enterprise.
    Pipeline: Input → Validation → capability.runtime.startup → Engine[RuntimeEngine] → Provider[RuntimeProvider] → Result
#>
function Invoke-UseCase_RuntimeStartup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Container
    )

    $result = [pscustomobject][ordered]@{
        UseCaseName    = 'RuntimeStartup'
        Status         = 'Pending'
        ExecutionId    = [guid]::NewGuid().ToString()
        CorrelationId  = $UseCaseContext.Metadata.CorrelationId
        Capability     = 'capability.runtime.startup'
        Engine         = ''
        Provider       = ''
        Start          = [datetime]::UtcNow.ToString('o')
        End            = $null
        Duration       = 0
        Output         = $null
        Errors         = [System.Collections.ArrayList]@()
    }

    try {
        $engineResolver = Get-EngineResolverFromContainer -Container $Container -Capability 'capability.runtime.startup'
        $result.Engine = 'RuntimeEngine'
        $engine = & $engineResolver -UseCaseContext $UseCaseContext -Container $Container

        $providerResolver = Get-ProviderResolverFromContainer -Container $Container -Capability 'capability.runtime.startup'
        $result.Provider = 'RuntimeProvider'
        $providerOutput = & $providerResolver -UseCaseContext $UseCaseContext -Container $Container

        $result.Output = @{
            RuntimeId     = $providerOutput.RuntimeId
            Status        = $providerOutput.Status
            StartedAt     = $providerOutput.StartedAt
        }
        $UseCaseContext.OutputResults = $result.Output
        $result.Status = 'Completed'
    }
    catch {
        $result.Status = 'Failed'
        $null = $result.Errors.Add($_.Exception.Message)
    }
    finally {
        $endTime = [datetime]::UtcNow
        $result.End = $endTime.ToString('o')
        $result.Duration = [math]::Round(($endTime - [datetime]$result.Start).TotalMilliseconds, 2)
    }

    $UseCaseContext.Status = $result.Status
    $null = $UseCaseContext.PipelineStack.Add("UseCase[RuntimeStartup]: $($result.Status)")
    return $result
}

#---------------------------------------------------------------------------
# USE CASE 7: Provider Resolution
#---------------------------------------------------------------------------
<#
.SYNOPSIS
    Ejecuta el Use Case "Provider Resolution".
.DESCRIPTION
    Resuelve un proveedor específico por tipo y nombre.
    Pipeline: Input → Validation → capability.provider.resolve → Engine[ProviderEngine] → Provider[ProviderResolver] → Result
#>
function Invoke-UseCase_ProviderResolution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Container
    )

    $result = [pscustomobject][ordered]@{
        UseCaseName    = 'ProviderResolution'
        Status         = 'Pending'
        ExecutionId    = [guid]::NewGuid().ToString()
        CorrelationId  = $UseCaseContext.Metadata.CorrelationId
        Capability     = 'capability.provider.resolve'
        Engine         = ''
        Provider       = ''
        Start          = [datetime]::UtcNow.ToString('o')
        End            = $null
        Duration       = 0
        Output         = $null
        Errors         = [System.Collections.ArrayList]@()
    }

    try {
        if (-not $UseCaseContext.InputParameters.ContainsKey('ProviderType')) {
            throw 'Input parameter "ProviderType" is required for ProviderResolution'
        }

        $engineResolver = Get-EngineResolverFromContainer -Container $Container -Capability 'capability.provider.resolve'
        $result.Engine = 'ProviderEngine'
        $engine = & $engineResolver -UseCaseContext $UseCaseContext -Container $Container

        $providerResolver = Get-ProviderResolverFromContainer -Container $Container -Capability 'capability.provider.resolve'
        $result.Provider = 'ProviderRegistryResolver'
        $providerOutput = & $providerResolver -UseCaseContext $UseCaseContext -Container $Container

        $result.Output = @{
            ProviderType  = $UseCaseContext.InputParameters.ProviderType
            Providers     = $providerOutput.Providers
            Count         = $providerOutput.Count
        }
        $UseCaseContext.OutputResults = $result.Output
        $result.Status = 'Completed'
    }
    catch {
        $result.Status = 'Failed'
        $null = $result.Errors.Add($_.Exception.Message)
    }
    finally {
        $endTime = [datetime]::UtcNow
        $result.End = $endTime.ToString('o')
        $result.Duration = [math]::Round(($endTime - [datetime]$result.Start).TotalMilliseconds, 2)
    }

    $UseCaseContext.Status = $result.Status
    $null = $UseCaseContext.PipelineStack.Add("UseCase[ProviderResolution]: $($result.Status)")
    return $result
}

#---------------------------------------------------------------------------
# USE CASE 8: Engine Resolution
#---------------------------------------------------------------------------
<#
.SYNOPSIS
    Ejecuta el Use Case "Engine Resolution".
.DESCRIPTION
    Resuelve un motor específico por nombre o capacidad.
    Pipeline: Input → Validation → capability.engine.resolve → Engine[EngineResolver] → Provider[EngineRegistryProvider] → Result
#>
function Invoke-UseCase_EngineResolution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Container
    )

    $result = [pscustomobject][ordered]@{
        UseCaseName    = 'EngineResolution'
        Status         = 'Pending'
        ExecutionId    = [guid]::NewGuid().ToString()
        CorrelationId  = $UseCaseContext.Metadata.CorrelationId
        Capability     = 'capability.engine.resolve'
        Engine         = ''
        Provider       = ''
        Start          = [datetime]::UtcNow.ToString('o')
        End            = $null
        Duration       = 0
        Output         = $null
        Errors         = [System.Collections.ArrayList]@()
    }

    try {
        if (-not $UseCaseContext.InputParameters.ContainsKey('EngineName') -and -not $UseCaseContext.InputParameters.ContainsKey('Capability')) {
            throw 'Input parameter "EngineName" or "Capability" is required for EngineResolution'
        }

        $engineResolver = Get-EngineResolverFromContainer -Container $Container -Capability 'capability.engine.resolve'
        $result.Engine = 'EngineResolver'
        $engine = & $engineResolver -UseCaseContext $UseCaseContext -Container $Container

        $providerResolver = Get-ProviderResolverFromContainer -Container $Container -Capability 'capability.engine.resolve'
        $result.Provider = 'EngineRegistryProvider'
        $providerOutput = & $providerResolver -UseCaseContext $UseCaseContext -Container $Container

        $result.Output = @{
            SearchCriteria = if ($UseCaseContext.InputParameters.ContainsKey('EngineName')) { $UseCaseContext.InputParameters.EngineName } else { $UseCaseContext.InputParameters.Capability }
            Engines        = $providerOutput.Engines
            Count          = $providerOutput.Count
        }
        $UseCaseContext.OutputResults = $result.Output
        $result.Status = 'Completed'
    }
    catch {
        $result.Status = 'Failed'
        $null = $result.Errors.Add($_.Exception.Message)
    }
    finally {
        $endTime = [datetime]::UtcNow
        $result.End = $endTime.ToString('o')
        $result.Duration = [math]::Round(($endTime - [datetime]$result.Start).TotalMilliseconds, 2)
    }

    $UseCaseContext.Status = $result.Status
    $null = $UseCaseContext.PipelineStack.Add("UseCase[EngineResolution]: $($result.Status)")
    return $result
}

#---------------------------------------------------------------------------
# USE CASE 9: Kernel Startup
#---------------------------------------------------------------------------
<#
.SYNOPSIS
    Ejecuta el Use Case "Kernel Startup".
.DESCRIPTION
    Inicia el Kernel Enterprise completo incluyendo todos los subsistemas.
    Pipeline: Input → Validation → capability.kernel.startup → Engine[KernelEngine] → Provider[KernelProvider] → Result
#>
function Invoke-UseCase_KernelStartup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Container
    )

    $result = [pscustomobject][ordered]@{
        UseCaseName    = 'KernelStartup'
        Status         = 'Pending'
        ExecutionId    = [guid]::NewGuid().ToString()
        CorrelationId  = $UseCaseContext.Metadata.CorrelationId
        Capability     = 'capability.kernel.startup'
        Engine         = ''
        Provider       = ''
        Start          = [datetime]::UtcNow.ToString('o')
        End            = $null
        Duration       = 0
        Output         = $null
        Errors         = [System.Collections.ArrayList]@()
    }

    try {
        $engineResolver = Get-EngineResolverFromContainer -Container $Container -Capability 'capability.kernel.startup'
        $result.Engine = 'KernelEngine'
        $engine = & $engineResolver -UseCaseContext $UseCaseContext -Container $Container

        $providerResolver = Get-ProviderResolverFromContainer -Container $Container -Capability 'capability.kernel.startup'
        $result.Provider = 'KernelProvider'
        $providerOutput = & $providerResolver -UseCaseContext $UseCaseContext -Container $Container

        $result.Output = @{
            KernelId      = $providerOutput.KernelId
            Status        = $providerOutput.Status
            Subsystems    = $providerOutput.Subsystems
        }
        $UseCaseContext.OutputResults = $result.Output
        $result.Status = 'Completed'
    }
    catch {
        $result.Status = 'Failed'
        $null = $result.Errors.Add($_.Exception.Message)
    }
    finally {
        $endTime = [datetime]::UtcNow
        $result.End = $endTime.ToString('o')
        $result.Duration = [math]::Round(($endTime - [datetime]$result.Start).TotalMilliseconds, 2)
    }

    $UseCaseContext.Status = $result.Status
    $null = $UseCaseContext.PipelineStack.Add("UseCase[KernelStartup]: $($result.Status)")
    return $result
}

#---------------------------------------------------------------------------
# Helper: Gets an Engine Resolver ScriptBlock from Container
#---------------------------------------------------------------------------
function Get-EngineResolverFromContainer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Container,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Capability
    )

    $capabilityRegistry = Get-ServiceFromContainer -Container $Container -ServiceName 'CapabilityRegistry'
    if ($null -eq $capabilityRegistry) {
        throw "CapabilityRegistry not found in container"
    }

    $resolvers = Get-CapabilityEngineResolvers -CapabilityRegistry $capabilityRegistry -CapabilityName $Capability
    if ($null -eq $resolvers -or $resolvers.Count -eq 0) {
        throw "No engine resolvers registered for capability: $Capability"
    }

    return $resolvers[0]
}

#---------------------------------------------------------------------------
# Helper: Gets a Provider Resolver ScriptBlock from Container
#---------------------------------------------------------------------------
function Get-ProviderResolverFromContainer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Container,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Capability
    )

    $capabilityRegistry = Get-ServiceFromContainer -Container $Container -ServiceName 'CapabilityRegistry'
    if ($null -eq $capabilityRegistry) {
        throw "CapabilityRegistry not found in container"
    }

    $resolvers = Get-CapabilityProviderResolvers -CapabilityRegistry $capabilityRegistry -CapabilityName $Capability
    if ($null -eq $resolvers -or $resolvers.Count -eq 0) {
        throw "No provider resolvers registered for capability: $Capability"
    }

    return $resolvers[0]
}

#---------------------------------------------------------------------------
# Helper: Gets a service from the Dependency Container
#---------------------------------------------------------------------------
function Get-ServiceFromContainer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Container,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceName
    )

    if ($Container.PSObject.Properties.Name -contains 'Services' -and $Container.Services.ContainsKey($ServiceName)) {
        return $Container.Services[$ServiceName]
    }

    if ($Container.PSObject.Properties.Name -contains $ServiceName) {
        return $Container.$ServiceName
    }

    return $null
}

#---------------------------------------------------------------------------
# Use Case Factory Functions (for UseCaseRegistry)
#---------------------------------------------------------------------------
function New-BootstrapUseCase {
    [CmdletBinding()]
    param(
        [string]$Id,
        [string]$Name
    )
    return [pscustomobject][ordered]@{
        Id           = $Id
        Name         = $Name
        Capability   = 'capability.workspace.bootstrap'
        EngineType   = 'Bootstrap'
        ProviderType = 'GitHub'
        Status       = 'Registered'
    }
}
function New-WorkspaceDiscoveryUseCase {
    [CmdletBinding()]
    param(
        [string]$Id,
        [string]$Name
    )
    return [pscustomobject][ordered]@{
        Id           = $Id
        Name         = $Name
        Capability   = 'capability.workspace.discovery'
        EngineType   = 'Discovery'
        ProviderType = 'Workspace'
        Status       = 'Registered'
    }
}
function New-CapabilityDiscoveryUseCase {
    [CmdletBinding()]
    param(
        [string]$Id,
        [string]$Name
    )
    return [pscustomobject][ordered]@{
        Id           = $Id
        Name         = $Name
        Capability   = 'capability.capability.discovery'
        EngineType   = 'Discovery'
        ProviderType = 'Capability'
        Status       = 'Registered'
    }
}
function New-ConfigurationLoadUseCase {
    [CmdletBinding()]
    param(
        [string]$Id,
        [string]$Name
    )
    return [pscustomobject][ordered]@{
        Id           = $Id
        Name         = $Name
        Capability   = 'capability.configuration.load'
        EngineType   = 'Config'
        ProviderType = 'Configuration'
        Status       = 'Registered'
    }
}
function New-ConfigurationValidateUseCase {
    [CmdletBinding()]
    param(
        [string]$Id,
        [string]$Name
    )
    return [pscustomobject][ordered]@{
        Id           = $Id
        Name         = $Name
        Capability   = 'capability.configuration.validate'
        EngineType   = 'Config'
        ProviderType = 'Configuration'
        Status       = 'Registered'
    }
}
function New-DependencyResolveUseCase {
    [CmdletBinding()]
    param(
        [string]$Id,
        [string]$Name
    )
    return [pscustomobject][ordered]@{
        Id           = $Id
        Name         = $Name
        Capability   = 'capability.dependency.resolve'
        EngineType   = 'Dependency'
        ProviderType = 'Dependency'
        Status       = 'Registered'
    }
}
function New-ProviderResolveUseCase {
    [CmdletBinding()]
    param(
        [string]$Id,
        [string]$Name
    )
    return [pscustomobject][ordered]@{
        Id           = $Id
        Name         = $Name
        Capability   = 'capability.provider.resolve'
        EngineType   = 'Provider'
        ProviderType = 'Provider'
        Status       = 'Registered'
    }
}
function New-RuntimeStartupUseCase {
    [CmdletBinding()]
    param(
        [string]$Id,
        [string]$Name
    )
    return [pscustomobject][ordered]@{
        Id           = $Id
        Name         = $Name
        Capability   = 'capability.runtime.startup'
        EngineType   = 'Runtime'
        ProviderType = 'Runtime'
        Status       = 'Registered'
    }
}
function New-KernelStartupUseCase {
    [CmdletBinding()]
    param(
        [string]$Id,
        [string]$Name
    )
    return [pscustomobject][ordered]@{
        Id           = $Id
        Name         = $Name
        Capability   = 'capability.kernel.startup'
        EngineType   = 'Kernel'
        ProviderType = 'FileSystem'
        Status       = 'Registered'
    }
}
