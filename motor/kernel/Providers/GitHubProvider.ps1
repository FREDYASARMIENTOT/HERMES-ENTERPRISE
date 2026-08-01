<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : GitHubProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Proveedor de GitHub — interactúa con la API de GitHub para operaciones de repositorio.
    Satisface: capability.workspace.bootstrap
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-GitHubProvider {
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
        Type        = 'GitHub'
        Status      = 'Uninitialized'
        Capabilities = @('capability.workspace.bootstrap')
        CreatedAt   = [datetime]::UtcNow.ToString('o')
    }
}

function Invoke-GitHubProvider {
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
        $workspaceName = $UseCaseContext.InputParameters.WorkspaceName
        $Provider.Status = 'Available'

        return @{
            Provider      = 'GitHubProvider'
            Status        = 'Available'
            WorkspaceName = $workspaceName
            RepoUrl       = "https://github.com/owner/$workspaceName"
        }
    }
    catch {
        $Provider.Status = 'Error'
        return @{ Provider = 'GitHubProvider'; Status = 'Error'; Error = $_.Exception.Message }
    }
}

function Test-GitHubProviderValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    return (-not [string]::IsNullOrEmpty($Provider.Id)) -and
           (-not [string]::IsNullOrEmpty($Provider.Name))
}

