<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : WorkspaceProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Proveedor de Workspace — gestiona workspaces disponibles en el sistema.
    Satisface: capability.workspace.discovery
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-WorkspaceProvider {
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
        Type        = 'Workspace'
        Status      = 'Uninitialized'
        Capabilities = @('capability.workspace.discovery')
        CreatedAt   = [datetime]::UtcNow.ToString('o')
    }
}

function Invoke-WorkspaceProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCaseContext,

        [Parameter(Mandatory = $false)]
        [psobject]$Container = $null
    )

    $Provider.Status = 'Running'

    try {
        $Provider.Status = 'Available'
        return @{
            Provider   = 'WorkspaceProvider'
            Status     = 'Available'
        }
    }
    catch {
        $Provider.Status = 'Error'
        return @{ Provider = 'WorkspaceProvider'; Status = 'Error'; Error = $_.Exception.Message }
    }
}

function Test-WorkspaceProviderValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    return (-not [string]::IsNullOrEmpty($Provider.Id)) -and
           (-not [string]::IsNullOrEmpty($Provider.Name))
}

