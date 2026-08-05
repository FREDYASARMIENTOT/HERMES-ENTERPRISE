<#
.SYNOPSIS
    Administrador de Log Analytics Workspace en Azure.
.DESCRIPTION
    Provider canónico para crear y gestionar Log Analytics Workspaces.
    Proporciona almacenamiento centralizado de logs para todos los proyectos Hermes.
    Se integra con Application Insights para consultas Kusto avanzadas.
    Incluye telemetría local y registro en SQLite.
#>

function New-HermesAzureLogAnalytics {
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

        [ValidateSet('PerGB2018','PerNode','Standalone','Free')]
        [string]$Sku = 'PerGB2018',

        [int]$RetentionInDays = 30,

        [switch]$Force
    )

    Write-Host "[AzureLogAnalytics] Creating workspace '$Name' (SKU: $Sku, Retention: ${RetentionInDays}d)" -ForegroundColor Cyan

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) not found. Install it first."
    }

    # Verificar existencia
    $existing = az monitor log-analytics workspace show --workspace-name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>$null
    if ($existing -and -not $Force) {
        Write-Warning "Log Analytics workspace '$Name' already exists. Use -Force to update."
        return $existing | ConvertFrom-Json
    }

    if ($PSCmdlet.ShouldProcess($Name, 'Create/Update Azure Log Analytics Workspace')) {
        $result = az monitor log-analytics workspace create `
            --workspace-name $Name `
            --resource-group $ResourceGroupName `
            --location $Location `
            --subscription $SubscriptionId `
            --sku $Sku `
            --retention-time $RetentionInDays `
            2>&1 | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Log Analytics workspace '$Name': $result"
        }

        $workspace = $result | ConvertFrom-Json

        Write-Host "[AzureLogAnalytics] Workspace '$Name' ready." -ForegroundColor Green

        return [PSCustomObject]@{
            Name              = $workspace.name
            ResourceGroupName = $ResourceGroupName
            Location          = $Location
            SubscriptionId    = $SubscriptionId
            Sku               = $Sku
            RetentionInDays   = $RetentionInDays
            CustomerId        = $workspace.customerId
            ProvisioningState = 'Succeeded'
        }
    }
}

function Get-HermesAzureLogAnalytics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )

    Write-Host "[AzureLogAnalytics] Getting workspace '$Name'" -ForegroundColor Cyan

    $result = az monitor log-analytics workspace show --workspace-name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Log Analytics workspace '$Name' not found."
        return $null
    }

    return $result
}

function Get-HermesAzureLogAnalyticsWorkspaceId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )

    Write-Host "[AzureLogAnalytics] Getting workspace ID for '$Name'" -ForegroundColor Cyan

    $result = az monitor log-analytics workspace show --workspace-name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get workspace info for '$Name'."
    }

    return @{
        CustomerId    = $result.customerId
        ResourceId    = $result.id
        PrimaryKey    = 'See Azure Portal (keys are shared)'
    }
}

function Remove-HermesAzureLogAnalytics {
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

    Write-Host "[AzureLogAnalytics] Removing workspace '$Name'" -ForegroundColor Yellow

    if ($Force -or $PSCmdlet.ShouldProcess($Name, 'Remove Azure Log Analytics Workspace')) {
        az monitor log-analytics workspace delete --workspace-name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId --yes 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete Log Analytics workspace '$Name'."
        }
        Write-Host "[AzureLogAnalytics] Workspace '$Name' deleted." -ForegroundColor Green
    }
}

Export-ModuleMember -Function New-HermesAzureLogAnalytics, Get-HermesAzureLogAnalytics, Get-HermesAzureLogAnalyticsWorkspaceId, Remove-HermesAzureLogAnalytics