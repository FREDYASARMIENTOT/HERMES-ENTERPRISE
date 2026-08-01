<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : EngineRegistry.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Registro central de motores activos del Kernel Enterprise.
    Mantiene un inventario de todas las instancias de motores en ejecución.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea una nueva instancia de EngineRegistry.
.DESCRIPTION
    Inicializa el registro con una colección vacía de motores.
#>
function New-EngineRegistry {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Engines      = @{}
        TotalCount   = 0
        RunningCount = 0
        FaultedCount = 0
    }
}

<#
.SYNOPSIS
    Registra un motor en el registro.
.DESCRIPTION
    Almacena el motor en el registro indexado por su Id.
    Si el motor ya existe, lanza una excepción.
.PARAMETER Registry
    Instancia de EngineRegistry.
.PARAMETER Engine
    Instancia del motor a registrar.
#>
function Register-EngineInRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Registry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Engine
    )

    if ($Registry.Engines.ContainsKey($Engine.Id)) {
        throw "Engine already registered with Id: $($Engine.Id)"
    }

    $Registry.Engines[$Engine.Id] = $Engine
    $Registry.TotalCount++

    if ($Engine.Status -eq 'Running') {
        $Registry.RunningCount++
    }

    if ($Engine.Status -eq 'Faulted') {
        $Registry.FaultedCount++
    }
}

<#
.SYNOPSIS
    Elimina un motor del registro.
.DESCRIPTION
    Remueve el motor identificado por su Id del registro.
    Si el motor no existe, lanza una excepción.
#>
function Unregister-EngineFromRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Registry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EngineId
    )

    if (-not $Registry.Engines.ContainsKey($EngineId)) {
        throw "Engine not found in registry: $EngineId"
    }

    $engine = $Registry.Engines[$EngineId]

    if ($engine.Status -eq 'Running') {
        $Registry.RunningCount--
    }

    if ($engine.Status -eq 'Faulted') {
        $Registry.FaultedCount--
    }

    $Registry.Engines.Remove($EngineId)
    $Registry.TotalCount--
}

<#
.SYNOPSIS
    Obtiene un motor del registro por su Id.
#>
function Get-EngineFromRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Registry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EngineId
    )

    if ($Registry.Engines.ContainsKey($EngineId)) {
        return $Registry.Engines[$EngineId]
    }

    return $null
}

<#
.SYNOPSIS
    Obtiene todos los motores registrados, opcionalmente filtrados por estado.
#>
function Get-AllEnginesFromRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Registry,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Stopped', 'Initialized', 'Running', 'Faulted')]
        [string]$FilterByStatus = ''
    )

    $engines = $Registry.Engines.Values

    if (-not [string]::IsNullOrEmpty($FilterByStatus)) {
        $engines = $engines | Where-Object { $_.Status -eq $FilterByStatus }
    }

    return $engines
}

<#
.SYNOPSIS
    Actualiza los contadores del registro según el estado actual de los motores.
.DESCRIPTION
    Recorre todos los motores registrados y recalcula los contadores RunningCount y FaultedCount.
#>
function Update-EngineRegistryCounters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Registry
    )

    $Registry.RunningCount = ($Registry.Engines.Values | Where-Object { $_.Status -eq 'Running' } | Measure-Object).Count
    $Registry.FaultedCount = ($Registry.Engines.Values | Where-Object { $_.Status -eq 'Faulted' } | Measure-Object).Count
}

