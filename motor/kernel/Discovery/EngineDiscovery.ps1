<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : EngineDiscovery.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Motor de descubrimiento de Engines registrados en el sistema.
    Escanea el registro de Engines, filtra por tipo/capacidad y retorna los candidatos.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea un nuevo discovery de Engines.
.DESCRIPTION
    Inicializa el discovery context con el registro de Engines y metadatos.
.PARAMETER EngineRegistry
    El registro de Engines (EngineRegistry) donde buscar.
#>
function New-EngineDiscovery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$EngineRegistry
    )

    return [pscustomobject][ordered]@{
        Registry       = $EngineRegistry
        SearchResults  = [System.Collections.ArrayList]@()
        LastSearch     = $null
    }
}

<#
.SYNOPSIS
    Busca Engines que satisfagan una capacidad específica.
.PARAMETER EngineDiscovery
    El objeto de descubrimiento.
.PARAMETER CapabilityName
    Nombre de la capacidad a buscar.
#>
function Find-EngineByCapability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$EngineDiscovery,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CapabilityName
    )

    $results = [System.Collections.ArrayList]@()
    $engines = $EngineDiscovery.Registry.Engines

    if ($null -eq $engines -or $engines.Count -eq 0) {
        return $results
    }

    foreach ($engineEntry in $engines.Values) {
        $engine = $engineEntry
        $engineCapabilities = @()

        if ($engine.PSObject.Properties.Name -contains 'Capabilities') {
            $engineCapabilities = $engine.Capabilities
        }
        elseif ($engine.PSObject.Properties.Name -contains 'Metadata' -and
                $engine.Metadata.PSObject.Properties.Name -contains 'Capabilities') {
            $engineCapabilities = $engine.Metadata.Capabilities
        }

        if ($engineCapabilities -contains $CapabilityName) {
            $null = $results.Add($engine)
        }
    }

    $EngineDiscovery.SearchResults = $results
    $EngineDiscovery.LastSearch = $CapabilityName
    return $results
}

<#
.SYNOPSIS
    Busca Engines por tipo.
.PARAMETER EngineDiscovery
    El objeto de descubrimiento.
.PARAMETER EngineType
    Tipo de Engine a buscar (bootstrap, provision, etc.).
#>
function Find-EngineByType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$EngineDiscovery,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EngineType
    )

    $results = [System.Collections.ArrayList]@()
    $engines = $EngineDiscovery.Registry.Engines

    if ($null -eq $engines -or $engines.Count -eq 0) {
        return $results
    }

    foreach ($engineEntry in $engines.Values) {
        $engine = $engineEntry
        $type = $engine.EngineType
        if ($engine.PSObject.Properties.Name -contains 'Type') {
            $type = $engine.Type
        }

        if ($type -eq $EngineType) {
            $null = $results.Add($engine)
        }
    }

    $EngineDiscovery.SearchResults = $results
    $EngineDiscovery.LastSearch = "Type:$EngineType"
    return $results
}

<#
.SYNOPSIS
    Lista todos los Engines registrados.
#>
function Get-DiscoveredEngines {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$EngineDiscovery
    )

    return $EngineDiscovery.SearchResults
}

Export-ModuleMember -Function New-EngineDiscovery, Find-EngineByCapability, Find-EngineByType, Get-DiscoveredEngines