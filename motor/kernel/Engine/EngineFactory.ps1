<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : EngineFactory.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Fábrica de motores del Kernel Enterprise.
    Centraliza la creación de instancias de motores con configuración predefinida.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea una nueva instancia de EngineFactory.
.DESCRIPTION
    Inicializa la fábrica con un registro interno de constructores de motores.
    Los constructores se identifican por el nombre del motor.
#>
function New-EngineFactory {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        Constructors = @{}
        CreatedCount = 0
    }
}

<#
.SYNOPSIS
    Registra un constructor de motores en la fábrica.
.DESCRIPTION
    Asocia un nombre de motor con un scriptblock constructor que crea instancias de ese motor.
    El scriptblock debe aceptar parámetros: $Id, $Name, $Version, $EngineContext.
.PARAMETER Factory
    Instancia de EngineFactory.
.PARAMETER EngineName
    Nombre único del tipo de motor.
.PARAMETER Constructor
    Scriptblock que crea una nueva instancia del motor.
.EXAMPLE
    Register-EngineFactoryConstructor -Factory $factory -EngineName 'BootstrapEngine' -Constructor {
        param($Id, $Name, $Version, $EngineContext)
        return New-EngineBase -Id $Id -Name $Name -Version $Version -EngineContext $EngineContext
    }
#>
function Register-EngineFactoryConstructor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Factory,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EngineName,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_ -is [scriptblock] })]
        [scriptblock]$Constructor
    )

    $Factory.Constructors[$EngineName] = $Constructor
}

<#
.SYNOPSIS
    Crea una nueva instancia de un motor registrado.
.DESCRIPTION
    Utiliza el constructor registrado para crear una instancia del motor especificado.
    Si el motor no está registrado, lanza una excepción.
.PARAMETER Factory
    Instancia de EngineFactory.
.PARAMETER EngineName
    Nombre del tipo de motor a crear.
.PARAMETER Id
    Identificador único para la nueva instancia.
.PARAMETER Version
    Versión del motor.
.PARAMETER EngineContext
    Contexto de ejecución (opcional).
#>
function New-EngineFromFactory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Factory,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EngineName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Version,

        [Parameter(Mandatory = $false)]
        [hashtable]$EngineContext = @{}
    )

    if (-not $Factory.Constructors.ContainsKey($EngineName)) {
        throw "Engine constructor not registered: $EngineName"
    }

    $constructor = $Factory.Constructors[$EngineName]
    $engine = & $constructor -Id $Id -Name $EngineName -Version $Version -EngineContext $EngineContext
    $Factory.CreatedCount++

    return $engine
}

<#
.SYNOPSIS
    Verifica si un constructor de motor está registrado.
#>
function Test-EngineFactoryRegistered {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Factory,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EngineName
    )

    return $Factory.Constructors.ContainsKey($EngineName)
}

<#
.SYNOPSIS
    Obtiene los nombres de todos los motores registrados en la fábrica.
#>
function Get-EngineFactoryRegisteredEngines {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Factory
    )

    return $Factory.Constructors.Keys | Sort-Object
}

