<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : RuntimeEngine.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Motor de Runtime — gestiona el ciclo de vida del runtime del Kernel.
    Ciclo de vida: Instance → Initialize → Start → HealthCheck → Complete/Fault
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-RuntimeEngine {
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
        EngineType  = 'Runtime'
        Status      = 'Stopped'
        Capabilities = @('capability.runtime.startup')
        CreatedAt   = [datetime]::UtcNow.ToString('o')
        Metrics     = @{
            TotalStarts     = 0
            TotalDuration   = 0
        }
    }
}

function Invoke-RuntimeEngine {
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
            Engine    = 'RuntimeEngine'
            Status    = 'Completed'
        }
    }
    catch {
        $Engine.Status = 'Faulted'
        return @{ Engine = 'RuntimeEngine'; Status = 'Faulted'; Error = $_.Exception.Message }
    }
    finally {
        $Engine.Metrics.TotalDuration += [math]::Round(([datetime]::UtcNow - $startTime).TotalMilliseconds, 2)
    }
}

function Test-RuntimeEngineValid {
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

