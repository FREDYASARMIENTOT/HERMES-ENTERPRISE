<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderEngine.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Motor de Provider — resuelve proveedores registrados por tipo.
    Ciclo de vida: Instance → Initialize → Resolve → Validate → Complete/Fault
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-ProviderEngine {
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
        EngineType  = 'Provider'
        Status      = 'Stopped'
        Capabilities = @('capability.provider.resolve')
        CreatedAt   = [datetime]::UtcNow.ToString('o')
        Metrics     = @{
            TotalResolutions = 0
            TotalDuration    = 0
        }
    }
}

function Invoke-ProviderEngine {
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
        $providerType = $UseCaseContext.InputParameters.ProviderType
        if ([string]::IsNullOrEmpty($providerType)) {
            throw 'ProviderEngine requires ProviderType in InputParameters'
        }

        $Engine.Metrics.TotalResolutions++
        $Engine.Status = 'Completed'

        return @{
            Engine       = 'ProviderEngine'
            Status       = 'Completed'
            ProviderType = $providerType
        }
    }
    catch {
        $Engine.Status = 'Faulted'
        return @{ Engine = 'ProviderEngine'; Status = 'Faulted'; Error = $_.Exception.Message }
    }
    finally {
        $Engine.Metrics.TotalDuration += [math]::Round(([datetime]::UtcNow - $startTime).TotalMilliseconds, 2)
    }
}

function Test-ProviderEngineValid {
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

