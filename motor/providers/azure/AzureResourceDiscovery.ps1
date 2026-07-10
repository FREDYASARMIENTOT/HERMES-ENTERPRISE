<#
.SYNOPSIS
    Componente de descubrimiento de recursos para Azure Provider.

.DESCRIPTION
    AzureResourceDiscovery descubre recursos disponibles dentro de una suscripcion
    Azure utilizando un AzureContext previamente autenticado.

    Este componente NO autentica (responsabilidad del Sprint 6.2).
    NO interactua con servicios especificos.
    Solo consulta metadata de recursos via az CLI.

.PARAMETER AzureContext
    Objeto PSCustomObject producido por Connect-HermesAzure.
    Debe contener el campo EstaAutenticado = $true.

.PARAMETER NombreGrupoRecursos
    (Opcional) Filtrar recursos a un grupo especifico.
    Si no se especifica, se retornan todos los recursos de la suscripcion activa.

.PARAMETER TipoRecurso
    (Opcional) Filtrar recursos por tipo (ej: 'Microsoft.Compute/virtualMachines').

.OUTPUTS
    PSCustomObject con estructura AzureDiscovery:
    {
        Usuario:                 [string]  Correo del usuario autenticado
        IdentificadorInquilino:  [string]  GUID del tenant
        SuscripcionesDisponibles:[array]   Listado completo de suscripciones
        SuscripcionSeleccionada: [PSCustomObject] Suscripcion activa
        GruposRecursos:          [array]   Resource Groups dentro de la suscripcion
        RecursosEncontrados:     [array]   Recursos descubiertos (filtrados si aplica)
        TiposRecursos:           [array]   Tipos unicos de recursos encontrados
        FechaConsulta:           [datetime] Timestamp UTC de la consulta
        TotalRecursos:           [int]     Numero de recursos listados
        EstaAutenticado:         [bool]    true si el contexto es valido
    }

.EXAMPLE
    $contexto = Connect-HermesAzure -CorreoElectronico "usuario@dominio.com"
    $discovery = Get-HermesAzureResourceDiscovery -AzureContext $contexto

.EXAMPLE
    $discovery = Get-HermesAzureResourceDiscovery -AzureContext $contexto -NombreGrupoRecursos "RG-Produccion"

.NOTES
    Autor:    Hermes Enterprise
    Version:  1.0.0
    Sprint:   6.3
    Fecha:    2026-07-10

    Responsabilidad unica: descubrimiento de recursos via az CLI.
    No ejecuta operaciones de negocio sobre los recursos.
#>

