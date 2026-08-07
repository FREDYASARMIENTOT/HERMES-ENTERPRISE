<#
.SYNOPSIS
    Provision Azure Resource Groups
.DESCRIPTION
    Provider for creating and managing Azure Resource Groups.
    Uses 'az group' CLI commands with idempotent create-or-update semantics.
#>

function New-HermesAzureResourceGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Location,

        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [hashtable]$Tags = @{},

        [switch]$Force
    )

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) not found. Install it first."
    }

    $rgExists = az group exists --name $Name --subscription $SubscriptionId 2>$null
    if ($rgExists -eq 'true' -and -not $Force) {
        Write-Warning "Resource group '$Name' already exists. Use -Force to update tags."
        return Get-HermesAzureResourceGroup -Name $Name -SubscriptionId $SubscriptionId
    }

    $tagArgs = @()
    foreach ($kv in $Tags.GetEnumerator()) {
        $tagArgs += "$($kv.Key)=$($kv.Value)"
    }
    $tagStr = if ($tagArgs.Count -gt 0) { "--tags $($tagArgs -join ' ')" } else { '' }

    $result = az group create `
        --name $Name `
        --location $Location `
        --subscription $SubscriptionId `
        $tagStr `
        2>&1 | Out-String

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create resource group: $result"
    }

    return [PSCustomObject]@{
        Name           = $Name
        Location       = $Location
        SubscriptionId = $SubscriptionId
        ProvisioningState = 'Succeeded'
        Tags           = $Tags
    }
}

function Get-HermesAzureResourceGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )

    $result = az group show --name $Name --subscription $SubscriptionId 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Resource group '$Name' not found."
        return $null
    }

    return [PSCustomObject]@{
        Name           = $result.name
        Location       = $result.location
        SubscriptionId = $SubscriptionId
        ProvisioningState = $result.properties.provisioningState
        Tags           = $result.tags
    }
}

function Remove-HermesAzureResourceGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [switch]$Force
    )

    # ── Guardian validation ───────────────────────────────────────────────
    $guardianPath = Join-Path $PSScriptRoot '..\..\Security\AzureInfrastructureGuardian.ps1'
    if (Test-Path $guardianPath) {
        . $guardianPath
        Invoke-InfrastructureGuardian -Operation 'ResourceGroup' -ResourceName $Name -ResourceGroupName $Name -Force:$Force
    }

    if ($Force -or $PSCmdlet.ShouldProcess($Name, 'Remove Azure Resource Group')) {
        $confirm = if ($Force) { '--yes' } else { '' }
        az group delete --name $Name --subscription $SubscriptionId $confirm --no-wait 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete resource group '$Name'."
        }
        Write-Host "[Azure] Resource group '$Name' deletion initiated (async)."
    }
}

Export-ModuleMember -Function New-HermesAzureResourceGroup, Get-HermesAzureResourceGroup, Remove-HermesAzureResourceGroup
