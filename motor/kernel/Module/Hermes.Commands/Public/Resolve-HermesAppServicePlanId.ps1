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
    Definida en Private/AzureConfiguration.ps1
#>
# La implementación real está en Private/AzureConfiguration.ps1
# Este archivo existe para que el módulo exporte la función automáticamente.