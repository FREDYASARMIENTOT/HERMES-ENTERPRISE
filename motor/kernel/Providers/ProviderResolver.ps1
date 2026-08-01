<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderResolver.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Resolvedor de dependencias entre proveedores del Kernel Enterprise.
    Proporciona capacidades de descubrimiento y resolución de proveedores por tipo, nombre y estado.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-ProviderResolver {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Registry
    )

    return [pscustomobject][ordered]@{
        Registry = $Registry
    }
}

function Resolve-ProviderById {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Resolver,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderId
    )

    return Get-ProviderFromRegistry -Registry $Resolver.Registry -ProviderId $ProviderId
}

function Resolve-ProvidersByName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Resolver,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderName
    )

    $allProviders = Get-AllProvidersFromRegistry -Registry $Resolver.Registry
    return $allProviders | Where-Object { $_.Name -eq $ProviderName }
}

function Resolve-ProvidersByType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Resolver,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderType
    )

    return Get-AllProvidersFromRegistry -Registry $Resolver.Registry -FilterByType $ProviderType
}

function Resolve-ProvidersByStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Resolver,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Stopped', 'Initialized', 'Running', 'Faulted')]
        [string]$Status
    )

    return Get-AllProvidersFromRegistry -Registry $Resolver.Registry -FilterByStatus $Status
}

function Resolve-ConnectedProviders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Resolver
    )

    $allProviders = Get-AllProvidersFromRegistry -Registry $Resolver.Registry
    return $allProviders | Where-Object { $_.IsConnected }
}

function Get-ProviderResolverSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Resolver
    )

    $providers = Get-AllProvidersFromRegistry -Registry $Resolver.Registry
    $summary = @()

    foreach ($provider in $providers) {
        $summary += [pscustomobject][ordered]@{
            Id            = $provider.Id
            Name          = $provider.Name
            Version       = $provider.Version
            ProviderType  = $provider.ProviderType
            Status        = $provider.Status
            IsConnected   = $provider.IsConnected
        }
    }

    return $summary
}

Export-ModuleMember -Function New-ProviderResolver, Resolve-ProviderById, Resolve-ProvidersByName, Resolve-ProvidersByType, Resolve-ProvidersByStatus, Resolve-ConnectedProviders, Get-ProviderResolverSummary