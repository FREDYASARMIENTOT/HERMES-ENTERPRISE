<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : BootstrapEngine.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Motor de Bootstrap — orquesta la creación inicial del workspace.
    Ciclo de vida: Instance → Initialize → Validate → Execute → Complete/Fault
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-BootstrapEngine {
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
        EngineType  = 'Bootstrap'
        Status      = 'Stopped'
        Capabilities = @('capability.workspace.bootstrap')
        CreatedAt   = [datetime]::UtcNow.ToString('o')
        Metrics     = @{
            TotalExecutions = 0
            TotalDuration   = 0
        }
    }
}

function Invoke-BootstrapEngine {
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
        $workspaceName = $UseCaseContext.InputParameters.WorkspaceName
        $repoRoot = $UseCaseContext.InputParameters.RepositoryRoot

        if ([string]::IsNullOrEmpty($workspaceName) -or [string]::IsNullOrEmpty($repoRoot)) {
            throw 'BootstrapEngine requires WorkspaceName and RepositoryRoot in InputParameters'
        }

        $Engine.Metrics.TotalExecutions++
        $Engine.Status = 'Completed'

        return @{
            Engine        = 'BootstrapEngine'
            Status        = 'Completed'
            WorkspacePath = Join-Path $repoRoot $workspaceName
        }
    }
    catch {
        $Engine.Status = 'Faulted'
        return @{
            Engine  = 'BootstrapEngine'
            Status  = 'Faulted'
            Error   = $_.Exception.Message
        }
    }
    finally {
        $Engine.Metrics.TotalDuration += [math]::Round(([datetime]::UtcNow - $startTime).TotalMilliseconds, 2)
    }
}

function Test-BootstrapEngineValid {
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

