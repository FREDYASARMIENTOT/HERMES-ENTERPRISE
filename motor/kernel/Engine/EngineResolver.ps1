<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : EngineResolver.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Resolvedor de dependencias entre motores del Kernel Enterprise.
    Proporciona capacidades de descubrimiento y resolución de motores por nombre, capacidad o estado.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea una nueva instancia de EngineResolver.
.DESCRIPTION
    Inicializa el resolvedor vinculado a un EngineRegistry para consultar motores.
.PARAMETER Registry
    Instancia de EngineRegistry donde buscar motores.
#>
function New-EngineResolver {
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

<#
.SYNOPSIS
    Resuelve un motor por su Id.
.DESCRIPTION
    Busca un motor en el registro por su identificador único.
#>
function Resolve-EngineById {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Resolver,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EngineId
    )

    return Get-EngineFromRegistry -Registry $Resolver.Registry -EngineId $EngineId
}

<#
.SYNOPSIS
    Resuelve motores por su nombre.
.DESCRIPTION
    Busca todos los motores cuyo Name coincida exactamente con el valor proporcionado.
#>
function Resolve-EnginesByName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Resolver,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EngineName
    )

    $allEngines = Get-AllEnginesFromRegistry -Registry $Resolver.Registry
    return $allEngines | Where-Object { $_.Name -eq $EngineName }
}

<#
.SYNOPSIS
    Resuelve motores que tengan una capacidad específica.
.DESCRIPTION
    Busca motores cuya lista de capacidades contenga la capacidad especificada.
    Nota: Esta función requiere que los motores tengan una propiedad Capabilities.
.PARAMETER Resolver
    Instancia de EngineResolver.
.PARAMETER Capability
    Nombre de la capacidad a buscar.
#>
function Resolve-EnginesByCapability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Resolver,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Capability
    )

    $allEngines = Get-AllEnginesFromRegistry -Registry $Resolver.Registry
    return $allEngines | Where-Object {
        $_.PSObject.Properties.Name -contains 'Capabilities' -and
        $null -ne $_.Capabilities -and
        $_.Capabilities -contains $Capability
    }
}

<#
.SYNOPSIS
    Resuelve motores por estado.
.DESCRIPTION
    Busca todos los motores que estén en el estado especificado.
#>
function Resolve-EnginesByStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Resolver,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Stopped', 'Initialized', 'Running', 'Faulted')]
        [string]$Status
    )

    return Get-AllEnginesFromRegistry -Registry $Resolver.Registry -FilterByStatus $Status
}

<#
.SYNOPSIS
    Obtiene un resumen de todos los motores y su estado.
.DESCRIPTION
    Retorna una lista de objetos con información resumida de cada motor registrado.
#>
function Get-EngineResolverSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Resolver
    )

    $engines = Get-AllEnginesFromRegistry -Registry $Resolver.Registry
    $summary = @()

    foreach ($engine in $engines) {
        $summary += [pscustomobject][ordered]@{
            Id      = $engine.Id
            Name    = $engine.Name
            Version = $engine.Version
            Status  = $engine.Status
        }
    }

    return $summary
}

Export-ModuleMember -Function New-EngineResolver, Resolve-EngineById, Resolve-EnginesByName, Resolve-EnginesByCapability, Resolve-EnginesByStatus, Get-EngineResolverSummary