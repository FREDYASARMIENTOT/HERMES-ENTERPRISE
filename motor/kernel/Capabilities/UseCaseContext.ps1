<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : UseCaseContext.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Contexto de ejecución para un Use Case del Core.
    Encapsula capacidades, entrada, salida, metadatos y estado de ejecución.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea un nuevo contexto de Use Case.
.DESCRIPTION
    Inicializa el contexto con el nombre, capacidades requeridas, parámetros de entrada y metadatos.
.PARAMETER UseCaseName
    Nombre único del Use Case.
.PARAMETER RequiredCapabilities
    Lista de capacidades requeridas para ejecutar el Use Case.
.PARAMETER InputParameters
    Hashtable con los parámetros de entrada del Use Case.
.PARAMETER Metadata
    Hashtable opcional con metadatos adicionales (versión, autor, etc.).
#>
function New-UseCaseContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UseCaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$RequiredCapabilities,

        [Parameter(Mandatory = $false)]
        [hashtable]$InputParameters = @{},

        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )

    return [pscustomobject][ordered]@{
        # Identidad
        UseCaseName         = $UseCaseName
        UseCaseId           = [guid]::NewGuid().ToString()

        # Capacidades requeridas
        RequiredCapabilities = $RequiredCapabilities

        # Parámetros
        InputParameters     = $InputParameters
        OutputResults       = $null

        # Estado de ejecución
        Status              = 'Pending'   # Pending | Validated | Executing | Completed | Failed | RolledBack
        StartedAt           = $null
        CompletedAt         = $null
        ExecutionTimeMs     = 0

        # Metadatos
        Metadata            = $Metadata

        # Errores
        Errors              = [System.Collections.ArrayList]@()

        # Pipeline Stack (engines and providers invoked)
        PipelineStack       = [System.Collections.ArrayList]@()
    }
}

<#
.SYNOPSIS
    Valida que el contexto del Use Case tenga todos los campos requeridos.
#>
function Test-UseCaseContextValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext
    )

    process {
        $isValid = $true

        if ([string]::IsNullOrEmpty($UseCaseContext.UseCaseName)) {
            $null = $UseCaseContext.Errors.Add('UseCaseName cannot be null or empty')
            $isValid = $false
        }

        if ($null -eq $UseCaseContext.RequiredCapabilities -or $UseCaseContext.RequiredCapabilities.Count -eq 0) {
            $null = $UseCaseContext.Errors.Add('At least one RequiredCapability must be specified')
            $isValid = $false
        }

        return $isValid
    }
}

<#
.SYNOPSIS
    Obtiene un resumen del estado del Use Case.
#>
function Get-UseCaseContextStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext
    )

    process {
        return [pscustomobject][ordered]@{
            UseCaseId            = $UseCaseContext.UseCaseId
            UseCaseName          = $UseCaseContext.UseCaseName
            Status               = $UseCaseContext.Status
            RequiredCapabilities = $UseCaseContext.RequiredCapabilities -join ', '
            ExecutionTimeMs      = $UseCaseContext.ExecutionTimeMs
            ErrorCount           = $UseCaseContext.Errors.Count
            PipelineSteps        = $UseCaseContext.PipelineStack.Count
        }
    }
}

