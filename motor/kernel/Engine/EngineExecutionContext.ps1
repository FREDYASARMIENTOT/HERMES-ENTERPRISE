<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : EngineExecutionContext.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Contexto de ejecución compartido entre motores del Kernel Enterprise.
    Proporciona un mecanismo para compartir datos, estado y configuración entre motores
    durante el ciclo de ejecución de un pipeline.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea un nuevo contexto de ejecución para motores.
.DESCRIPTION
    Inicializa el contexto con un identificador único, datos compartidos y metadatos.
    El contexto es el mecanismo principal para pasar información entre motores en un pipeline.
#>
function New-EngineExecutionContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ParentExecutionId = ''
    )

    return [pscustomobject][ordered]@{
        ExecutionId      = [guid]::NewGuid().ToString()
        ParentExecutionId = $ParentExecutionId
        SharedData       = @{}
        Metadata         = @{}
        StartTime        = (Get-Date).ToString('o')
        EngineResults    = [System.Collections.ArrayList]@()
        IsCompleted      = $false
        IsFaulted        = $false
    }
}

<#
.SYNOPSIS
    Establece un valor en los datos compartidos del contexto.
.DESCRIPTION
    Almacena un valor en el hashtable SharedData del contexto.
    Si la clave ya existe, el valor se sobrescribe.
.PARAMETER Context
    Instancia de EngineExecutionContext.
.PARAMETER Key
    Clave del dato a almacenar.
.PARAMETER Value
    Valor a almacenar.
#>
function Set-ExecutionContextData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Context,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        $Value
    )

    $Context.SharedData[$Key] = $Value
}

<#
.SYNOPSIS
    Obtiene un valor de los datos compartidos del contexto.
.DESCRIPTION
    Recupera un valor del hashtable SharedData del contexto.
    Si la clave no existe, retorna $null.
.PARAMETER Context
    Instancia de EngineExecutionContext.
.PARAMETER Key
    Clave del dato a recuperar.
#>
function Get-ExecutionContextData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Context,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Key
    )

    if ($Context.SharedData.ContainsKey($Key)) {
        return $Context.SharedData[$Key]
    }

    return $null
}

<#
.SYNOPSIS
    Elimina un valor de los datos compartidos del contexto.
#>
function Remove-ExecutionContextData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Context,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Key
    )

    if ($Context.SharedData.ContainsKey($Key)) {
        $Context.SharedData.Remove($Key)
    }
}

<#
.SYNOPSIS
    Registra el resultado de la ejecución de un motor en el contexto.
.DESCRIPTION
    Agrega un resultado de motor a la colección EngineResults del contexto.
    Esto permite trackear qué motores se ejecutaron y con qué resultado.
.PARAMETER Context
    Instancia de EngineExecutionContext.
.PARAMETER EngineId
    Identificador del motor que se ejecutó.
.PARAMETER EngineName
    Nombre del motor que se ejecutó.
.PARAMETER Result
    Resultado de la ejecución ('Success', 'Failure', 'Skipped').
.PARAMETER DurationMs
    Duración de la ejecución en milisegundos.
.PARAMETER Output
    Datos de salida del motor (opcional).
#>
function Register-EngineExecutionResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Context,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EngineId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EngineName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Success', 'Failure', 'Skipped')]
        [string]$Result,

        [Parameter(Mandatory = $false)]
        [int]$DurationMs = 0,

        [Parameter(Mandatory = $false)]
        $Output = $null
    )

    $null = $Context.EngineResults.Add([pscustomobject][ordered]@{
        Timestamp  = (Get-Date).ToString('o')
        EngineId   = $EngineId
        EngineName = $EngineName
        Result     = $Result
        DurationMs = $DurationMs
        Output     = $Output
    })
}

<#
.SYNOPSIS
    Marca el contexto de ejecución como completado.
.DESCRIPTION
    Establece IsCompleted a $true.
    Si se proporciona un mensaje de error, también marca IsFaulted como $true.
#>
function Complete-EngineExecutionContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Context,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = ''
    )

    $Context.IsCompleted = $true

    if (-not [string]::IsNullOrEmpty($ErrorMessage)) {
        $Context.IsFaulted = $true
        $Context.Metadata['ErrorMessage'] = $ErrorMessage
    }

    $Context.Metadata['EndTime'] = (Get-Date).ToString('o')
}

<#
.SYNOPSIS
    Obtiene un resumen del contexto de ejecución.
.DESCRIPTION
    Retorna un objeto resumen con el estado actual del contexto,
    incluyendo cantidad de resultados y estado de finalización.
#>
function Get-ExecutionContextSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Context
    )

    $successCount = ($Context.EngineResults | Where-Object { $_.Result -eq 'Success' } | Measure-Object).Count
    $failureCount = ($Context.EngineResults | Where-Object { $_.Result -eq 'Failure' } | Measure-Object).Count
    $skippedCount = ($Context.EngineResults | Where-Object { $_.Result -eq 'Skipped' } | Measure-Object).Count

    return [pscustomobject][ordered]@{
        ExecutionId       = $Context.ExecutionId
        IsCompleted       = $Context.IsCompleted
        IsFaulted         = $Context.IsFaulted
        TotalResults      = $Context.EngineResults.Count
        SuccessCount      = $successCount
        FailureCount      = $failureCount
        SkippedCount      = $skippedCount
        SharedDataKeys    = $Context.SharedData.Keys
        StartTime         = $Context.StartTime
    }
}

Export-ModuleMember -Function New-EngineExecutionContext, Set-ExecutionContextData, Get-ExecutionContextData, Remove-ExecutionContextData, Register-EngineExecutionResult, Complete-EngineExecutionContext, Get-ExecutionContextSummary