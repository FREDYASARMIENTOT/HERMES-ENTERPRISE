<#
.SYNOPSIS
    Caso de uso: Exportar reporte de infraestructura Azure.
.DESCRIPTION
    Genera un reporte detallado del estado de la infraestructura Azure
    en formato JSON o Markdown. Incluye:
    - Estado de cada recurso (✓/✗)
    - Nombres, ubicaciones, SKUs
    - Connection strings (ofuscados) y endpoints
    - Timestamp y estado general (Healthy/Degraded)
    El reporte puede usarse para auditoría o integración CI/CD.
#>

function Invoke-ExportarReporteInfraestructuraAzure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [string]$ResourceGroupName = 'RG-Hermes-Proyectos',

        [ValidateSet('JSON','Markdown')]
        [string]$Format = 'JSON',

        [string]$OutputPath
    )

    Write-Host "[UseCase] Exporting Azure infrastructure report ($Format)" -ForegroundColor Cyan

    # Obtener estado actual
    $check = Invoke-VerificarInfraestructuraAzure -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName

    # Construir reporte detallado
    $report = [PSCustomObject]@{
        ReportMetadata = @{
            Title           = 'Azure Infrastructure Health Report'
            GeneratedAt     = $check.Timestamp
            OverallStatus   = $check.Status
            SubscriptionId  = $SubscriptionId
            ResourceGroup   = $ResourceGroupName
            HermesVersion   = 'RC68'
        }
        Resources = [PSCustomObject]@{
            ResourceGroup   = @{ Name = $ResourceGroupName; Status = $check.ResourceGroup }
            ManagedIdentity = @{ Name = 'id-hermes-infra'; Status = $check.ManagedIdentity }
            StorageAccount  = @{ Name = 'hermesinfra-*'; Status = $check.Storage }
            LogAnalytics    = @{ Name = 'hermes-logs'; Status = $check.LogAnalytics }
            AppInsights     = @{ Name = 'hermes-insights'; Status = $check.AppInsights }
            KeyVault        = @{ Name = 'hermes-kv-*'; Status = $check.KeyVault }
            AppServicePlan  = @{ Name = 'Plan-Hermes-Proyectos'; Status = $check.AppServicePlan }
        }
        Recommendations = @()
    }

    # Generar recomendaciones según estado
    $check.PSObject.Properties | Where-Object { $_.Name -notin @('Timestamp','Status') } | ForEach-Object {
        if ($_.Value -like '✗*' -or $_.Value -like '*Error*') {
            $report.Recommendations += "Recreate $($_.Name): resource is missing or errored"
        }
    }

    if ($report.Recommendations.Count -eq 0) {
        $report.Recommendations += 'All resources healthy — no action required'
    }

    # Exportar
    if (-not $OutputPath) {
        $date = (Get-Date).ToString('yyyyMMdd-HHmmss')
        $OutputPath = Join-Path (Get-Location) "azure-infrastructure-report-$date.$($Format.ToLower())"
    }

    if ($Format -eq 'JSON') {
        $jsonContent = $report | ConvertTo-Json -Depth 5
        $jsonContent | Out-File -FilePath $OutputPath -Encoding utf8
    }
    else {
        # Markdown
        $md = @"
# Azure Infrastructure Health Report

**Generated:** $($report.ReportMetadata.GeneratedAt)
**Status:** $($report.ReportMetadata.OverallStatus)
**Subscription:** $($report.ReportMetadata.SubscriptionId)
**Resource Group:** $($report.ReportMetadata.ResourceGroup)

## Resource Status

| Resource | Name | Status |
|----------|------|--------|
| Resource Group | $($report.Resources.ResourceGroup.Name) | $($report.Resources.ResourceGroup.Status) |
| Managed Identity | $($report.Resources.ManagedIdentity.Name) | $($report.Resources.ManagedIdentity.Status) |
| Storage Account | $($report.Resources.StorageAccount.Name) | $($report.Resources.StorageAccount.Status) |
| Log Analytics | $($report.Resources.LogAnalytics.Name) | $($report.Resources.LogAnalytics.Status) |
| Application Insights | $($report.Resources.AppInsights.Name) | $($report.Resources.AppInsights.Status) |
| Key Vault | $($report.Resources.KeyVault.Name) | $($report.Resources.KeyVault.Status) |
| App Service Plan | $($report.Resources.AppServicePlan.Name) | $($report.Resources.AppServicePlan.Status) |

## Recommendations

$(for ($i=0; $i -lt $report.Recommendations.Count; $i++) { "$($i+1). $($report.Recommendations[$i])`n" })
"@
        $md | Out-File -FilePath $OutputPath -Encoding utf8
    }

    Write-Host "[UseCase] Report exported to: $OutputPath" -ForegroundColor Green

    return @{
        Path     = $OutputPath
        Format   = $Format
        Status   = $report.ReportMetadata.OverallStatus
        ResourceCount = 7
    }
}

Export-ModuleMember -Function Invoke-ExportarReporteInfraestructuraAzure