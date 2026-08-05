<#
.SYNOPSIS
    Establece la configuración canónica de infraestructura Azure compartida.
.DESCRIPTION
    Escribe o sobrescribe Hermes.Azure.json con los valores especificados.
    Todos los parámetros tienen valores por defecto.

    Si no se especifica un parámetro, se conserva el valor actual si existe,
    o se usa el valor por defecto.
.PARAMETER Location
    Región Azure (default: eastus).
.PARAMETER ResourceGroupAplicaciones
    Resource Group para Web Apps (default: RG-Hermes-Proyectos).
.PARAMETER ResourceGroupPlan
    Resource Group del App Service Plan (default: RG-Datamining-SII2.0-Dev).
.PARAMETER AppServicePlan
    Nombre del App Service Plan (default: ASP-IAUR).
.PARAMETER StorageAccount
    Cuenta de almacenamiento (default: saurhermesproyectos).
.PARAMETER UseSharedInfrastructure
    Usar infraestructura compartida (default: true).
.PARAMETER PassThru
    Retorna el objeto de configuración después de guardar.
.EXAMPLE
    Set-HermesAzureConfiguration -Location "westus" -PassThru
.EXAMPLE
    Set-HermesAzureConfiguration -AppServicePlan "ASP-MiPlan" -ResourceGroupPlan "RG-MiGrupo"
.OUTPUTS
    PSCustomObject
.NOTES
    Definida en Private/AzureConfiguration.ps1
#>
# La implementación real está en Private/AzureConfiguration.ps1
# Este archivo existe para que el módulo exporte la función automáticamente.