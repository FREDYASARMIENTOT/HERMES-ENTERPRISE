<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : RuntimeProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Proveedor de Runtime — gestiona el ciclo de vida del runtime del kernel.
    Satisface: capability.runtime.startup
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-RuntimeProvider {
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
        Type        = 'Runtime'
        Status      = 'Uninitialized'
        Capabilities = @('capability.runtime.startup')
        CreatedAt   = [datetime]::UtcNow.ToString('o')
    }
}

function Invoke-RuntimeProvider {
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
            Provider = 'RuntimeProvider'
            Status   = 'Available'
        }
    }
    catch {
        $Provider.Status = 'Error'
        return @{ Provider = 'RuntimeProvider'; Status = 'Error'; Error = $_.Exception.Message }
    }
}

function Test-RuntimeProviderValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    return (-not [string]::IsNullOrEmpty($Provider.Id)) -and
           (-not [string]::IsNullOrEmpty($Provider.Name))
}

