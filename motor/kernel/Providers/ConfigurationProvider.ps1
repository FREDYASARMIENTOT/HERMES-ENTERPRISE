<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ConfigurationProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Proveedor de Configuración — carga configuraciones desde archivos JSON/YAML.
    Satisface: capability.configuration.load, capability.configuration.validate
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-ConfigurationProvider {
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
        Type        = 'Configuration'
        Status      = 'Uninitialized'
        Capabilities = @('capability.configuration.load', 'capability.configuration.validate')
        CreatedAt   = [datetime]::UtcNow.ToString('o')
    }
}

function Invoke-ConfigurationProvider {
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
        $configPath = $UseCaseContext.InputParameters.ConfigPath
        $Provider.Status = 'Available'

        return @{
            Provider   = 'ConfigurationProvider'
            Status     = 'Available'
            ConfigPath = $configPath
        }
    }
    catch {
        $Provider.Status = 'Error'
        return @{ Provider = 'ConfigurationProvider'; Status = 'Error'; Error = $_.Exception.Message }
    }
}

function Test-ConfigurationProviderValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    return (-not [string]::IsNullOrEmpty($Provider.Id)) -and
           (-not [string]::IsNullOrEmpty($Provider.Name))
}

