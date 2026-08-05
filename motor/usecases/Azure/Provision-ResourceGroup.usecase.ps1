<#
.SYNOPSIS
    Use case: Provision an Azure Resource Group
.DESCRIPTION
    Validates inputs, checks Azure CLI, delegates to provider layer for RG creation.
#>

function Invoke-ProvisionResourceGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$ResourceGroupName,
        [Parameter(Mandatory)] [string]$Location,
        [Parameter(Mandatory)] [string]$SubscriptionId,
        [hashtable]$Tags = @{ Environment = 'production'; ManagedBy = 'Hermes' },
        [switch]$Force
    )

    Write-Host "[UseCase] Provision-ResourceGroup: $ResourceGroupName @ $Location" -ForegroundColor Cyan

    $providerPath = Join-Path $PSScriptRoot '..\..\kernel\Providers\Azure\AzureResourceGroupProvider.ps1'
    if (-not (Test-Path $providerPath)) { throw "Azure provider not found at: $providerPath" }
    . $providerPath

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) required. Install from https://aka.ms/installazurecliwindows"
    }

    $subCheck = az account show --subscription $SubscriptionId 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Cannot access subscription '$SubscriptionId'. Run 'az login' first." }

    $result = New-HermesAzureResourceGroup -Name $ResourceGroupName -Location $Location `
        -SubscriptionId $SubscriptionId -Tags $Tags -Force:$Force

    if ($result) { Write-Host "[UseCase] Resource group '$ResourceGroupName' ready." -ForegroundColor Green }
    return $result
}

Export-ModuleMember -Function Invoke-ProvisionResourceGroup