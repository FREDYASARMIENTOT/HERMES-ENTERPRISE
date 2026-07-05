<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderContext.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Construye el contexto operativo base para providers sin credenciales reales ni transporte externo.
====================================================================================================
#>
Set-StrictMode -Version Latest

function New-HermesEnterpriseProviderContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProvider,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$VersionProvider,
        [Parameter(Mandatory = $false)][hashtable]$ConfiguracionProvider = @{},
        [Parameter(Mandatory = $false)][string[]]$CapacidadesProvider = @(),
        [Parameter(Mandatory = $false)][hashtable]$MetadatosProvider = @{}
    )

    $ConfiguracionSegura = @{}
    foreach ($ClaveConfiguracion in $ConfiguracionProvider.Keys) {
        if ($ClaveConfiguracion -notmatch "(?i)(secret|token|password|apikey|api_key|credential)") {
            $ConfiguracionSegura[$ClaveConfiguracion] = $ConfiguracionProvider[$ClaveConfiguracion]
        }
    }

    return [pscustomobject][ordered]@{
        NombreProvider = $NombreProvider
        VersionProvider = $VersionProvider
        Estado = "Created"
        ConfiguracionProvider = $ConfiguracionSegura
        CapacidadesProvider = $CapacidadesProvider
        MetadatosProvider = $MetadatosProvider
        Health = [pscustomobject][ordered]@{
            Estado = "Unknown"
            UltimaVerificacion = $null
            Mensaje = "Provider creado sin validacion operativa."
        }
    }
}
