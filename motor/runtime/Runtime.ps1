<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Runtime.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Runtime del Kernel Enterprise — ciclo de vida, ejecución de motores, proveedores y orquestación.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea una nueva instancia del Runtime del Kernel Enterprise.
.DESCRIPTION
    Inicializa el Runtime con registros de motores, proveedores, bus de eventos y estado de ciclo de vida.
#>
function New-HermesEnterpriseRuntime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$EventBusKernel,

        [Parameter(Mandatory = $false)]
        [psobject]$EngineRegistry,

        [Parameter(Mandatory = $false)]
        [psobject]$ProviderRegistry
    )

    $runtime = [pscustomobject][ordered]@{
        EventBus        = $EventBusKernel
        EngineRegistry  = $EngineRegistry
        ProviderRegistry = $ProviderRegistry
        EstadoRuntime   = 'Creado'
        Componentes     = [System.Collections.ArrayList]@()
        HoraInicio      = $null
        ExecutionContexts = [System.Collections.ArrayList]@()
    }

    return $runtime
}

<#
.SYNOPSIS
    Inicia el Runtime del Kernel Enterprise.
.DESCRIPTION
    Activa todos los motores registrados, conecta proveedores y cambia el estado a 'Iniciado'.
#>
function Start-HermesEnterpriseRuntime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$RuntimeKernel
    )

    if ($RuntimeKernel.EstadoRuntime -eq 'Iniciado') {
        Write-Warning 'Runtime already started.'
        return $RuntimeKernel
    }

    # 1. Iniciar todos los motores registrados
    if ($null -ne $RuntimeKernel.EngineRegistry) {
        $engines = Get-AllEnginesFromRegistry -Registry $RuntimeKernel.EngineRegistry
        foreach ($engine in $engines) {
            $null = $RuntimeKernel.Componentes.Add(@{
                Nombre       = $engine.Name
                Tipo         = 'Engine'
                Estado       = 'Starting'
                FechaRegistro = (Get-Date).ToString('o')
            })
        }
    }

    # 2. Conectar todos los proveedores registrados
    if ($null -ne $RuntimeKernel.ProviderRegistry) {
        $providers = Get-AllProvidersFromRegistry -Registry $RuntimeKernel.ProviderRegistry
        foreach ($provider in $providers) {
            if ($provider.Status -eq 'Initialized') {
                Connect-ProviderBase -Provider $provider
            }
            $null = $RuntimeKernel.Componentes.Add(@{
                Nombre       = $provider.Name
                Tipo         = 'Provider'
                Estado       = $provider.Status
                FechaRegistro = (Get-Date).ToString('o')
            })
        }
    }

    $RuntimeKernel.HoraInicio = Get-Date
    $RuntimeKernel.EstadoRuntime = 'Iniciado'

    return $RuntimeKernel
}

<#
.SYNOPSIS
    Detiene el Runtime del Kernel Enterprise.
.DESCRIPTION
    Desconecta proveedores y cambia el estado a 'Detenido'.
#>
function Stop-HermesEnterpriseRuntime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$RuntimeKernel
    )

    if ($RuntimeKernel.EstadoRuntime -eq 'Detenido') {
        Write-Warning 'Runtime already stopped.'
        return $RuntimeKernel
    }

    # Desconectar todos los proveedores conectados
    if ($null -ne $RuntimeKernel.ProviderRegistry) {
        $providers = Get-AllProvidersFromRegistry -Registry $RuntimeKernel.ProviderRegistry
        foreach ($provider in $providers) {
            if ($provider.IsConnected) {
                Disconnect-ProviderBase -Provider $provider
            }
        }
    }

    $RuntimeKernel.EstadoRuntime = 'Detenido'

    return $RuntimeKernel
}

<#
.SYNOPSIS
    Ejecuta un motor específico dentro del Runtime.
.DESCRIPTION
    Crea un contexto de ejecución compartido, resuelve el motor y lo ejecuta con proveedores asociados.
#>
function Invoke-HermesEnterpriseRuntimeEngine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$RuntimeKernel,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EngineName,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},

        [Parameter(Mandatory = $false)]
        [string]$ExecutionId = ''
    )

    if ($RuntimeKernel.EstadoRuntime -ne 'Iniciado') {
        throw "Runtime is not started. Current state: $($RuntimeKernel.EstadoRuntime)"
    }

    if ($null -eq $RuntimeKernel.EngineRegistry) {
        throw 'EngineRegistry is not configured in Runtime.'
    }

    # Resolver el motor
    $engineResolver = New-EngineResolver -Registry $RuntimeKernel.EngineRegistry
    $engine = Resolve-EngineByName -Resolver $engineResolver -EngineName $EngineName

    if ($null -eq $engine) {
        throw "Engine not found: $EngineName"
    }

    # Crear contexto de ejecución compartido
    $executionContext = New-EngineExecutionContext -EngineName $EngineName -ExecutionId $ExecutionId

    # Registrar contexto en Runtime
    $null = $RuntimeKernel.ExecutionContexts.Add($executionContext)

    # Ejecutar
    $result = Execute-Engine -Engine $engine -ExecutionContext $executionContext -Parameters $Parameters

    return $result
}

<#
.SYNOPSIS
    Registra un componente en el Runtime.
.DESCRIPTION
    Agrega un componente (Engine o Provider) al listado de componentes activos del Runtime.
#>
function Register-HermesEnterpriseRuntimeComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$RuntimeKernel,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreComponente,

        [Parameter(Mandatory = $false)]
        [string]$TipoComponente = 'Component',

        [Parameter(Mandatory = $false)]
        [hashtable]$ConfiguracionComponente = @{}
    )

    $EntradaComponente = [pscustomobject][ordered]@{
        Nombre       = $NombreComponente
        Tipo         = $TipoComponente
        Configuracion = $ConfiguracionComponente
        FechaRegistro = (Get-Date).ToString('o')
    }

    $null = $RuntimeKernel.Componentes.Add($EntradaComponente)

    return $EntradaComponente
}

<#
.SYNOPSIS
    Obtiene el estado actual del Runtime.
#>
function Get-HermesEnterpriseRuntimeStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$RuntimeKernel
    )

    $engineCount = 0
    $providerCount = 0

    if ($null -ne $RuntimeKernel.EngineRegistry) {
        $engineCount = $RuntimeKernel.EngineRegistry.TotalCount
    }

    if ($null -ne $RuntimeKernel.ProviderRegistry) {
        $providerCount = $RuntimeKernel.ProviderRegistry.TotalCount
    }

    return [pscustomobject][ordered]@{
        EstadoRuntime         = $RuntimeKernel.EstadoRuntime
        HoraInicio            = $RuntimeKernel.HoraInicio
        ComponentesRegistrados = $RuntimeKernel.Componentes.Count
        Motores               = $engineCount
        Proveedores           = $providerCount
        ContextosEjecucion    = $RuntimeKernel.ExecutionContexts.Count
    }
}

Export-ModuleMember -Function New-HermesEnterpriseRuntime, Start-HermesEnterpriseRuntime, Stop-HermesEnterpriseRuntime, Invoke-HermesEnterpriseRuntimeEngine, Register-HermesEnterpriseRuntimeComponent, Get-HermesEnterpriseRuntimeStatus