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
.PARAMETER WhatIf
    Muestra qué pasaría si se ejecuta el comando.
.PARAMETER Confirm
    Solicita confirmación antes de ejecutar.
.EXAMPLE
    Set-HermesAzureConfiguration -Location "westus" -PassThru
.EXAMPLE
    Set-HermesAzureConfiguration -AppServicePlan "ASP-MiPlan" -ResourceGroupPlan "RG-MiGrupo"
.OUTPUTS
    PSCustomObject
.NOTES
    RC70-D: Migrado desde Private/AzureConfiguration.ps1 a Public/
#>
function Set-HermesAzureConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Location,

        [Parameter(Mandatory = $false)]
        [string]$ResourceGroupAplicaciones,

        [Parameter(Mandatory = $false)]
        [string]$ResourceGroupPlan,

        [Parameter(Mandatory = $false)]
        [string]$AppServicePlan,

        [Parameter(Mandatory = $false)]
        [string]$StorageAccount,

        [Parameter(Mandatory = $false)]
        [bool]$UseSharedInfrastructure,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # Read current config or use defaults
    $current = _Read-AzureConfiguration
    if (-not $current) {
        $current = [PSCustomObject]@{
            Location                  = 'eastus'
            ResourceGroupAplicaciones = 'RG-Hermes-Proyectos'
            ResourceGroupPlan         = 'RG-Datamining-SII2.0-Dev'
            AppServicePlan            = 'ASP-IAUR'
            StorageAccount            = 'saurhermesproyectos'
            UseSharedInfrastructure   = $true
        }
    }

    # Apply overrides
    if ($PSBoundParameters.ContainsKey('Location')) { $current.Location = $Location }
    if ($PSBoundParameters.ContainsKey('ResourceGroupAplicaciones')) { $current.ResourceGroupAplicaciones = $ResourceGroupAplicaciones }
    if ($PSBoundParameters.ContainsKey('ResourceGroupPlan')) { $current.ResourceGroupPlan = $ResourceGroupPlan }
    if ($PSBoundParameters.ContainsKey('AppServicePlan')) { $current.AppServicePlan = $AppServicePlan }
    if ($PSBoundParameters.ContainsKey('StorageAccount')) { $current.StorageAccount = $StorageAccount }
    if ($PSBoundParameters.ContainsKey('UseSharedInfrastructure')) { $current.UseSharedInfrastructure = $UseSharedInfrastructure }

    if ($PSCmdlet.ShouldProcess("Azure configuration", "Set configuration values")) {
        _Save-AzureConfiguration -Configuration $current
        Write-Verbose "[Hermes] Azure configuration updated"

        if ($PassThru) {
            return $current
        }
    }
}