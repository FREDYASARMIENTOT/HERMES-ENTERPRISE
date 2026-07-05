<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderAdapter.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Define adapter base y state machine declarativa para providers sin Azure, HTTP, SDKs,
    IA, credenciales reales ni providers externos.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Get-HermesEnterpriseProviderAdapterStateMachine {
    [CmdletBinding()]
    param()

    return [pscustomobject][ordered]@{
        EstadosPermitidos = @("Created", "Configured", "Validated", "Initialized", "Ready", "Healthy", "Degraded", "Faulted", "Disposed")
        TransicionesPermitidas = @{
            Created = @("Configured", "Faulted", "Disposed")
            Configured = @("Validated", "Faulted", "Disposed")
            Validated = @("Initialized", "Faulted", "Disposed")
            Initialized = @("Ready", "Faulted", "Disposed")
            Ready = @("Healthy", "Degraded", "Faulted", "Disposed")
            Healthy = @("Degraded", "Faulted", "Disposed")
            Degraded = @("Healthy", "Faulted", "Disposed")
            Faulted = @("Disposed")
            Disposed = @()
        }
    }
}

function New-HermesEnterpriseProviderAdapter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProvider,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$VersionProvider,
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$Autor = "HERMES-ENTERPRISE"
    )

    return [pscustomobject][ordered]@{
        NombreProvider = $NombreProvider
        VersionProvider = $VersionProvider
        Autor = $Autor
        EstadoActual = "Created"
        HistorialEstados = New-Object System.Collections.Generic.List[string]
        OperacionesRequeridas = @("Initialize", "ValidateConfiguration", "Connect", "Disconnect", "Health", "DescribeCapabilities")
        LimitesIncluidos = [pscustomobject][ordered]@{
            AzureFoundry = $false
            HTTP = $false
            SDKExterno = $false
            ProviderReal = $false
            CredencialesReales = $false
            IA = $false
        }
    }
}

function Test-HermesEnterpriseProviderAdapterStateTransition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$EstadoOrigen,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$EstadoDestino
    )

    $StateMachine = Get-HermesEnterpriseProviderAdapterStateMachine
    if ($StateMachine.EstadosPermitidos -notcontains $EstadoOrigen) { return $false }
    if ($StateMachine.EstadosPermitidos -notcontains $EstadoDestino) { return $false }
    return ($StateMachine.TransicionesPermitidas[$EstadoOrigen] -contains $EstadoDestino)
}

function Move-HermesEnterpriseProviderAdapterState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$ProviderAdapter,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NuevoEstado
    )

    if (-not (Test-HermesEnterpriseProviderAdapterStateTransition -EstadoOrigen $ProviderAdapter.EstadoActual -EstadoDestino $NuevoEstado)) {
        throw "Transición de estado no permitida: $($ProviderAdapter.EstadoActual) -> $NuevoEstado"
    }

    if ($ProviderAdapter.HistorialEstados.Count -eq 0) {
        $ProviderAdapter.HistorialEstados.Add($ProviderAdapter.EstadoActual) | Out-Null
    }

    $ProviderAdapter.EstadoActual = $NuevoEstado
    $ProviderAdapter.HistorialEstados.Add($NuevoEstado) | Out-Null
    return $ProviderAdapter
}

function Test-HermesEnterpriseProviderAdapterContract {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$ProviderAdapter)

    $Errores = New-Object System.Collections.Generic.List[string]
    $OperacionesRequeridas = @("Initialize", "ValidateConfiguration", "Connect", "Disconnect", "Health", "DescribeCapabilities")

    foreach ($OperacionRequerida in $OperacionesRequeridas) {
        if ($ProviderAdapter.OperacionesRequeridas -notcontains $OperacionRequerida) {
            $Errores.Add("Falta operación requerida: $OperacionRequerida") | Out-Null
        }
    }

    if ([string]::IsNullOrWhiteSpace($ProviderAdapter.NombreProvider)) {
        $Errores.Add("Falta metadata requerida: NombreProvider") | Out-Null
    }

    if ([string]::IsNullOrWhiteSpace($ProviderAdapter.VersionProvider)) {
        $Errores.Add("Falta metadata requerida: VersionProvider") | Out-Null
    }

    return [pscustomobject][ordered]@{
        EsValido = ($Errores.Count -eq 0)
        NombreProvider = $ProviderAdapter.NombreProvider
        Errores = $Errores.ToArray()
    }
}
