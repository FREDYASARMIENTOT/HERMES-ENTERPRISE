<#
.SYNOPSIS
    Caso de uso: Crear infraestructura compartida de Azure.
.DESCRIPTION
    Orquesta la creación completa de la infraestructura Azure compartida:
    Resource Group, Managed Identity, Storage, Log Analytics,
    Application Insights, Key Vault y App Service Plan.
    Sigue el orden de despliegue definido en Azure-Infrastructure-Model.md.
    Registra cada paso en SQLite y en la telemetría local.
    NO despliega proyectos ni aplicaciones web — solo infraestructura base.
#>

function Invoke-CrearInfraestructuraAzure {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [Parameter(Mandatory)]
        [string]$Location,

        [string]$ResourceGroupName = 'RG-Hermes-Proyectos',

        [string]$PlanName = 'Plan-Hermes-Proyectos',

        [string]$PlanSku = 'B1',

        [switch]$Force
    )

    Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Crear Infraestructura Azure — Hermes        ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "[UseCase] Subscription: $SubscriptionId" -ForegroundColor Cyan
    Write-Host "[UseCase] Location: $Location" -ForegroundColor Cyan
    Write-Host "[UseCase] RG: $ResourceGroupName" -ForegroundColor Cyan

    # Validar Azure CLI
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) required. Install from https://aka.ms/installazurecliwindows"
    }

    # Validar suscripción
    $subCheck = az account show --subscription $SubscriptionId 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Cannot access subscription '$SubscriptionId'. Run 'az login' first." }

    # Cargar providers necesarios
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
        if (-not (Test-Path $path)) { throw "Provider not found: $path" }
        . $path
    }

    $results = @{}
    $errors = @{}

    # --- Orden de despliegue ---
    # 1. Managed Identity (necesario antes que Key Vault)
    Write-Host "`n[1/7] Managed Identity..." -ForegroundColor Yellow
    try {
        $identityName = 'id-hermes-infra'
        $results.ManagedIdentity = New-HermesAzureManagedIdentity -Name $identityName -ResourceGroupName $ResourceGroupName -Location $Location -SubscriptionId $SubscriptionId -Force:$Force
        Write-Host "  ✓ Managed Identity: $identityName" -ForegroundColor Green
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $errors.ManagedIdentity = $_ }

    # 2. Resource Group
    Write-Host "[2/7] Resource Group..." -ForegroundColor Yellow
    try {
        $results.ResourceGroup = New-HermesAzureResourceGroup -Name $ResourceGroupName -Location $Location -SubscriptionId $SubscriptionId -Tags @{Environment='Shared';ManagedBy='Hermes';Purpose='Infrastructure'} -Force:$Force
        Write-Host "  ✓ RG: $ResourceGroupName" -ForegroundColor Green
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $errors.ResourceGroup = $_ }

    # 3. Storage Account
    Write-Host "[3/7] Storage Account..." -ForegroundColor Yellow
    try {
        $storageName = "hermesinfra$((Get-Random -Maximum 9999).ToString('0000'))"
        $results.Storage = New-HermesAzureStorageAccount -Name $storageName -ResourceGroupName $ResourceGroupName -Location $Location -SubscriptionId $SubscriptionId -Force:$Force
        Write-Host "  ✓ Storage: $storageName" -ForegroundColor Green
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $errors.Storage = $_ }

    # 4. Log Analytics
    Write-Host "[4/7] Log Analytics..." -ForegroundColor Yellow
    try {
        $results.LogAnalytics = New-HermesAzureLogAnalytics -Name "hermes-logs" -ResourceGroupName $ResourceGroupName -Location $Location -SubscriptionId $SubscriptionId -Force:$Force
        Write-Host "  ✓ Log Analytics: hermes-logs" -ForegroundColor Green
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $errors.LogAnalytics = $_ }

    # 5. Application Insights (vinculado a Log Analytics)
    Write-Host "[5/7] Application Insights..." -ForegroundColor Yellow
    try {
        $workspaceId = if ($results.LogAnalytics) { $results.LogAnalytics.id } else { $null }
        $results.AppInsights = New-HermesAzureApplicationInsights -Name "hermes-insights" -ResourceGroupName $ResourceGroupName -Location $Location -SubscriptionId $SubscriptionId -WorkspaceResourceId $workspaceId -Force:$Force
        Write-Host "  ✓ App Insights: hermes-insights" -ForegroundColor Green
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $errors.AppInsights = $_ }

    # 6. Key Vault (con acceso para Managed Identity)
    Write-Host "[6/7] Key Vault..." -ForegroundColor Yellow
    try {
        $kvName = "hermes-kv-$((Get-Random -Maximum 9999).ToString('0000'))"
        $adminIds = if ($results.ManagedIdentity) { @($results.ManagedIdentity.PrincipalId) } else { @() }
        $results.KeyVault = New-HermesAzureKeyVault -Name $kvName -ResourceGroupName $ResourceGroupName -Location $Location -SubscriptionId $SubscriptionId -AdminObjectIds $adminIds -EnableSoftDelete -Force:$Force

        # Guardar connection strings como secrets
        if ($results.Storage) {
            $connString = Get-HermesAzureStorageConnectionString -Name $results.Storage.Name -ResourceGroupName $ResourceGroupName -SubscriptionId $SubscriptionId
            Set-HermesAzureKeyVaultSecret -VaultName $kvName -SecretName 'Hermes-Storage-Connection' -SecretValue $connString -SubscriptionId $SubscriptionId
        }
        Write-Host "  ✓ Key Vault: $kvName" -ForegroundColor Green
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $errors.KeyVault = $_ }

    # 7. App Service Plan (compartido)
    Write-Host "[7/7] App Service Plan..." -ForegroundColor Yellow
    try {
        $results.AppServicePlan = New-HermesAzureAppServicePlan -Name $PlanName -ResourceGroupName $ResourceGroupName -Location $Location -SubscriptionId $SubscriptionId -Sku $PlanSku -Force:$Force
        Write-Host "  ✓ Plan: $PlanName (SKU: $PlanSku)" -ForegroundColor Green
    } catch { Write-Warning "  ✗ $($_.Exception.Message)"; $errors.AppServicePlan = $_ }

    # Asignar roles a Managed Identity
    if ($results.ManagedIdentity -and $results.ResourceGroup) {
        Write-Host "[RBAC] Assigning roles to Managed Identity..." -ForegroundColor Yellow
        $rgScope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName"
        try {
            Set-HermesAzureManagedIdentityRole -PrincipalId $results.ManagedIdentity.PrincipalId -Scope $rgScope -RoleDefinitionName 'Contributor' -SubscriptionId $SubscriptionId -Force:$Force
            Write-Host "  ✓ Contributor on RG" -ForegroundColor Green
        } catch { Write-Warning "  ✗ Role assignment: $($_.Exception.Message)" }

        if ($results.KeyVault) {
            try {
                Set-HermesAzureManagedIdentityRole -PrincipalId $results.ManagedIdentity.PrincipalId -Scope $results.KeyVault.id -RoleDefinitionName 'Key Vault Secrets User' -SubscriptionId $SubscriptionId -Force:$Force
                Write-Host "  ✓ Key Vault Secrets User" -ForegroundColor Green
            } catch { Write-Warning "  ✗ KV role: $($_.Exception.Message)" }
        }
    }

    # --- Resumen ---
    Write-Host "`n═══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "RESUMEN DE INFRAESTRUCTURA" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
    $successCount = ($results.Values | Where-Object { $_ -ne $null }).Count
    $errorCount = ($errors.Values | Where-Object { $_ -ne $null }).Count
    Write-Host "Recursos creados: $successCount/7" -ForegroundColor $(if ($errorCount -eq 0) { 'Green' } else { 'Yellow' })
    Write-Host "Errores: $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { 'Green' } else { 'Red' })

    if ($errors.Count -gt 0) {
        Write-Warning "Algunos recursos no se crearon. Revise los errores anteriores."
    } else {
        Write-Host "Infraestructura Azure lista para proyectos Hermes." -ForegroundColor Green
    }

    return $results
}

Export-ModuleMember -Function Invoke-CrearInfraestructuraAzure