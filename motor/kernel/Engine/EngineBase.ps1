<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : EngineBase.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Clase base abstracta para todos los motores del Kernel Enterprise.
    Proporciona la infraestructura común: ciclo de vida, eventos, logging y estado.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea una nueva instancia de EngineBase — clase base para todos los motores.
.DESCRIPTION
    Inicializa el motor con su identificador único, nombre, versión y contexto de ejecución.
    Establece el estado inicial a 'Stopped' y prepara las colecciones de eventos y errores.
.PARAMETER Id
    Identificador único del motor.
.PARAMETER Name
    Nombre descriptivo del motor.
.PARAMETER Version
    Versión semántica del motor.
.PARAMETER EngineContext
    Hashtable con el contexto de ejecución del motor (puede ser $null).
#>
function New-EngineBase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Version,

        [Parameter(Mandatory = $false)]
        [hashtable]$EngineContext = @{}
    )

    return [pscustomobject][ordered]@{
        # Identidad
        Id      = $Id
        Name    = $Name
        Version = $Version

        # Ciclo de vida
        Status        = 'Stopped'
        StatusHistory = @()

        # Contexto
        EngineContext = $EngineContext

        # Eventos internos
        EngineEvents  = [System.Collections.ArrayList]@()

        # Errores
        Errors        = [System.Collections.ArrayList]@()
    }
}

<#
.SYNOPSIS
    Inicializa el motor con el contexto proporcionado.
.DESCRIPTION
    Establece el contexto de ejecución y cambia el estado a 'Initialized'.
    No debe iniciar la operación del motor; solo prepara sus estructuras internas.
#>
function Initialize-EngineBase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Engine,

        [Parameter(Mandatory = $true)]
        [hashtable]$EngineContext
    )

    process {
        $Engine.EngineContext = $EngineContext
        $Engine.Status = 'Initialized'

        # Registrar evento de inicialización
        $null = $Engine.EngineEvents.Add(@{
            Timestamp = (Get-Date).ToString('o')
            EventType = 'Initialize'
            Status    = 'Initialized'
        })

        return $Engine
    }
}

<#
.SYNOPSIS
    Valida que la configuración y el contexto del motor sean correctos.
.DESCRIPTION
    Verifica que el motor tenga un Id, Name y Version no vacíos.
    Retorna $true si la validación es exitosa, $false en caso contrario.
    Los errores de validación se agregan a la colección Errors del motor.
#>
function Test-EngineBaseValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Engine
    )

    process {
        $isValid = $true

        if ([string]::IsNullOrEmpty($Engine.Id)) {
            $null = $Engine.Errors.Add('Engine Id cannot be null or empty')
            $isValid = $false
        }

        if ([string]::IsNullOrEmpty($Engine.Name)) {
            $null = $Engine.Errors.Add('Engine Name cannot be null or empty')
            $isValid = $false
        }

        if ([string]::IsNullOrEmpty($Engine.Version)) {
            $null = $Engine.Errors.Add('Engine Version cannot be null or empty')
            $isValid = $false
        }

        return $isValid
    }
}

<#
.SYNOPSIS
    Inicia la ejecución del motor.
.DESCRIPTION
    Cambia el estado del motor a 'Running' después de validar que esté en estado 'Initialized'.
    Si el motor no está en el estado correcto, registra un error y retorna $false.
#>
function Start-EngineBase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Engine
    )

    process {
        if ($Engine.Status -ne 'Initialized') {
            $null = $Engine.Errors.Add("Cannot start engine from status '$($Engine.Status)'. Expected 'Initialized'.")
            return $false
        }

        $Engine.Status = 'Running'

        $null = $Engine.EngineEvents.Add(@{
            Timestamp = (Get-Date).ToString('o')
            EventType = 'Start'
            Status    = 'Running'
        })

        return $true
    }
}

<#
.SYNOPSIS
    Detiene la ejecución del motor.
.DESCRIPTION
    Cambia el estado del motor a 'Stopped' desde cualquier estado.
    Si ya estaba detenido, no realiza ninguna acción.
#>
function Stop-EngineBase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Engine
    )

    process {
        if ($Engine.Status -eq 'Stopped') {
            return $Engine
        }

        $Engine.Status = 'Stopped'

        $null = $Engine.EngineEvents.Add(@{
            Timestamp = (Get-Date).ToString('o')
            EventType = 'Stop'
            Status    = 'Stopped'
        })

        return $Engine
    }
}

<#
.SYNOPSIS
    Marca el motor como en estado Faulted (con error).
.DESCRIPTION
    Cambia el estado del motor a 'Faulted' y registra el mensaje de error.
#>
function Set-EngineBaseFaulted {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Engine,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ErrorMessage
    )

    process {
        $Engine.Status = 'Faulted'
        $null = $Engine.Errors.Add($ErrorMessage)

        $null = $Engine.EngineEvents.Add(@{
            Timestamp   = (Get-Date).ToString('o')
            EventType   = 'Faulted'
            Status      = 'Faulted'
            ErrorMessage = $ErrorMessage
        })

        return $Engine
    }
}

<#
.SYNOPSIS
    Obtiene el estado actual del motor.
#>
function Get-EngineBaseStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Engine
    )

    process {
        return [pscustomobject][ordered]@{
            Id            = $Engine.Id
            Name          = $Engine.Name
            Version       = $Engine.Version
            Status        = $Engine.Status
            ErrorCount    = $Engine.Errors.Count
            EventCount    = $Engine.EngineEvents.Count
            LastEvent     = if ($Engine.EngineEvents.Count -gt 0) { $Engine.EngineEvents[-1] } else { $null }
        }
    }
}

Export-ModuleMember -Function New-EngineBase, Initialize-EngineBase, Test-EngineBaseValidation, Start-EngineBase, Stop-EngineBase, Set-EngineBaseFaulted, Get-EngineBaseStatus