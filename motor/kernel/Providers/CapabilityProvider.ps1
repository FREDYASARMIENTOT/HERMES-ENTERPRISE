<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : CapabilityProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Proveedor de Capacidades — expone capacidades registradas en el sistema.
    Satisface: capability.capability.discovery
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-CapabilityProvider {
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
        Id           = $Id
        Name         = $Name
        Version      = '1.0.0'
        Type         = 'Capability'
        Status       = 'Uninitialized'
        Capabilities = @('capability.capability.discovery')
        CreatedAt    = [datetime]::UtcNow.ToString('o')
    }
}

function Invoke-CapabilityProvider {
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
            Provider     = 'CapabilityProvider'
            Status       = 'Available'
        }
    }
    catch {
        $Provider.Status = 'Error'
        return @{ Provider = 'CapabilityProvider'; Status = 'Error'; Error = $_.Exception.Message }
    }
}

function Test-CapabilityProviderValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    return (-not [string]::IsNullOrEmpty($Provider.Id)) -and
           (-not [string]::IsNullOrEmpty($Provider.Name))
}

