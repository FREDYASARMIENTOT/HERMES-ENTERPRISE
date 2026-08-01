<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderDiscovery.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Motor de descubrimiento de Providers registrados en el sistema.
    Escanea el registro de Providers, filtra por tipo/capacidad y retorna los candidatos.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea un nuevo discovery de Providers.
.DESCRIPTION
    Inicializa el discovery context con el registro de Providers y metadatos.
.PARAMETER ProviderRegistry
    El registro de Providers (ProviderRegistry) donde buscar.
#>
function New-ProviderDiscovery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$ProviderRegistry
    )

    return [pscustomobject][ordered]@{
        Registry       = $ProviderRegistry
        SearchResults  = [System.Collections.ArrayList]@()
        LastSearch     = $null
    }
}

<#
.SYNOPSIS
    Busca Providers que satisfagan una capacidad específica.
.PARAMETER ProviderDiscovery
    El objeto de descubrimiento.
.PARAMETER CapabilityName
    Nombre de la capacidad a buscar.
#>
function Find-ProviderByCapability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$ProviderDiscovery,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CapabilityName
    )

    $results = [System.Collections.ArrayList]@()
    $providers = $ProviderDiscovery.Registry.Providers

    if ($null -eq $providers -or $providers.Count -eq 0) {
        return $results
    }

    foreach ($providerEntry in $providers.Values) {
        $provider = $providerEntry
        $providerCapabilities = @()

        if ($provider.PSObject.Properties.Name -contains 'Capabilities') {
            $providerCapabilities = $provider.Capabilities
        }
        elseif ($provider.PSObject.Properties.Name -contains 'Metadata' -and
                $provider.Metadata.PSObject.Properties.Name -contains 'Capabilities') {
            $providerCapabilities = $provider.Metadata.Capabilities
        }

        if ($providerCapabilities -contains $CapabilityName) {
            $null = $results.Add($provider)
        }
    }

    $ProviderDiscovery.SearchResults = $results
    $ProviderDiscovery.LastSearch = $CapabilityName
    return $results
}

<#
.SYNOPSIS
    Busca Providers por tipo.
.PARAMETER ProviderDiscovery
    El objeto de descubrimiento.
.PARAMETER ProviderType
    Tipo de Provider a buscar (git, azure, filesystem, etc.).
#>
function Find-ProviderByType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$ProviderDiscovery,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderType
    )

    $results = [System.Collections.ArrayList]@()
    $providers = $ProviderDiscovery.Registry.Providers

    if ($null -eq $providers -or $providers.Count -eq 0) {
        return $results
    }

    foreach ($providerEntry in $providers.Values) {
        $provider = $providerEntry
        $type = $provider.ProviderType
        if ($provider.PSObject.Properties.Name -contains 'Type') {
            $type = $provider.Type
        }

        if ($type -eq $ProviderType) {
            $null = $results.Add($provider)
        }
    }

    $ProviderDiscovery.SearchResults = $results
    $ProviderDiscovery.LastSearch = "Type:$ProviderType"
    return $results
}

<#
.SYNOPSIS
    Lista todos los Providers descubiertos en la última búsqueda.
#>
function Get-DiscoveredProviders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$ProviderDiscovery
    )

    return $ProviderDiscovery.SearchResults
}

