<#
.SYNOPSIS
    Obtiene la configuración canónica de infraestructura Azure compartida.
.DESCRIPTION
    Lee Hermes.Azure.json y retorna un objeto con todos los parámetros
    de infraestructura Azure compartida.

    Hermes NO descubre recursos Azure. Únicamente lee configuración.
.PARAMETER Path
    Ruta opcional al archivo Hermes.Azure.json. Si no se especifica,
    se lee desde <ProjectRoot>/config/Hermes.Azure.json.
.EXAMPLE
    Get-HermesAzureConfiguration
.EXAMPLE
    Get-HermesAzureConfiguration -Path "C:\config\Hermes.Azure.json"
.OUTPUTS
    PSCustomObject
.NOTES
    RC70-D: Migrado desde Private/AzureConfiguration.ps1 a Public/
#>
function Get-HermesAzureConfiguration {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path
    )

    if ($Path) {
        if (-not (Test-Path $Path)) {
            Write-Error "Azure configuration file not found: $Path"
            return $null
        }
        try {
            $raw = Get-Content -Path $Path -Raw -ErrorAction Stop
            $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
            $azure = $parsed.Azure
            if (-not $azure) {
                Write-Error "Invalid Azure configuration: missing 'Azure' root key"
                return $null
            }
            return [PSCustomObject]@{
                PSTypeName                = 'Hermes.AzureConfiguration'
                Location                  = $azure.Location
                ResourceGroupAplicaciones = $azure.ResourceGroupAplicaciones
                ResourceGroupPlan         = $azure.ResourceGroupPlan
                AppServicePlan            = $azure.AppServicePlan
                StorageAccount            = if ($azure.PSObject.Properties.Name -contains 'StorageAccount') { $azure.StorageAccount } else { '' }
                UseSharedInfrastructure   = [bool]$azure.UseSharedInfrastructure
            }
        }
        catch {
            Write-Error "Failed to parse Azure configuration: $_"
            return $null
        }
    }

    return _Read-AzureConfiguration
}
