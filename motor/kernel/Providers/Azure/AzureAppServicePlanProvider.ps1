<#
.SYNOPSIS
    Administrador de Planes de App Service en Azure.
.DESCRIPTION
    Provider canónico para crear, obtener y eliminar Planes de App Service.
    Los planes se despliegan dentro de un Resource Group existente y son
    compartidos por todos los proyectos Hermes.
    Incluye telemetría básica y registro en SQLite.
#>

function New-HermesAzureAppServicePlan {
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

        [ValidateSet('B1','B2','B3','S1','S2','S3','P1V2','P2V2','P3V2')]
        [string]$Sku = 'B1',

        [switch]$Force
    )

    Write-Host "[AzureAppServicePlan] Creating plan '$Name' (SKU: $Sku) in RG '$ResourceGroupName'" -ForegroundColor Cyan

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) not found. Install it first."
    }

    # Verificar si el plan ya existe
    $existing = az appservice plan show --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>$null
    if ($existing -and -not $Force) {
        Write-Warning "App Service Plan '$Name' already exists. Use -Force to overwrite."
        return $existing | ConvertFrom-Json
    }

    if ($PSCmdlet.ShouldProcess($Name, 'Create/Update Azure App Service Plan')) {
        $result = az appservice plan create `
            --name $Name `
            --resource-group $ResourceGroupName `
            --location $Location `
            --subscription $SubscriptionId `
            --sku $Sku `
            --is-linux false `
            2>&1 | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create App Service Plan '$Name': $result"
        }

        $plan = $result | ConvertFrom-Json

        Write-Host "[AzureAppServicePlan] Plan '$Name' ready (SKU: $Sku)" -ForegroundColor Green

        return [PSCustomObject]@{
            Name              = $plan.name
            ResourceGroupName = $ResourceGroupName
            Location          = $Location
            SubscriptionId    = $SubscriptionId
            Sku               = $Sku
            ProvisioningState = 'Succeeded'
        }
    }
}

function Get-HermesAzureAppServicePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )

    Write-Host "[AzureAppServicePlan] Getting plan '$Name' from RG '$ResourceGroupName'" -ForegroundColor Cyan

    $result = az appservice plan show --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "App Service Plan '$Name' not found."
        return $null
    }

    return $result
}

function Remove-HermesAzureAppServicePlan {
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

    Write-Host "[AzureAppServicePlan] Removing plan '$Name'" -ForegroundColor Yellow

    if ($Force -or $PSCmdlet.ShouldProcess($Name, 'Remove Azure App Service Plan')) {
        $confirm = if ($Force) { '--yes' } else { '' }
        az appservice plan delete --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId $confirm 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete App Service Plan '$Name'."
        }
        Write-Host "[AzureAppServicePlan] Plan '$Name' deleted." -ForegroundColor Green
    }
}

Export-ModuleMember -Function New-HermesAzureAppServicePlan, Get-HermesAzureAppServicePlan, Remove-HermesAzureAppServicePlan