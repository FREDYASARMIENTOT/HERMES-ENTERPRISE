<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderExecutionContext.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Contexto de ejecución compartido entre proveedores del Kernel Enterprise.
    Proporciona un mecanismo para compartir credenciales, configuraciones y estado entre
    proveedores durante el ciclo de vida de una operación.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-ProviderExecutionContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ParentExecutionId = ''
    )

    return [pscustomobject][ordered]@{
        ExecutionId       = [guid]::NewGuid().ToString()
        ParentExecutionId = $ParentExecutionId
        SharedCredentials = @{}
        SharedConfig      = @{}
        SharedState       = @{}
        ProviderResults   = [System.Collections.ArrayList]@()
        StartTime         = (Get-Date).ToString('o')
        IsCompleted       = $false
        IsFaulted         = $false
    }
}

function Set-ProviderContextCredential {
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

    $Context.SharedCredentials[$Key] = $Value
}

function Get-ProviderContextCredential {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Context,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Key
    )

    if ($Context.SharedCredentials.ContainsKey($Key)) {
        return $Context.SharedCredentials[$Key]
    }

    return $null
}

function Set-ProviderContextConfig {
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

    $Context.SharedConfig[$Key] = $Value
}

function Get-ProviderContextConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Context,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Key
    )

    if ($Context.SharedConfig.ContainsKey($Key)) {
        return $Context.SharedConfig[$Key]
    }

    return $null
}

function Register-ProviderExecutionResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Context,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Success', 'Failure', 'Skipped')]
        [string]$Result,

        [Parameter(Mandatory = $false)]
        [int]$DurationMs = 0,

        [Parameter(Mandatory = $false)]
        $Output = $null
    )

    $null = $Context.ProviderResults.Add([pscustomobject][ordered]@{
        Timestamp    = (Get-Date).ToString('o')
        ProviderId   = $ProviderId
        ProviderName = $ProviderName
        Result       = $Result
        DurationMs   = $DurationMs
        Output       = $Output
    })
}

function Complete-ProviderExecutionContext {
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
        $Context.SharedState['ErrorMessage'] = $ErrorMessage
    }

    $Context.SharedState['EndTime'] = (Get-Date).ToString('o')
}

function Get-ProviderExecutionContextSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Context
    )

    $successCount = ($Context.ProviderResults | Where-Object { $_.Result -eq 'Success' } | Measure-Object).Count
    $failureCount = ($Context.ProviderResults | Where-Object { $_.Result -eq 'Failure' } | Measure-Object).Count
    $skippedCount = ($Context.ProviderResults | Where-Object { $_.Result -eq 'Skipped' } | Measure-Object).Count

    return [pscustomobject][ordered]@{
        ExecutionId    = $Context.ExecutionId
        IsCompleted    = $Context.IsCompleted
        IsFaulted      = $Context.IsFaulted
        TotalResults   = $Context.ProviderResults.Count
        SuccessCount   = $successCount
        FailureCount   = $failureCount
        SkippedCount   = $skippedCount
        ConfigKeys     = $Context.SharedConfig.Keys
        StartTime      = $Context.StartTime
    }
}

Export-ModuleMember -Function New-ProviderExecutionContext, Set-ProviderContextCredential, Get-ProviderContextCredential, Set-ProviderContextConfig, Get-ProviderContextConfig, Register-ProviderExecutionResult, Complete-ProviderExecutionContext, Get-ProviderExecutionContextSummary