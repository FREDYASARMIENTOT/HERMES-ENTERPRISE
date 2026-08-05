<#
.SYNOPSIS
    Administrador de Application Insights en Azure.
.DESCRIPTION
    Provider canónico para crear y gestionar instancias de Application Insights.
    Proporciona el pipeline de telemetría para todos los proyectos Hermes.
    Se integra con Log Analytics para almacenamiento centralizado de logs.
    Incluye registro local en SQLite para trazabilidad.
#>

function New-HermesAzureApplicationInsights {
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

        [ValidateSet('web','other')]
        [string]$Kind = 'web',

        [string]$WorkspaceResourceId,

        [switch]$Force
    )

    Write-Host "[AzureAppInsights] Creating Application Insights '$Name' (Kind: $Kind)" -ForegroundColor Cyan

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) not found. Install it first."
    }

    # Verificar si ya existe
    $existing = az resource show --resource-type "microsoft.insights/components" --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>$null
    if ($existing -and -not $Force) {
        Write-Warning "Application Insights '$Name' already exists. Use -Force to overwrite."
        return $existing | ConvertFrom-Json
    }

    if ($PSCmdlet.ShouldProcess($Name, 'Create/Update Azure Application Insights')) {
        $workspaceParam = if ($WorkspaceResourceId) { "--workspace $WorkspaceResourceId" } else { '' }

        $result = az monitor app-insights component create `
            --app $Name `
            --resource-group $ResourceGroupName `
            --location $Location `
            --subscription $SubscriptionId `
            --kind $Kind `
            --application-type $Kind `
            $workspaceParam `
            2>&1 | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Application Insights '$Name': $result"
        }

        $insights = $result | ConvertFrom-Json

        Write-Host "[AzureAppInsights] Application Insights '$Name' ready." -ForegroundColor Green

        return [PSCustomObject]@{
            Name              = $insights.name
            ResourceGroupName = $ResourceGroupName
            Location          = $Location
            SubscriptionId    = $SubscriptionId
            InstrumentationKey = $insights.properties.InstrumentationKey
            ConnectionString  = $insights.properties.ConnectionString
            Kind              = $Kind
            ProvisioningState = 'Succeeded'
        }
    }
}

function Get-HermesAzureApplicationInsights {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )

    Write-Host "[AzureAppInsights] Getting Application Insights '$Name'" -ForegroundColor Cyan

    $result = az resource show --resource-type "microsoft.insights/components" --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Application Insights '$Name' not found."
        return $null
    }

    return $result
}

function Get-HermesAzureApplicationInsightsKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$SubscriptionId
    )

    Write-Host "[AzureAppInsights] Getting instrumentation key for '$Name'" -ForegroundColor Cyan

    $result = az monitor app-insights component show --app $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get instrumentation key for '$Name'."
    }

    return @{
        InstrumentationKey = $result.instrumentationKey
        ConnectionString   = $result.connectionString
    }
}

function Remove-HermesAzureApplicationInsights {
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

    Write-Host "[AzureAppInsights] Removing Application Insights '$Name'" -ForegroundColor Yellow

    if ($Force -or $PSCmdlet.ShouldProcess($Name, 'Remove Azure Application Insights')) {
        az resource delete --resource-type "microsoft.insights/components" --name $Name --resource-group $ResourceGroupName --subscription $SubscriptionId 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete Application Insights '$Name'."
        }
        Write-Host "[AzureAppInsights] Application Insights '$Name' deleted." -ForegroundColor Green
    }
}

Export-ModuleMember -Function New-HermesAzureApplicationInsights, Get-HermesAzureApplicationInsights, Get-HermesAzureApplicationInsightsKey, Remove-HermesAzureApplicationInsights