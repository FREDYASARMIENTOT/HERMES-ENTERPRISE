<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderDescriptor.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Consolida metainformación local de providers en un objeto raíz sin Adapter Base, Azure,
    HTTP, SDKs, IA, credenciales reales ni providers externos.
====================================================================================================
#>
Set-StrictMode -Version Latest

function New-HermesEnterpriseProviderDescriptor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$Metadata,
        [Parameter(Mandatory = $false)][psobject]$Configuration = $null,
        [Parameter(Mandatory = $false)][psobject]$Capabilities = $null,
        [Parameter(Mandatory = $false)][psobject]$Diagnostics = $null,
        [Parameter(Mandatory = $false)][psobject]$Health = $null,
        [Parameter(Mandatory = $false)][psobject]$Observability = $null,
        [Parameter(Mandatory = $false)][psobject]$Maturity = $null,
        [Parameter(Mandatory = $false)][psobject]$RuntimeState = $null
    )

    return [pscustomobject][ordered]@{
        Nombre = $Metadata.Nombre
        Version = $Metadata.Version
        Autor = $Metadata.Autor
        Metadata = $Metadata
        Configuration = $Configuration
        Capabilities = $Capabilities
        Diagnostics = $Diagnostics
        Health = $Health
        Observability = $Observability
        Maturity = $Maturity
        RuntimeState = $RuntimeState
        LimitesIncluidos = [pscustomobject][ordered]@{
            AdapterBase = $false
            AzureFoundry = $false
            HTTP = $false
            SDKExterno = $false
            ProviderReal = $false
            CredencialesReales = $false
            IA = $false
        }
    }
}

function Get-HermesEnterpriseProviderDescriptorSummary {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$ProviderDescriptor)

    return [pscustomobject][ordered]@{
        Nombre = $ProviderDescriptor.Nombre
        Version = $ProviderDescriptor.Version
        Autor = $ProviderDescriptor.Autor
        TieneConfiguration = ($null -ne $ProviderDescriptor.Configuration)
        TieneCapabilities = ($null -ne $ProviderDescriptor.Capabilities)
        TieneDiagnostics = ($null -ne $ProviderDescriptor.Diagnostics)
        TieneHealth = ($null -ne $ProviderDescriptor.Health)
        TieneObservability = ($null -ne $ProviderDescriptor.Observability)
        TieneMaturity = ($null -ne $ProviderDescriptor.Maturity)
        TieneRuntimeState = ($null -ne $ProviderDescriptor.RuntimeState)
        EsListoLocalmente = ($null -ne $ProviderDescriptor.Diagnostics -and [bool]$ProviderDescriptor.Diagnostics.EsListoLocalmente)
        LimitesIncluidos = $ProviderDescriptor.LimitesIncluidos
    }
}

function Test-HermesEnterpriseProviderDescriptor {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$ProviderDescriptor)

    $Errores = New-Object System.Collections.Generic.List[string]
    $SeccionesRequeridas = @(
        "Configuration",
        "Capabilities",
        "Diagnostics",
        "Health",
        "Observability",
        "Maturity"
    )

    if ([string]::IsNullOrWhiteSpace($ProviderDescriptor.Nombre)) {
        $Errores.Add("Falta metadata requerida: Nombre") | Out-Null
    }

    if ([string]::IsNullOrWhiteSpace($ProviderDescriptor.Version)) {
        $Errores.Add("Falta metadata requerida: Version") | Out-Null
    }

    foreach ($NombreSeccion in $SeccionesRequeridas) {
        if ($null -eq $ProviderDescriptor.$NombreSeccion) {
            $Errores.Add("Falta sección requerida: $NombreSeccion") | Out-Null
        }
    }

    return [pscustomobject][ordered]@{
        EsValido = ($Errores.Count -eq 0)
        NombreProvider = $ProviderDescriptor.Nombre
        Errores = $Errores.ToArray()
    }
}
