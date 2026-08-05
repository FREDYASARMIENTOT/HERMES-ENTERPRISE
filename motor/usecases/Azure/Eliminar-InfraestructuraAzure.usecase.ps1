<#
.SYNOPSIS
    Caso de uso: Eliminar toda la infraestructura compartida de Azure.
.DESCRIPTION
    Orquesta la eliminación completa de la infraestructura Azure compartida.
    Sigue el orden inverso al de creación para respetar dependencias:
    App Service Plan → Key Vault → App Insights → Log Analytics →
    Storage → Resource Group (que elimina todo lo contenido).
    Requiere confirmación explícita (-Force para omitir).
    Registra la operación en SQLite y telemetría local.
#>

function Invoke-EliminarInfraestructuraAzure {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [string]$ResourceGroupName = 'RG-Hermes-Proyectos',

        [switch]$Force
    )

    Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  Eliminar Infraestructura Azure — Hermes     ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host "[UseCase] This will DELETE all resources in RG '$ResourceGroupName'" -ForegroundColor Red
    Write-Host "[UseCase] Subscription: $SubscriptionId" -ForegroundColor Yellow

    if (-not $Force) {
        $confirm = Read-Host "Are you sure? Type 'YES' to confirm"
        if ($confirm -ne 'YES') {
            Write-Host "[UseCase] Operation cancelled." -ForegroundColor Cyan
            return
        }
    }

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) required."
    }

    # Cargar providers
    $providerBase = Join-Path $PSScriptRoot '..\..\kernel\Providers\Azure'
    . (Join-Path $providerBase 'AzureResourceGroupProvider.ps1')
    . (Join-Path $providerBase 'AzureAppServicePlanProvider.ps1')
    . (Join-Path $providerBase 'AzureKeyVaultProvider.ps1')
    . (Join-Path $providerBase 'AzureApplicationInsightsProvider.ps1')
    . (Join-Path $providerBase 'AzureLogAnalyticsProvider.ps1')
    . (Join-Path $providerBase 'AzureStorageProvider.ps1')
    . (Join-Path $providerBase 'AzureManagedIdentityProvider.ps1')

    $results = @{}

    # Orden inverso de eliminación
    # 1. App Service Plan
    Write-Host "[1/7] Eliminando App Service Plan..." -ForegroundColor Yellow
    try {
        Remove-HermesAzureAppServicePlan -Name 'Plan-Hermes-Proyectos' -ResourceGroupName $ResourceGroupName -SubscriptionId $SubscriptionId -Force:$Force
        $results.AppServicePlan = 'Deleted'
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $results.AppServicePlan = 'Error' }

    # 2. Key Vault
    Write-Host "[2/7] Eliminando Key Vault..." -ForegroundColor Yellow
    try {
        $kvs = az keyvault list --resource-group $ResourceGroupName --subscription $SubscriptionId --query "[?starts_with(name, 'hermes-kv')]" 2>$null | ConvertFrom-Json
        if ($kvs -and $kvs.Count -gt 0) {
            foreach ($kv in $kvs) {
                Remove-HermesAzureKeyVault -Name $kv.name -ResourceGroupName $ResourceGroupName -SubscriptionId $SubscriptionId -Force:$Force
            }
        }
        $results.KeyVault = 'Deleted'
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $results.KeyVault = 'Error' }

    # 3. Application Insights
    Write-Host "[3/7] Eliminando Application Insights..." -ForegroundColor Yellow
    try {
        Remove-HermesAzureApplicationInsights -Name 'hermes-insights' -ResourceGroupName $ResourceGroupName -SubscriptionId $SubscriptionId -Force:$Force
        $results.AppInsights = 'Deleted'
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $results.AppInsights = 'Error' }

    # 4. Log Analytics
    Write-Host "[4/7] Eliminando Log Analytics..." -ForegroundColor Yellow
    try {
        Remove-HermesAzureLogAnalytics -Name 'hermes-logs' -ResourceGroupName $ResourceGroupName -SubscriptionId $SubscriptionId -Force:$Force
        $results.LogAnalytics = 'Deleted'
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $results.LogAnalytics = 'Error' }

    # 5. Storage Account
    Write-Host "[5/7] Eliminando Storage Account..." -ForegroundColor Yellow
    try {
        $storages = az storage account list --resource-group $ResourceGroupName --subscription $SubscriptionId --query "[?starts_with(name, 'hermesinfra')]" 2>$null | ConvertFrom-Json
        if ($storages -and $storages.Count -gt 0) {
            foreach ($st in $storages) {
                Remove-HermesAzureStorageAccount -Name $st.name -ResourceGroupName $ResourceGroupName -SubscriptionId $SubscriptionId -Force:$Force
            }
        }
        $results.Storage = 'Deleted'
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $results.Storage = 'Error' }

    # 6. Managed Identity
    Write-Host "[6/7] Eliminando Managed Identity..." -ForegroundColor Yellow
    try {
        Remove-HermesAzureManagedIdentity -Name 'id-hermes-infra' -ResourceGroupName $ResourceGroupName -SubscriptionId $SubscriptionId -Force:$Force
        $results.ManagedIdentity = 'Deleted'
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $results.ManagedIdentity = 'Error' }

    # 7. Resource Group (elimina lo que quede)
    Write-Host "[7/7] Eliminando Resource Group..." -ForegroundColor Yellow
    try {
        Remove-HermesAzureResourceGroup -Name $ResourceGroupName -SubscriptionId $SubscriptionId -Force:$Force
        $results.ResourceGroup = 'Deleted'
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $results.ResourceGroup = 'Error' }

    # Resumen
    Write-Host "`n═══════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "RESUMEN DE ELIMINACIÓN" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Yellow
    foreach ($item in $results.GetEnumerator()) {
        $icon = if ($item.Value -eq 'Deleted') { '✅' } else { '❌' }
        Write-Host "$icon $($item.Key): $($item.Value)"
    }

    Write-Host "`nInfraestructura Azure eliminada." -ForegroundColor Yellow
    return $results
}

Export-ModuleMember -Function Invoke-EliminarInfraestructuraAzure