<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : CapabilityRegistry.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Registro central de capacidades del sistema.
    Mapea capacidades (UseCase -> requiredCapabilities) a Engine y Provider resolvers.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea un nuevo registro de capacidades.
.DESCRIPTION
    Inicializa el contenedor que mapea capacidades requeridas a resolvers (Engine/Provider) concretos.
#>
function New-CapabilityRegistry {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        # Diccionario: CapabilityName -> @{ EngineResolvers = [], ProviderResolvers = [] }
        CapabilityMap      = @{}
        # Diccionario: UseCaseName -> @{ Capabilities = @(), Definition = {} }
        UseCaseMap         = @{}
        # Estadísticas
        RegisteredCapabilities = 0
        RegisteredUseCases     = 0
        LastUpdated         = [datetime]::MinValue
    }
}

<#
.SYNOPSIS
    Registra una capacidad con sus resolvers de Engine y Provider.
.PARAMETER CapabilityRegistry
    El registro de capacidades (CapabilityRegistry).
.PARAMETER CapabilityName
    Nombre de la capacidad (ej: "provision.git.repository").
.PARAMETER EngineResolver
    ScriptBlock o nombre del resolver de Engine que satisface la capacidad.
.PARAMETER ProviderResolver
    ScriptBlock o nombre del resolver de Provider asociado a la capacidad.
#>
function Register-CapabilityToRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$CapabilityRegistry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CapabilityName,

        [Parameter(Mandatory = $false)]
        [scriptblock]$EngineResolver = $null,

        [Parameter(Mandatory = $false)]
        [scriptblock]$ProviderResolver = $null
    )

    if (-not $CapabilityRegistry.CapabilityMap.ContainsKey($CapabilityName)) {
        $CapabilityRegistry.CapabilityMap[$CapabilityName] = @{
            EngineResolvers  = [System.Collections.ArrayList]@()
            ProviderResolvers = [System.Collections.ArrayList]@()
        }
    }

    if ($null -ne $EngineResolver) {
        $null = $CapabilityRegistry.CapabilityMap[$CapabilityName].EngineResolvers.Add($EngineResolver)
    }
    if ($null -ne $ProviderResolver) {
        $null = $CapabilityRegistry.CapabilityMap[$CapabilityName].ProviderResolvers.Add($ProviderResolver)
    }

    $CapabilityRegistry.RegisteredCapabilities = $CapabilityRegistry.CapabilityMap.Keys.Count
    $CapabilityRegistry.LastUpdated = [datetime]::UtcNow
    return $true
}

<#
.SYNOPSIS
    Verifica si una capacidad está registrada.
#>
function Test-CapabilityRegistered {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$CapabilityRegistry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CapabilityName
    )

    return $CapabilityRegistry.CapabilityMap.ContainsKey($CapabilityName)
}

<#
.SYNOPSIS
    Obtiene los resolvers de Engine para una capacidad específica.
#>
function Get-CapabilityEngineResolvers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$CapabilityRegistry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CapabilityName
    )

    if (-not $CapabilityRegistry.CapabilityMap.ContainsKey($CapabilityName)) {
        return @()
    }

    return $CapabilityRegistry.CapabilityMap[$CapabilityName].EngineResolvers
}

<#
.SYNOPSIS
    Obtiene los resolvers de Provider para una capacidad específica.
#>
function Get-CapabilityProviderResolvers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$CapabilityRegistry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CapabilityName
    )

    if (-not $CapabilityRegistry.CapabilityMap.ContainsKey($CapabilityName)) {
        return @()
    }

    return $CapabilityRegistry.CapabilityMap[$CapabilityName].ProviderResolvers
}

<#
.SYNOPSIS
    Resuelve un array de capacidades a sus resolvers de Engine y Provider.
    Retorna una lista de resolvers a ejecutar en orden.
#>
function Resolve-Capabilities {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$CapabilityRegistry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$RequiredCapabilities
    )

    $resolvedEngines = [System.Collections.ArrayList]@()
    $resolvedProviders = [System.Collections.ArrayList]@()

    foreach ($capability in $RequiredCapabilities) {
        if (-not $CapabilityRegistry.CapabilityMap.ContainsKey($capability)) {
            throw "Capability not registered: $capability"
        }

        $entry = $CapabilityRegistry.CapabilityMap[$capability]

        foreach ($engineResolver in $entry.EngineResolvers) {
            $null = $resolvedEngines.Add($engineResolver)
        }
        foreach ($providerResolver in $entry.ProviderResolvers) {
            $null = $resolvedProviders.Add($providerResolver)
        }
    }

    return [pscustomobject][ordered]@{
        EngineResolvers  = $resolvedEngines
        ProviderResolvers = $resolvedProviders
        CapabilityCount   = $RequiredCapabilities.Count
    }
}

<#
.SYNOPSIS
    Lista todas las capacidades registradas.
#>
function Get-CapabilityRegistrySummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$CapabilityRegistry
    )

    return [pscustomobject][ordered]@{
        RegisteredCapabilities = $CapabilityRegistry.RegisteredCapabilities
        RegisteredUseCases     = $CapabilityRegistry.RegisteredUseCases
        LastUpdated           = $CapabilityRegistry.LastUpdated
        CapabilityList        = @($CapabilityRegistry.CapabilityMap.Keys | Sort-Object)
    }
}

