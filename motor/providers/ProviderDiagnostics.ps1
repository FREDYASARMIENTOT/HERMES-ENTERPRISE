<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderDiagnostics.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Ejecuta diagnósticos locales de configuración, capacidades y health para providers sin HTTP,
    SDKs, IA, credenciales reales ni providers externos.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Invoke-HermesEnterpriseProviderDiagnostics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProvider,
        [Parameter(Mandatory = $true)][psobject]$AdministradorConfiguracionProviders,
        [Parameter(Mandatory = $false)]$ConfiguracionProvider = @{},
        [Parameter(Mandatory = $true)][psobject]$DescriptorCapacidadesProvider,
        [Parameter(Mandatory = $false)][string[]]$CapacidadesRequeridas = @(),
        [Parameter(Mandatory = $false)][psobject]$HealthProvider = $null
    )

    $ResultadoConfiguracion = Test-HermesEnterpriseProviderConfiguration `
        -AdministradorConfiguracionProviders $AdministradorConfiguracionProviders `
        -NombreProvider $NombreProvider `
        -ConfiguracionSolicitada $ConfiguracionProvider

    $ErroresCapacidades = New-Object System.Collections.Generic.List[string]
    foreach ($CapacidadRequerida in $CapacidadesRequeridas) {
        if (-not (Test-HermesEnterpriseProviderCapability -DescriptorCapacidadesProvider $DescriptorCapacidadesProvider -NombreCapacidad $CapacidadRequerida)) {
            $ErroresCapacidades.Add("Capacidad requerida no soportada: $CapacidadRequerida") | Out-Null
        }
    }

    $EstadoHealth = if ($null -eq $HealthProvider) { "Unknown" } else { $HealthProvider.Estado }
    $MensajeHealth = if ($null -eq $HealthProvider) { "Health no informado." } else { $HealthProvider.Mensaje }
    $HealthEsValido = ($EstadoHealth -eq "Healthy")

    $ResultadoCapacidades = [pscustomobject][ordered]@{
        EsValida = ($ErroresCapacidades.Count -eq 0)
        CapacidadesRequeridas = $CapacidadesRequeridas
        CapacidadesSoportadas = @($DescriptorCapacidadesProvider.CapacidadesSoportadas)
        CapacidadesExperimentales = @($DescriptorCapacidadesProvider.CapacidadesExperimentales)
        Errores = $ErroresCapacidades.ToArray()
    }

    $ResultadoHealth = [pscustomobject][ordered]@{
        EsValido = $HealthEsValido
        Estado = $EstadoHealth
        Mensaje = $MensajeHealth
    }

    $EsListoLocalmente = ($ResultadoConfiguracion.EsValida -and $ResultadoCapacidades.EsValida -and $ResultadoHealth.EsValido)

    return [pscustomobject][ordered]@{
        NombreComponente = "Provider Diagnostics"
        NombreProvider = $NombreProvider
        EsListoLocalmente = $EsListoLocalmente
        Configuracion = $ResultadoConfiguracion
        Capacidades = $ResultadoCapacidades
        Health = $ResultadoHealth
        LimitesIncluidos = [pscustomobject][ordered]@{
            HTTP = $false
            SDKExterno = $false
            ProviderReal = $false
            CredencialesReales = $false
            IA = $false
        }
    }
}
