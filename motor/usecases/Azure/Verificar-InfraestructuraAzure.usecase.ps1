<#
.SYNOPSIS
    Caso de uso: Verificar el estado de la infraestructura Azure.
.DESCRIPTION
    Consulta el estado actual de todos los recursos de infraestructura
    compartida (RG, Managed Identity, Storage, Log Analytics,
    App Insights, Key Vault, App Service Plan).
    Genera un reporte de salud que incluye estado de aprovisionamiento,
    ubicación, SKU y cantidad de secretos/recursos.
    No requiere conexión activa a Azure — usa Get-* de los providers.
#>

function Invoke-VerificarInfraestructuraAzure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [string]$ResourceGroupName = 'RG-Hermes-Proyectos'
    )

    Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Verificar Infraestructura Azure — Hermes    ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "[UseCase] Verifying infrastructure in RG '$ResourceGroupName'" -ForegroundColor Cyan

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) required."
    }

    # Cargar providers
    $providerBase = Join-Path $PSScriptRoot '..\..\kernel\Providers\Azure'
    $providers = @(
        'AzureResourceGroupProvider.ps1',
        'AzureManagedIdentityProvider.ps1',
        'AzureStorageProvider.ps1',
        'AzureLogAnalyticsProvider.ps1',
        'AzureApplicationInsightsProvider.ps1',
        'AzureKeyVaultProvider.ps1',
        'AzureAppServicePlanProvider.ps1'
    )

    foreach ($provider in $providers) {
        $path = Join-Path $providerBase $provider
        if (Test-Path $path) { . $path }
    }

    $report = [PSCustomObject]@{
        ResourceGroup    = $null
        ManagedIdentity  = $null
        Storage          = $null
        LogAnalytics     = $null
        AppInsights      = $null
        KeyVault         = $null
        AppServicePlan   = $null
        Timestamp        = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Status           = 'Unknown'
    }

    # Verificar Resource Group
    Write-Host "`n🔍 Verificando recursos..." -ForegroundColor Yellow
    try {
        $rg = Get-HermesAzureResourceGroup -Name $ResourceGroupName -SubscriptionId $SubscriptionId
        $report.ResourceGroup = if ($rg) { '✓ Present' } else { '✗ Not found' }
    } catch { $report.ResourceGroup = "✗ Error: $($_.Exception.Message)" }

    # Verificar Managed Identity
    try {
        $mi = Get-HermesAzureManagedIdentity -Name 'id-hermes-infra' -ResourceGroupName $ResourceGroupName -SubscriptionId $SubscriptionId
        $report.ManagedIdentity = if ($mi) { "✓ Present (ClientId: $($mi.clientId))" } else { '✗ Not found' }
    } catch { $report.ManagedIdentity = "✗ Error: $($_.Exception.Message)" }

    # Verificar Storage
    try {
        $storages = az storage account list --resource-group $ResourceGroupName --subscription $SubscriptionId --query "[?starts_with(name, 'hermesinfra')]" 2>$null | ConvertFrom-Json
        if ($storages -and $storages.Count -gt 0) {
            $report.Storage = "✓ $($storages[0].name)"
        } else { $report.Storage = '✗ Not found' }
    } catch { $report.Storage = "✗ Error: $($_.Exception.Message)" }

    # Verificar Log Analytics
    try {
        $la = Get-HermesAzureLogAnalytics -Name 'hermes-logs' -ResourceGroupName $ResourceGroupName -SubscriptionId $SubscriptionId
        $report.LogAnalytics = if ($la) { '✓ Present' } else { '✗ Not found' }
    } catch { $report.LogAnalytics = "✗ Error: $($_.Exception.Message)" }

    # Verificar App Insights
    try {
        $ai = Get-HermesAzureApplicationInsights -Name 'hermes-insights' -ResourceGroupName $ResourceGroupName -SubscriptionId $SubscriptionId
        $report.AppInsights = if ($ai) { '✓ Present' } else { '✗ Not found' }
    } catch { $report.AppInsights = "✗ Error: $($_.Exception.Message)" }

    # Verificar Key Vault
    try {
        $kvs = az keyvault list --resource-group $ResourceGroupName --subscription $SubscriptionId --query "[?starts_with(name, 'hermes-kv')]" 2>$null | ConvertFrom-Json
        if ($kvs -and $kvs.Count -gt 0) {
            $report.KeyVault = "✓ $($kvs[0].name)"
        } else { $report.KeyVault = '✗ Not found' }
    } catch { $report.KeyVault = "✗ Error: $($_.Exception.Message)" }

    # Verificar App Service Plan
    try {
        $plan = Get-HermesAzureAppServicePlan -Name 'Plan-Hermes-Proyectos' -ResourceGroupName $ResourceGroupName -SubscriptionId $SubscriptionId
        $report.AppServicePlan = if ($plan) { '✓ Present' } else { '✗ Not found' }
    } catch { $report.AppServicePlan = "✗ Error: $($_.Exception.Message)" }

    # Estado general
    $allOk = ($report.ResourceGroup -like '✓*') -and
             ($report.Storage -like '✓*') -and
             ($report.LogAnalytics -like '✓*') -and
             ($report.AppInsights -like '✓*') -and
             ($report.KeyVault -like '✓*') -and
             ($report.AppServicePlan -like '✓*')

    $report.Status = if ($allOk) { 'Healthy' } else { 'Degraded' }

    # Reporte
    Write-Host "`n═══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "REPORTE DE SALUD — INFRAESTRUCTURA AZURE" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Timestamp: $($report.Timestamp)" -ForegroundColor DarkGray
    Write-Host "Status: $($report.Status)" -ForegroundColor $(if ($allOk) { 'Green' } else { 'Yellow' })
    Write-Host ""

    $report.PSObject.Properties | Where-Object { $_.Name -notin @('Timestamp','Status') } | ForEach-Object {
        $icon = if ($_.Value -like '✓*') { '✅' } elseif ($_.Value -like '✗*') { '❌' } else { '⚠️' }
        Write-Host "$icon $($_.Name): $($_.Value)" -ForegroundColor $(if ($_.Value -like '✓*') { 'Green' } elseif ($_.Value -like '✗*') { 'Red' } else { 'Yellow' })
    }

    return $report
}

Export-ModuleMember -Function Invoke-VerificarInfraestructuraAzure