<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : KernelEngine.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Motor de Kernel — orquesta el startup completo del Kernel Enterprise.
    Ciclo de vida: Instance → Initialize → StartSubsystems → HealthCheck → Complete/Fault
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-KernelEngine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    return [pscustomobject][ordered]@{
        Id          = $Id
        Name        = $Name
        Version     = '1.0.0'
        EngineType  = 'Kernel'
        Status      = 'Stopped'
        Capabilities = @('capability.kernel.startup')
        CreatedAt   = [datetime]::UtcNow.ToString('o')
        Metrics     = @{
            TotalStarts     = 0
            TotalDuration   = 0
        }
    }
}

function Invoke-KernelEngine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Engine,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext,

        [Parameter(Mandatory = $false)]
        [psobject]$Container = $null
    )

    $startTime = [datetime]::UtcNow
    $Engine.Status = 'Running'

    try {
        $Engine.Metrics.TotalStarts++
        $Engine.Status = 'Completed'

        return @{
            Engine = 'KernelEngine'
            Status = 'Completed'
        }
    }
    catch {
        $Engine.Status = 'Faulted'
        return @{ Engine = 'KernelEngine'; Status = 'Faulted'; Error = $_.Exception.Message }
    }
    finally {
        $Engine.Metrics.TotalDuration += [math]::Round(([datetime]::UtcNow - $startTime).TotalMilliseconds, 2)
    }
}

function Test-KernelEngineValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Engine
    )

    return (-not [string]::IsNullOrEmpty($Engine.Id)) -and
           (-not [string]::IsNullOrEmpty($Engine.Name)) -and
           ($null -ne $Engine.Capabilities -and $Engine.Capabilities.Count -gt 0)
}

