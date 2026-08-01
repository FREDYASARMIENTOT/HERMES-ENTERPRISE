<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ConfigEngine.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Motor de Configuración — carga, valida y expone configuraciones del sistema.
    Ciclo de vida: Instance → Initialize → Load → Validate → Resolve → Complete/Fault
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-ConfigEngine {
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
        EngineType  = 'Config'
        Status      = 'Stopped'
        Capabilities = @('capability.configuration.load', 'capability.configuration.validate')
        CreatedAt   = [datetime]::UtcNow.ToString('o')
        Metrics     = @{
            TotalLoads      = 0
            TotalDuration   = 0
        }
    }
}

function Invoke-ConfigEngine {
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
        $configPath = $UseCaseContext.InputParameters.ConfigPath
        if ([string]::IsNullOrEmpty($configPath)) {
            throw 'ConfigEngine requires ConfigPath in InputParameters'
        }

        $Engine.Metrics.TotalLoads++
        $Engine.Status = 'Completed'

        return @{
            Engine     = 'ConfigEngine'
            Status     = 'Completed'
            ConfigPath = $configPath
        }
    }
    catch {
        $Engine.Status = 'Faulted'
        return @{ Engine = 'ConfigEngine'; Status = 'Faulted'; Error = $_.Exception.Message }
    }
    finally {
        $Engine.Metrics.TotalDuration += [math]::Round(([datetime]::UtcNow - $startTime).TotalMilliseconds, 2)
    }
}

function Test-ConfigEngineValid {
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

