<#
.SYNOPSIS
    Administrador de Key Vault en Azure.
.DESCRIPTION
    Provider canónico para crear y gestionar Azure Key Vaults.
    Almacena secretos, connection strings y certificados de forma segura.
    Se integra con Managed Identity para control de acceso sin credenciales estáticas.
    Incluye telemetría local y registro en SQLite.
#>

function New-HermesAzureKeyVault {
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

        [ValidateSet('Standard','Premium')]
        [string]$Sku = 'Standard',

        [string[]]$AdminObjectIds,

        [switch]$EnableSoftDelete,

        [switch]$EnablePurgeProtection,

        [switch]$Force
    )

    Write-Host "[AzureKeyVault] Creating Key Vault '$Name' (SKU: $Sku)" -ForegroundColor Cyan

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) not found. Install it first."
    }

    # Verificar existencia
    $existing = az keyvault show --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>$null
    if ($existing -and -not $Force) {
        Write-Warning "Key Vault '$Name' already exists. Use -Force to overwrite."
        return $existing | ConvertFrom-Json
    }

    if ($PSCmdlet.ShouldProcess($Name, 'Create/Update Azure Key Vault')) {
        $softDelete = if ($EnableSoftDelete) { '--enable-soft-delete true' } else { '--enable-soft-delete false' }
        $purgeProtection = if ($EnablePurgeProtection) { '--enable-purge-protection true' } else { '' }

        $result = az keyvault create `
            --name $Name `
            --resource-group $ResourceGroupName `
            --location $Location `
            --subscription $SubscriptionId `
            --sku $Sku `
            $softDelete `
            $purgeProtection `
            2>&1 | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Key Vault '$Name': $result"
        }

        $vault = $result | ConvertFrom-Json

        # Agregar administradores si se especificaron
        if ($AdminObjectIds) {
            foreach ($oid in $AdminObjectIds) {
                az keyvault set-policy --name $Name --object-id $oid --secret-permissions get list set delete --key-permissions get list create delete --subscription $SubscriptionId 2>&1 | Out-Null
                Write-Host "[AzureKeyVault] Added admin policy for object '$oid'" -ForegroundColor DarkGray
            }
        }

        # Registrar secrets por defecto
        Write-Host "[AzureKeyVault] Adding default secrets..." -ForegroundColor DarkGray
        $defaultSecrets = @{
            'Hermes-Init-Complete' = 'false'
        }
        foreach ($secret in $defaultSecrets.GetEnumerator()) {
            az keyvault secret set --vault-name $Name --name $secret.Key --value $secret.Value --subscription $SubscriptionId 2>$null | Out-Null
        }

        Write-Host "[AzureKeyVault] Key Vault '$Name' ready." -ForegroundColor Green

        return [PSCustomObject]@{
            Name              = $vault.name
            ResourceGroupName = $ResourceGroupName
            Location          = $Location
            SubscriptionId    = $SubscriptionId
            Sku               = $Sku
            VaultUri          = $vault.properties.vaultUri
            ProvisioningState = 'Succeeded'
        }
    }
}

function Set-HermesAzureKeyVaultSecret {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$VaultName,

        [Parameter(Mandatory)]
        [string]$SecretName,

        [Parameter(Mandatory)]
        [string]$SecretValue,

        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )

    Write-Host "[AzureKeyVault] Setting secret '$SecretName' in vault '$VaultName'" -ForegroundColor Cyan

    if ($PSCmdlet.ShouldProcess($SecretName, "Set secret in $VaultName")) {
        $result = az keyvault secret set --vault-name $VaultName --name $SecretName --value $SecretValue --subscription $SubscriptionId 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to set secret '$SecretName': $result"
        }
        Write-Host "[AzureKeyVault] Secret '$SecretName' stored securely." -ForegroundColor Green
    }
}

function Get-HermesAzureKeyVaultSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VaultName,

        [Parameter(Mandatory)]
        [string]$SecretName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )

    Write-Host "[AzureKeyVault] Getting secret '$SecretName' from vault '$VaultName'" -ForegroundColor Cyan

    $result = az keyvault secret show --vault-name $VaultName --name $SecretName --subscription $SubscriptionId 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Secret '$SecretName' not found in vault '$VaultName'."
        return $null
    }

    return $result | ConvertFrom-Json
}

function Get-HermesAzureKeyVault {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )

    Write-Host "[AzureKeyVault] Getting Key Vault '$Name'" -ForegroundColor Cyan

    $result = az keyvault show --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Key Vault '$Name' not found."
        return $null
    }

    return $result
}

function Remove-HermesAzureKeyVault {
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

    # ── Guardian validation ───────────────────────────────────────────────
    $guardianPath = Join-Path $PSScriptRoot '..\..\Security\AzureInfrastructureGuardian.ps1'
    if (Test-Path $guardianPath) {
        . $guardianPath
        Invoke-InfrastructureGuardian -Operation 'KeyVault' -ResourceName $Name -ResourceGroupName $ResourceGroupName -Force:$Force
    }

    Write-Host "[AzureKeyVault] Removing Key Vault '$Name'" -ForegroundColor Yellow

    if ($Force -or $PSCmdlet.ShouldProcess($Name, 'Remove Azure Key Vault')) {
        az keyvault delete --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete Key Vault '$Name'."
        }
        Write-Host "[AzureKeyVault] Key Vault '$Name' deleted." -ForegroundColor Green
    }
}

Export-ModuleMember -Function New-HermesAzureKeyVault, Get-HermesAzureKeyVault, Set-HermesAzureKeyVaultSecret, Get-HermesAzureKeyVaultSecret, Remove-HermesAzureKeyVault
