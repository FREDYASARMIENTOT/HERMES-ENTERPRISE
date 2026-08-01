<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderRegistry.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Registro central de proveedores activos del Kernel Enterprise.
    Mantiene un inventario de todas las instancias de proveedores conectados.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-ProviderRegistry {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Providers       = @{}
        TotalCount      = 0
        ConnectedCount  = 0
        FaultedCount    = 0
    }
}

function Register-ProviderInRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Registry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    if ($Registry.Providers.ContainsKey($Provider.Id)) {
        throw "Provider already registered with Id: $($Provider.Id)"
    }

    $Registry.Providers[$Provider.Id] = $Provider
    $Registry.TotalCount++

    if ($Provider.IsConnected) {
        $Registry.ConnectedCount++
    }

    if ($Provider.Status -eq 'Faulted') {
        $Registry.FaultedCount++
    }
}

function Unregister-ProviderFromRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Registry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderId
    )

    if (-not $Registry.Providers.ContainsKey($ProviderId)) {
        throw "Provider not found in registry: $ProviderId"
    }

    $provider = $Registry.Providers[$ProviderId]

    if ($provider.IsConnected) {
        $Registry.ConnectedCount--
    }

    if ($provider.Status -eq 'Faulted') {
        $Registry.FaultedCount--
    }

    $Registry.Providers.Remove($ProviderId)
    $Registry.TotalCount--
}

function Get-ProviderFromRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Registry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderId
    )

    if ($Registry.Providers.ContainsKey($ProviderId)) {
        return $Registry.Providers[$ProviderId]
    }

    return $null
}

function Get-AllProvidersFromRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Registry,

        [Parameter(Mandatory = $false)]
        [string]$FilterByType = '',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Stopped', 'Initialized', 'Running', 'Faulted')]
        [string]$FilterByStatus = ''
    )

    $providers = $Registry.Providers.Values

    if (-not [string]::IsNullOrEmpty($FilterByType)) {
        $providers = $providers | Where-Object { $_.ProviderType -eq $FilterByType }
    }

    if (-not [string]::IsNullOrEmpty($FilterByStatus)) {
        $providers = $providers | Where-Object { $_.Status -eq $FilterByStatus }
    }

    return $providers
}

function Update-ProviderRegistryCounters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Registry
    )

    $Registry.ConnectedCount = ($Registry.Providers.Values | Where-Object { $_.IsConnected } | Measure-Object).Count
    $Registry.FaultedCount = ($Registry.Providers.Values | Where-Object { $_.Status -eq 'Faulted' } | Measure-Object).Count
}

