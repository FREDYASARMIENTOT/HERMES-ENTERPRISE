<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderLifecycleManager.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Gestor del ciclo de vida de Providers.
    Maneja: activación (connect), validación de estado, ejecución, desactivación (disconnect),
    y monitoreo de salud de providers.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea un nuevo gestor de ciclo de vida de Providers.
.DESCRIPTION
    Inicializa el gestor con el registro de Providers y el contenedor de dependencias.
.PARAMETER ProviderRegistry
    El registro de Providers (ProviderRegistry).
.PARAMETER DependencyContainer
    El contenedor de dependencias del sistema.
#>
function New-ProviderLifecycleManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$ProviderRegistry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$DependencyContainer
    )

    return [pscustomobject][ordered]@{
        Registry           = $ProviderRegistry
        Container          = $DependencyContainer
        ActiveProviders    = [System.Collections.ArrayList]@()
        ProviderStates     = @{}   # ProviderId -> 'Disconnected' | 'Connecting' | 'Active' | 'Error' | 'Disconnected'
        ConnectionHistory  = [System.Collections.ArrayList]@()
        TotalConnections   = 0
        TotalDisconnections = 0
    }
}

<#
.SYNOPSIS
    Activa (conecta) un Provider por su nombre.
.DESCRIPTION
    Verifica que el Provider esté registrado, cambia su estado a Active y lo agrega
    a la lista de providers activos.
.PARAMETER LifecycleManager
    El gestor de ciclo de vida.
.PARAMETER ProviderName
    Nombre del Provider a activar.
#>
function Connect-Provider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$LifecycleManager,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderName
    )

    # Verificar que el provider existe en el registro
    $providerFound = $false
    $provider = $null

    if ($LifecycleManager.Registry.Providers.ContainsKey($ProviderName)) {
        $providerFound = $true
        $provider = $LifecycleManager.Registry.Providers[$ProviderName]
    }
    else {
        # También buscar en el contenedor de dependencias
        $provider = Resolve-HermesEnterpriseService -ContenedorDependencias $LifecycleManager.Container -NombreServicio "Provider.$ProviderName"
        if ($null -ne $provider) {
            $providerFound = $true
        }
    }

    if (-not $providerFound) {
        throw "Provider not found: $ProviderName"
    }

    # Cambiar estado
    $LifecycleManager.ProviderStates[$ProviderName] = 'Active'
    $null = $LifecycleManager.ActiveProviders.Add($ProviderName)

    # Registrar conexión
    $connectionEntry = [pscustomobject][ordered]@{
        ProviderName = $ProviderName
        Action       = 'Connect'
        Timestamp    = [datetime]::UtcNow.ToString('o')
        Status       = 'Success'
    }
    $null = $LifecycleManager.ConnectionHistory.Add($connectionEntry)
    $LifecycleManager.TotalConnections++

    return $true
}

<#
.SYNOPSIS
    Desactiva (desconecta) un Provider por su nombre.
.PARAMETER LifecycleManager
    El gestor de ciclo de vida.
.PARAMETER ProviderName
    Nombre del Provider a desactivar.
#>
function Disconnect-Provider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$LifecycleManager,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderName
    )

    if (-not $LifecycleManager.ProviderStates.ContainsKey($ProviderName)) {
        throw "Provider not tracked: $ProviderName"
    }

    $LifecycleManager.ProviderStates[$ProviderName] = 'Disconnected'

    # Remover de activos
    $index = $LifecycleManager.ActiveProviders.IndexOf($ProviderName)
    if ($index -ge 0) {
        $LifecycleManager.ActiveProviders.RemoveAt($index)
    }

    # Registrar desconexión
    $disconnectionEntry = [pscustomobject][ordered]@{
        ProviderName = $ProviderName
        Action       = 'Disconnect'
        Timestamp    = [datetime]::UtcNow.ToString('o')
        Status       = 'Success'
    }
    $null = $LifecycleManager.ConnectionHistory.Add($disconnectionEntry)
    $LifecycleManager.TotalDisconnections++

    return $true
}

<#
.SYNOPSIS
    Verifica el estado de un Provider.
.PARAMETER LifecycleManager
    El gestor de ciclo de vida.
.PARAMETER ProviderName
    Nombre del Provider a verificar.
#>
function Test-ProviderHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$LifecycleManager,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderName
    )

    if (-not $LifecycleManager.ProviderStates.ContainsKey($ProviderName)) {
        return $false
    }

    return ($LifecycleManager.ProviderStates[$ProviderName] -eq 'Active')
}

<#
.SYNOPSIS
    Obtiene el estado actual de todos los Providers gestionados.
#>
function Get-ProviderLifecycleStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$LifecycleManager
    )

    $statusList = [System.Collections.ArrayList]@()

    foreach ($providerName in $LifecycleManager.ProviderStates.Keys) {
        $entry = [pscustomobject][ordered]@{
            ProviderName = $providerName
            Status       = $LifecycleManager.ProviderStates[$providerName]
            IsActive     = ($LifecycleManager.ProviderStates[$providerName] -eq 'Active')
        }
        $null = $statusList.Add($entry)
    }

    return [pscustomobject][ordered]@{
        ActiveCount        = $LifecycleManager.ActiveProviders.Count
        TotalConnections   = $LifecycleManager.TotalConnections
        TotalDisconnections = $LifecycleManager.TotalDisconnections
        Providers          = $statusList
    }
}

<#
.SYNOPSIS
    Desconecta todos los Providers activos (limpieza global).
#>
function Disconnect-AllProviders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$LifecycleManager
    )

    $activeList = @($LifecycleManager.ActiveProviders | ForEach-Object { $_ })
    $results = [System.Collections.ArrayList]@()

    foreach ($providerName in $activeList) {
        try {
            $null = Disconnect-Provider -LifecycleManager $LifecycleManager -ProviderName $providerName
            $null = $results.Add([pscustomobject]@{ ProviderName = $providerName; Result = 'Disconnected' })
        }
        catch {
            $null = $results.Add([pscustomobject]@{ ProviderName = $providerName; Result = "Error: $_" })
        }
    }

    return $results
}

Export-ModuleMember -Function New-ProviderLifecycleManager, Connect-Provider, Disconnect-Provider, Test-ProviderHealth, Get-ProviderLifecycleStatus, Disconnect-AllProviders