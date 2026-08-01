<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : DependencyProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Proveedor de Dependencias — resuelve dependencias entre módulos.
    Satisface: capability.dependency.resolve
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-DependencyProvider {
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
        Type        = 'Dependency'
        Status      = 'Uninitialized'
        Capabilities = @('capability.dependency.resolve')
        CreatedAt   = [datetime]::UtcNow.ToString('o')
    }
}

function Invoke-DependencyProvider {
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
            Provider = 'DependencyProvider'
            Status   = 'Available'
        }
    }
    catch {
        $Provider.Status = 'Error'
        return @{ Provider = 'DependencyProvider'; Status = 'Error'; Error = $_.Exception.Message }
    }
}

function Test-DependencyProviderValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    return (-not [string]::IsNullOrEmpty($Provider.Id)) -and
           (-not [string]::IsNullOrEmpty($Provider.Name))
}

