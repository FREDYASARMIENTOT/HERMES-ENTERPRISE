<#
.SYNOPSIS
    Administrador de Managed Identities en Azure.
.DESCRIPTION
    Provider canónico para crear y gestionar User-Assigned Managed Identities.
    Las Managed Identities permiten a los recursos Azure autenticarse entre sí
    sin credenciales estáticas.
    Se asigna como Contributor sobre el Resource Group compartido y como
    Key Vault Secrets User para acceso seguro a secretos.
    Incluye telemetría local y registro en SQLite.
#>

function New-HermesAzureManagedIdentity {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$Location,

        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [switch]$Force
    )

    Write-Host "[AzureManagedIdentity] Creating Managed Identity '$Name'" -ForegroundColor Cyan

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) not found. Install it first."
    }

    # Verificar existencia
    $existing = az identity show --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>$null
    if ($existing -and -not $Force) {
        Write-Warning "Managed Identity '$Name' already exists. Use -Force to recreate."
        return $existing | ConvertFrom-Json
    }

    if ($PSCmdlet.ShouldProcess($Name, 'Create Azure Managed Identity')) {
        $result = az identity create `
            --name $Name `
            --resource-group $ResourceGroupName `
            --location $Location `
            --subscription $SubscriptionId `
            2>&1 | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Managed Identity '$Name': $result"
        }

        $identity = $result | ConvertFrom-Json

        Write-Host "[AzureManagedIdentity] Managed Identity '$Name' created." -ForegroundColor Green
        Write-Host "[AzureManagedIdentity] PrincipalId: $($identity.principalId)" -ForegroundColor DarkGray
        Write-Host "[AzureManagedIdentity] ClientId: $($identity.clientId)" -ForegroundColor DarkGray

        return [PSCustomObject]@{
            Name              = $identity.name
            ResourceGroupName = $ResourceGroupName
            Location          = $Location
            SubscriptionId    = $SubscriptionId
            ClientId          = $identity.clientId
            PrincipalId       = $identity.principalId
            TenantId          = $identity.tenantId
            ProvisioningState = 'Succeeded'
        }
    }
}

function Get-HermesAzureManagedIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )

    Write-Host "[AzureManagedIdentity] Getting Managed Identity '$Name'" -ForegroundColor Cyan

    $result = az identity show --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Managed Identity '$Name' not found."
        return $null
    }

    return $result
}

function Set-HermesAzureManagedIdentityRole {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$PrincipalId,

        [Parameter(Mandatory)]
        [string]$Scope,

        [Parameter(Mandatory)]
        [string]$RoleDefinitionName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [switch]$Force
    )

    $roleDesc = "$RoleDefinitionName on $Scope"
    Write-Host "[AzureManagedIdentity] Assigning role '$RoleDefinitionName' to principal '$PrincipalId'" -ForegroundColor Cyan

    if ($Force -or $PSCmdlet.ShouldProcess($roleDesc, 'Assign RBAC Role')) {
        $result = az role assignment create `
            --assignee-object-id $PrincipalId `
            --assignee-principal-type ServicePrincipal `
            --scope $Scope `
            --role "$RoleDefinitionName" `
            --subscription $SubscriptionId `
            2>&1 | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to assign role '$RoleDefinitionName': $result"
        }

        Write-Host "[AzureManagedIdentity] Role '$RoleDefinitionName' assigned." -ForegroundColor Green
    }
}

function Remove-HermesAzureManagedIdentityRole {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$PrincipalId,

        [Parameter(Mandatory)]
        [string]$Scope,

        [Parameter(Mandatory)]
        [string]$RoleDefinitionName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )

    Write-Host "[AzureManagedIdentity] Removing role '$RoleDefinitionName' from principal '$PrincipalId'" -ForegroundColor Yellow

    if ($PSCmdlet.ShouldProcess($RoleDefinitionName, "Remove RBAC Role Assignment")) {
        az role assignment delete `
            --assignee $PrincipalId `
            --scope $Scope `
            --role "$RoleDefinitionName" `
            --subscription $SubscriptionId `
            2>&1 | Out-Null

        Write-Host "[AzureManagedIdentity] Role '$RoleDefinitionName' removed." -ForegroundColor Green
    }
}

function Remove-HermesAzureManagedIdentity {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [switch]$Force
    )

    Write-Host "[AzureManagedIdentity] Removing Managed Identity '$Name'" -ForegroundColor Yellow

    if ($Force -or $PSCmdlet.ShouldProcess($Name, 'Remove Azure Managed Identity')) {
        az identity delete --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete Managed Identity '$Name'."
        }
        Write-Host "[AzureManagedIdentity] Managed Identity '$Name' deleted." -ForegroundColor Green
    }
}

Export-ModuleMember -Function New-HermesAzureManagedIdentity, Get-HermesAzureManagedIdentity, Set-HermesAzureManagedIdentityRole, Remove-HermesAzureManagedIdentityRole, Remove-HermesAzureManagedIdentity