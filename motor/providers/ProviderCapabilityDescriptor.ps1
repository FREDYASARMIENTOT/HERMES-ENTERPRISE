<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderCapabilityDescriptor.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Describe capacidades declarativas de providers como metainformación local, sin ejecutar IA,
    transporte externo, SDKs, HTTP ni providers reales.
====================================================================================================
#>
Set-StrictMode -Version Latest

function New-HermesEnterpriseProviderCapabilityDescriptor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProvider,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$VersionProvider,
        [Parameter(Mandatory = $false)][string[]]$CapacidadesSoportadas = @(),
        [Parameter(Mandatory = $false)][string[]]$CapacidadesExperimentales = @(),
        [Parameter(Mandatory = $false)][hashtable]$MetadatosCapacidades = @{}
    )

    return [pscustomobject][ordered]@{
        NombreProvider = $NombreProvider
        VersionProvider = $VersionProvider
        CapacidadesSoportadas = $CapacidadesSoportadas
        CapacidadesExperimentales = $CapacidadesExperimentales
        MetadatosCapacidades = $MetadatosCapacidades
        LimitesIncluidos = [pscustomobject][ordered]@{
            ImplementaIA = $false
            HTTP = $false
            SDKExterno = $false
            ProviderReal = $false
            CredencialesReales = $false
        }
    }
}

function Test-HermesEnterpriseProviderCapability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$DescriptorCapacidadesProvider,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreCapacidad,
        [Parameter(Mandatory = $false)][switch]$IncluirExperimentales
    )

    if ($DescriptorCapacidadesProvider.CapacidadesSoportadas -contains $NombreCapacidad) {
        return $true
    }

    if ($IncluirExperimentales.IsPresent -and $DescriptorCapacidadesProvider.CapacidadesExperimentales -contains $NombreCapacidad) {
        return $true
    }

    return $false
}

function Get-HermesEnterpriseProviderCapabilitySummary {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$DescriptorCapacidadesProvider)

    return [pscustomobject][ordered]@{
        NombreProvider = $DescriptorCapacidadesProvider.NombreProvider
        VersionProvider = $DescriptorCapacidadesProvider.VersionProvider
        TotalCapacidadesSoportadas = @($DescriptorCapacidadesProvider.CapacidadesSoportadas).Count
        TotalCapacidadesExperimentales = @($DescriptorCapacidadesProvider.CapacidadesExperimentales).Count
        CapacidadesSoportadas = @($DescriptorCapacidadesProvider.CapacidadesSoportadas)
        CapacidadesExperimentales = @($DescriptorCapacidadesProvider.CapacidadesExperimentales)
        LimitesIncluidos = $DescriptorCapacidadesProvider.LimitesIncluidos
    }
}

function Test-HermesEnterpriseProviderCapabilityDescriptor {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$DescriptorCapacidadesProvider)

    $Errores = New-Object System.Collections.Generic.List[string]
    $CapacidadesReservadas = @("HTTP", "REST", "SDK", "SDKExterno", "OAuth", "WebSockets")
    $TodasLasCapacidades = @($DescriptorCapacidadesProvider.CapacidadesSoportadas) + @($DescriptorCapacidadesProvider.CapacidadesExperimentales)

    foreach ($NombreCapacidad in $TodasLasCapacidades) {
        if ($NombreCapacidad -match "(?i)(secret|token|password|apikey|api_key|credential)") {
            $Errores.Add("Capacidad sensible no permitida: $NombreCapacidad") | Out-Null
            continue
        }

        if ($CapacidadesReservadas -contains $NombreCapacidad) {
            $Errores.Add("Capacidad reservada no permitida: $NombreCapacidad") | Out-Null
        }
    }

    return [pscustomobject][ordered]@{
        EsValido = ($Errores.Count -eq 0)
        NombreProvider = $DescriptorCapacidadesProvider.NombreProvider
        Errores = $Errores.ToArray()
    }
}
