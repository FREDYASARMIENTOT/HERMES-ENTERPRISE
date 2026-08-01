<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderBase.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Clase base para todos los proveedores del Kernel Enterprise.
    Proporciona el ciclo de vida estándar: Initialize, Connect, Disconnect, con estado.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea una nueva instancia de ProviderBase.
.DESCRIPTION
    Inicializa el proveedor con su identidad, tipo, configuración y colecciones de eventos/errores.
.PARAMETER Id
    Identificador único del proveedor.
.PARAMETER Name
    Nombre descriptivo del proveedor.
.PARAMETER Version
    Versión semántica del proveedor.
.PARAMETER ProviderType
    Tipo de proveedor (Cloud, Storage, Auth, AI, etc.).
.PARAMETER ProviderConfig
    Configuración específica del proveedor.
#>
function New-ProviderBase {
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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderType,

        [Parameter(Mandatory = $false)]
        [hashtable]$ProviderConfig = @{}
    )

    return [pscustomobject][ordered]@{
        Id             = $Id
        Name           = $Name
        Version        = $Version
        ProviderType   = $ProviderType
        ProviderConfig = $ProviderConfig

        # Ciclo de vida
        Status         = 'Stopped'
        IsConnected    = $false

        # Eventos y errores
        Events         = [System.Collections.ArrayList]@()
        Errors         = [System.Collections.ArrayList]@()

        # Métricas de conexión
        ConnectionAttempts = 0
        LastConnection     = $null
    }
}

<#
.SYNOPSIS
    Inicializa el proveedor con su configuración.
.DESCRIPTION
    Valida y establece la configuración del proveedor. Cambia el estado a 'Initialized'.
#>
function Initialize-ProviderBase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Provider,

        [Parameter(Mandatory = $true)]
        [hashtable]$ProviderConfig
    )

    $Provider.ProviderConfig = $ProviderConfig
    $Provider.Status = 'Initialized'

    $null = $Provider.Events.Add(@{
        Timestamp = (Get-Date).ToString('o')
        EventType = 'Initialize'
        Status    = 'Initialized'
    })

    return $Provider
}

<#
.SYNOPSIS
    Valida que la configuración del proveedor sea correcta.
.DESCRIPTION
    Verifica que el proveedor tenga Id, Name, Version y ProviderType no vacíos.
#>
function Test-ProviderBaseValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    $isValid = $true

    if ([string]::IsNullOrEmpty($Provider.Id)) {
        $null = $Provider.Errors.Add('Provider Id cannot be null or empty')
        $isValid = $false
    }

    if ([string]::IsNullOrEmpty($Provider.Name)) {
        $null = $Provider.Errors.Add('Provider Name cannot be null or empty')
        $isValid = $false
    }

    if ([string]::IsNullOrEmpty($Provider.Version)) {
        $null = $Provider.Errors.Add('Provider Version cannot be null or empty')
        $isValid = $false
    }

    if ([string]::IsNullOrEmpty($Provider.ProviderType)) {
        $null = $Provider.Errors.Add('ProviderType cannot be null or empty')
        $isValid = $false
    }

    return $isValid
}

<#
.SYNOPSIS
    Conecta el proveedor.
.DESCRIPTION
    Cambia el estado del proveedor a 'Running' y marca IsConnected = $true.
    Requiere que el proveedor esté en estado 'Initialized'.
#>
function Connect-ProviderBase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    if ($Provider.Status -ne 'Initialized') {
        $null = $Provider.Errors.Add("Cannot connect provider from status '$($Provider.Status)'. Expected 'Initialized'.")
        return $false
    }

    $Provider.ConnectionAttempts++
    $Provider.Status = 'Running'
    $Provider.IsConnected = $true
    $Provider.LastConnection = (Get-Date).ToString('o')

    $null = $Provider.Events.Add(@{
        Timestamp = (Get-Date).ToString('o')
        EventType = 'Connect'
        Status    = 'Running'
    })

    return $true
}

<#
.SYNOPSIS
    Desconecta el proveedor.
.DESCRIPTION
    Cambia el estado del proveedor a 'Stopped' y marca IsConnected = $false.
#>
function Disconnect-ProviderBase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    if (-not $Provider.IsConnected) {
        return $Provider
    }

    $Provider.Status = 'Stopped'
    $Provider.IsConnected = $false

    $null = $Provider.Events.Add(@{
        Timestamp = (Get-Date).ToString('o')
        EventType = 'Disconnect'
        Status    = 'Stopped'
    })

    return $Provider
}

<#
.SYNOPSIS
    Marca el proveedor como Faulted (con error).
.DESCRIPTION
    Cambia el estado del proveedor a 'Faulted' y registra el mensaje de error.
#>
function Set-ProviderBaseFaulted {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Provider,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ErrorMessage
    )

    $Provider.Status = 'Faulted'
    $Provider.IsConnected = $false
    $null = $Provider.Errors.Add($ErrorMessage)

    $null = $Provider.Events.Add(@{
        Timestamp    = (Get-Date).ToString('o')
        EventType    = 'Faulted'
        Status       = 'Faulted'
        ErrorMessage = $ErrorMessage
    })

    return $Provider
}

<#
.SYNOPSIS
    Obtiene el estado actual del proveedor.
#>
function Get-ProviderBaseStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    return [pscustomobject][ordered]@{
        Id                = $Provider.Id
        Name              = $Provider.Name
        Version           = $Provider.Version
        ProviderType      = $Provider.ProviderType
        Status            = $Provider.Status
        IsConnected       = $Provider.IsConnected
        ErrorCount        = $Provider.Errors.Count
        ConnectionAttempts = $Provider.ConnectionAttempts
        LastConnection    = $Provider.LastConnection
    }
}

Export-ModuleMember -Function New-ProviderBase, Initialize-ProviderBase, Test-ProviderBaseValidation, Connect-ProviderBase, Disconnect-ProviderBase, Set-ProviderBaseFaulted, Get-ProviderBaseStatus