function Get-HermesAzureResourceDiscovery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "AzureContext producido por Connect-HermesAzure")]
        [ValidateNotNull()]
        [PSCustomObject]$AzureContext,

        [Parameter(Mandatory = $false)]
        [string]$NombreGrupoRecursos,

        [Parameter(Mandatory = $false)]
        [string]$TipoRecurso
    )

    begin {
        Write-Verbose "Iniciando AzureResourceDiscovery para: $($AzureContext.Usuario)"
        $timestampInicio = [datetime]::UtcNow
    }

    process {
        try {
            # Paso 1: Validar AzureContext de entrada
            ValidarAzureContext -AzureContext $AzureContext

            # Paso 2: Obtener suscripciones disponibles
            $suscripciones = ObtenerSuscripciones
            Write-Verbose "Suscripciones obtenidas: $($suscripciones.Count)"

            # Paso 3: Obtener grupos de recursos
            $gruposRecursos = ObtenerGruposRecursos -NombreGrupoRecursos $NombreGrupoRecursos
            
            if ($NombreGrupoRecursos) {
                $gruposRecursos = $gruposRecursos | Where-Object { $_.name -eq $NombreGrupoRecursos }
                if (-not $gruposRecursos) {
                    throw "Grupo de recursos '$NombreGrupoRecursos' no encontrado en la suscripcion activa."
                }
            }
            Write-Verbose "Grupos de recursos filtrados: $(@($gruposRecursos).Count)"

            # Paso 4: Obtener recursos
            $recursos = ObtenerRecursos -NombreGrupoRecursos $NombreGrupoRecursos -TipoRecurso $TipoRecurso
            Write-Verbose "Recursos encontrados: $($recursos.Count)"

            # Paso 5: Construir y retornar AzureDiscovery
            $resultado = ConstruirResultadoDiscovery `
                -AzureContext $AzureContext `
                -Suscripciones $suscripciones `
                -GruposRecursos $gruposRecursos `
                -Recursos $recursos `
                -FechaConsulta $timestampInicio
            
            return $resultado
        }
        catch {
            Write-Error "Error durante el descubrimiento de recursos Azure: $_"
            throw
        }
    }

    end {
        Write-Verbose "AzureResourceDiscovery completado en $(([datetime]::UtcNow - $timestampInicio).TotalSeconds) segundos."
    }
}

#region Funciones Privadas

function ValidarAzureContext {
    <#
    .SYNOPSIS
        Valida que el AzureContext de entrada sea valido y este autenticado.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AzureContext
    )

    if (-not $AzureContext.EstaAutenticado) {
        throw "El AzureContext proporcionado no esta autenticado. Ejecute primero Connect-HermesAzure."
    }

    $camposRequeridos = @('Usuario', 'IdentificadorInquilino', 'IdentificadorSuscripcion')
    foreach ($campo in $camposRequeridos) {
        if (-not $AzureContext.$campo) {
            throw "El AzureContext no contiene el campo requerido: $campo"
        }
    }

    Write-Verbose "AzureContext validado correctamente para: $($AzureContext.Usuario)"
}

function ObtenerSuscripciones {
    <#
    .SYNOPSIS
        Obtiene la lista de suscripciones disponibles para el usuario autenticado.
    
    .DESCRIPTION
        Ejecuta 'az account list --all' para listar todas las suscripciones accesibles.
    #>
    [CmdletBinding()]
    param()

    try {
        $suscripciones = az account list --all --output json 2>&1 | ConvertFrom-Json
        return $suscripciones
    }
    catch {
        Write-Warning "No se pudieron obtener las suscripciones: $_"
        return @()
    }
}

function ObtenerGruposRecursos {
    <#
    .SYNOPSIS
        Obtiene los grupos de recursos de la suscripcion activa.
    
    .DESCRIPTION
        Ejecuta 'az group list' para listar todos los Resource Groups.
        Si se especifica un nombre, filtra la lista.
    
    .PARAMETER NombreGrupoRecursos
        (Opcional) Nombre del Resource Group a filtrar.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$NombreGrupoRecursos
    )

    try {
        $grupos = az group list --output json 2>&1 | ConvertFrom-Json
        return $grupos
    }
    catch {
        Write-Warning "No se pudieron obtener los grupos de recursos: $_"
        return @()
    }
}

function ObtenerRecursos {
    <#
    .SYNOPSIS
        Obtiene los recursos de Azure dentro de la suscripcion activa.
    
    .DESCRIPTION
        Ejecuta 'az resource list' para listar todos los recursos.
        Puede filtrar por grupo de recursos y/o tipo de recurso.
    
    .PARAMETER NombreGrupoRecursos
        (Opcional) Filtrar a un Resource Group especifico.
    
    .PARAMETER TipoRecurso
        (Opcional) Filtrar por tipo de recurso (ej: 'Microsoft.Compute/virtualMachines').
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$NombreGrupoRecursos,

        [Parameter(Mandatory = $false)]
        [string]$TipoRecurso
    )

    try {
        $comando = 'az resource list --output json'
        
        if ($NombreGrupoRecursos) {
            $comando += " --resource-group `"$NombreGrupoRecursos`""
        }
        
        if ($TipoRecurso) {
            $comando += " --resource-type `"$TipoRecurso`""
        }

        $recursos = Invoke-Expression "$comando 2>&1" | ConvertFrom-Json
        return $recursos
    }
    catch {
        Write-Warning "No se pudieron obtener los recursos: $_"
        return @()
    }
}

function ConstruirResultadoDiscovery {
    <#
    .SYNOPSIS
        Construye el objeto AzureDiscovery a partir de los datos descubiertos.
    
    .PARAMETER AzureContext
        Contexto de autenticacion original.
    
    .PARAMETER Suscripciones
        Lista de suscripciones disponibles.
    
    .PARAMETER GruposRecursos
        Lista de Resource Groups.
    
    .PARAMETER Recursos
        Lista de recursos descubiertos.
    
    .PARAMETER FechaConsulta
        Timestamp UTC de la consulta.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AzureContext,

        [Parameter(Mandatory = $true)]
        [array]$Suscripciones,

        [Parameter(Mandatory = $true)]
        [array]$GruposRecursos,

        [Parameter(Mandatory = $true)]
        [array]$Recursos,

        [Parameter(Mandatory = $true)]
        [datetime]$FechaConsulta
    )

    # Extraer suscripcion activa
    $suscripcionActiva = $Suscripciones | Where-Object { $_.id -eq $AzureContext.IdentificadorSuscripcion } | Select-Object -First 1

    # Extraer tipos unicos de recursos
    $tiposUnicos = @()
    if ($Recursos -and $Recursos.Count -gt 0) {
        $tipos = $Recursos | Select-Object -ExpandProperty type -ErrorAction SilentlyContinue | Select-Object -Unique
        if ($tipos.GetType().IsArray) {
            $tiposUnicos = $tipos
        } else {
            $tiposUnicos = @($tipos)
        }
    }

    $resultado = [PSCustomObject]@{
        Usuario                    = $AzureContext.Usuario
        IdentificadorInquilino     = $AzureContext.IdentificadorInquilino
        SuscripcionesDisponibles   = $Suscripciones
        SuscripcionSeleccionada    = $suscripcionActiva
        GruposRecursos             = $GruposRecursos
        RecursosEncontrados        = $Recursos
        TiposRecursos              = $tiposUnicos
        FechaConsulta              = $FechaConsulta
        TotalRecursos              = if ($Recursos) { $Recursos.Count } else { 0 }
        EstaAutenticado            = $AzureContext.EstaAutenticado
    }

    Write-Verbose "AzureDiscovery construido: $($resultado.TotalRecursos) recursos en $(@($resultado.GruposRecursos).Count) grupos"
    return $resultado
}

#endregion Funciones Privadas

# Exportar funcion publica si es modulo
if ($MyInvocation.MyCommand.Path -like '*.psm1') {
    Export-ModuleMember -Function Get-HermesAzureResourceDiscovery
}
