<#
.SYNOPSIS
    Resuelve el ResourceId de un App Service Plan existente en Azure.
.DESCRIPTION
    Ejecuta 'az appservice plan show' para obtener el ResourceId del
    App Service Plan. Usa exclusivamente los valores de ResourceGroupPlan
    y AppServicePlan de la configuración.

    Hermes NO descubre planes. NO lista recursos. NO explora Azure.

    Requiere Azure CLI autenticado (az login).
.PARAMETER ResourceGroupPlan
    Nombre del Resource Group donde reside el App Service Plan.
.PARAMETER AppServicePlan
    Nombre del App Service Plan.
.EXAMPLE
    Resolve-HermesAppServicePlanId -ResourceGroupPlan "RG-Datamining-SII2.0-Dev" -AppServicePlan "ASP-IAUR"
.OUTPUTS
    string
.NOTES
    RC70-D: Migrado desde Private/AzureConfiguration.ps1 a Public/
#>
function Resolve-HermesAppServicePlanId {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupPlan,

        [Parameter(Mandatory = $true)]
        [string]$AppServicePlan
    )

    Write-Host "[..] Resolving App Service Plan ResourceId..." -ForegroundColor Yellow
    Write-Host "     Resource Group: $ResourceGroupPlan" -ForegroundColor Gray
    Write-Host "     Plan Name     : $AppServicePlan" -ForegroundColor Gray

    try {
        $result = & az appservice plan show `
            --resource-group $ResourceGroupPlan `
            --name $AppServicePlan `
            --query id `
            --output tsv 2>&1

        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($result)) {
            Write-Error "Failed to resolve App Service Plan '$AppServicePlan' in resource group '$ResourceGroupPlan'. Verify the plan exists and you have permission to access it."
            Write-Host "     az exit code: $LASTEXITCODE" -ForegroundColor Red
            Write-Host "     az output   : $result" -ForegroundColor Red
            return $null
        }

        $resourceId = $result.Trim()
        Write-Host "[OK] ResourceId: $resourceId" -ForegroundColor Green
        return $resourceId
    }
    catch {
        Write-Error "Failed to resolve App Service Plan ResourceId: $_"
        return $null
    }
}