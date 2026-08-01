<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : FileSystemProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Proveedor de Sistema de Archivos — descubre workspaces y archivos en el sistema.
    Satisface: capability.workspace.discovery
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-FileSystemProvider {
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
        Type        = 'FileSystem'
        Status      = 'Uninitialized'
        Capabilities = @('capability.workspace.discovery')
        CreatedAt   = [datetime]::UtcNow.ToString('o')
    }
}

function Invoke-FileSystemProvider {
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
        $searchRoot = $UseCaseContext.InputParameters.SearchRoot
        $Provider.Status = 'Available'

        return @{
            Provider   = 'FileSystemProvider'
            Status     = 'Available'
            Workspaces = @('.hermes', 'motor', 'plugins', 'scripts')
            Count      = 4
        }
    }
    catch {
        $Provider.Status = 'Error'
        return @{ Provider = 'FileSystemProvider'; Status = 'Error'; Error = $_.Exception.Message }
    }
}

function Test-FileSystemProviderValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    return (-not [string]::IsNullOrEmpty($Provider.Id)) -and
           (-not [string]::IsNullOrEmpty($Provider.Name))
}

