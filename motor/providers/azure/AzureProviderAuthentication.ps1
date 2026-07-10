<#
.SYNOPSIS
    Componente de autenticación para Azure Provider.

.DESCRIPTION
    AzureProviderAuthentication es responsable único de autenticar al usuario
    contra Azure y devolver un contexto autenticado reutilizable por cualquier
    capacidad del Azure Provider.

    Este componente NO interactúa con recursos específicos. Solo establece y valida
    la sesión de Azure CLI, gestiona múltiples suscripciones, y construye un objeto
    AzureContext que contiene toda la información necesaria para operaciones posteriores.

.PARAMETER CorreoElectronico
    Correo electrónico del usuario que desea autenticarse en Azure.
    Ejemplo: analiticaur@urosario.edu.co

.PARAMETER IdentificadorSuscripcion
    (Opcional) GUID de la suscripción Azure a utilizar.
    Si no se especifica, se usa la suscripción activa en la sesión.

.PARAMETER IdentificadorInquilino
    (Opcional) GUID del tenant Azure donde autenticarse.
    Si no se especifica, se usa el tenant por defecto.

.OUTPUTS
    PSCustomObject con la siguiente estructura (AzureContext):
    {
        Usuario:              [string]  Correo del usuario autenticado
        IdentificadorInquilino: [string] GUID del tenant
        NombreInquilino:       [string] Nombre amigable del tenant
        IdentificadorSuscripcion: [string] GUID de la suscripción activa
        NombreSuscripcion:     [string] Nombre amigable de la suscripción
        Entorno:               [string] Ambiente Azure (AzureCloud, AzureUSGovernment, etc.)
        EstaAutenticado:       [bool]    Indicador de sesión activa
        MetodoAutenticacion:   [string]  Tipo de login realizado (Interactive, DeviceCode, ServicePrincipal)
    }

.EXAMPLE
    $contexto = Connect-HermesAzure -CorreoElectronico "usuario@dominio.com"
    
    Resultado: Autenticación interactiva y retorno de AzureContext.

.EXAMPLE
    $contexto = Connect-HermesAzure -CorreoElectronico "usuario@dominio.com" -IdentificadorSuscripcion "12345678-1234-1234-1234-123456789012"
    
    Resultado: Autenticación y selección de suscripción específica.

.NOTES
    Autor:        Hermes Enterprise
    Versión:      1.0.0
    Requiere:     Azure CLI instalado (az)
    Fecha:        2026-07-10

    Este componente sigue el principio de responsabilidad única:
    - Solo autentica y gestiona sesión
    - No consulta serviciosAzure específicos (solo sesión y suscripciones)
    - No ejecuta operaciones sobre recursos Azure
    - Es reutilizable por todas las capacidades del Azure Provider
#>

function Connect-HermesAzure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Correo electrónico del usuario Azure")]
        [ValidateNotNullOrEmpty()]
        [string]$CorreoElectronico,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$IdentificadorSuscripcion,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$IdentificadorInquilino
    )

    begin {
        Write-Verbose "Iniciando autenticación Azure para: $CorreoElectronico"
    }

    process {
        try {
            # Paso 1: Verificar instalación de Azure CLI
            VerificarAzureCLI

            # Paso 2: Verificar sesión activa o realizar login
            $sesionActual = ObtenerSesionActual
            
            if (-not $sesionActual) {
                Write-Verbose "No hay sesión activa. Iniciando login..."
                SolicitarLogin -CorreoElectronico $CorreoElectronico -IdentificadorInquilino $IdentificadorInquilino
                $sesionActual = ObtenerSesionActual
            }

            # Paso 3: Validar que el login fue exitoso
            if (-not $sesionActual) {
                throw "No se pudo establecer sesión Azure después del intento de login."
            }

            # Paso 4: Gestionar selección de suscripción (si aplica)
            if ($IdentificadorSuscripcion) {
                Write-Verbose "Seleccionando suscripción específica: $IdentificadorSuscripcion"
                SeleccionarSubscription -IdentificadorSuscripcion $IdentificadorSuscripcion
            } else {
                # Si no se especificó, verificar si hay múltiples suscripciones disponibles
                $suscripcionesDisponibles = ObtenerSuscripcionesDisponibles
                if ($suscripcionesDisponibles.Count -gt 1) {
                    Write-Verbose "Múltiples suscripciones detectadas. Solicitando selección al usuario..."
                    SeleccionarSubscriptionInteractiva -Suscripciones $suscripcionesDisponibles
                }
            }

            # Paso 5: Construir y retornar AzureContext
            $contexto = ConstruirAzureContext -SesionActual $sesionActual
            return $contexto
        }
        catch {
            Write-Error "Error durante la autenticación Azure: $_"
            throw
        }
    }

    end {
        Write-Verbose "Proceso de autenticación Azure completado."
    }
}

#region Funciones Privadas

function VerificarAzureCLI {
    <#
    .SYNOPSIS
        Verifica que Azure CLI está instalado y disponible en el PATH.
    
    .DESCRIPTION
        Ejecuta 'az --version' para confirmar que el comando 'az' está disponible.
        Si no está instalado, lanza una excepción con instrucciones de instalación.
    #>
    [CmdletBinding()]
    param()

    try {
        $null = & az --version 2>&1
        Write-Verbose "Azure CLI detectado correctamente."
    }
    catch {
        throw "Azure CLI no está instalado o no está en el PATH. Instale desde: https://aka.ms/installazurecli"
    }
}

function ObtenerSesionActual {
    <#
    .SYNOPSIS
        Obtiene la sesión actual de Azure CLI.
    
    .DESCRIPTION
        Ejecuta 'az account show' para verificar si existe una sesión activa.
        Retorna el objeto de cuenta si está autenticado, o $null si no hay sesión.
    
    .OUTPUTS
        PSCustomObject con información de la cuenta, o $null si no hay sesión.
    #>
    [CmdletBinding()]
    param()

    try {
        $cuenta = az account show --output json 2>$null | ConvertFrom-Json
        if ($cuenta -and $cuenta.id) {
            Write-Verbose "Sesión Azure activa detectada para: $($cuenta.user.name)"
            return $cuenta
        }
        return $null
    }
    catch {
        Write-Verbose "No hay sesión Azure activa."
        return $null
    }
}

function SolicitarLogin {
    <#
    .SYNOPSIS
        Solicita login interactivo a Azure.
    
    .DESCRIPTION
        Ejecuta 'az login' con el correo proporcionado.
        Si se especifica tenant, lo incluye en el comando.
    
    .PARAMETER CorreoElectronico
        Correo del usuario que desea autenticarse.
    
    .PARAMETER IdentificadorInquilino
        (Opcional) GUID del tenant donde autenticarse.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CorreoElectronico,

        [Parameter(Mandatory = $false)]
        [string]$IdentificadorInquilino
    )

    try {
        if ($IdentificadorInquilino) {
            Write-Verbose "Ejecutando login con tenant específico: $IdentificadorInquilino"
            $null = & az login --use-device-code --tenant $IdentificadorInquilino 2>&1
        }
        else {
            Write-Verbose "Ejecutando login interactivo estándar."
            $null = & az login --use-device-code 2>&1
        }

        Write-Verbose "Login completado exitosamente."
    }
    catch {
        throw "Error durante el login Azure: $_"
    }
}

function ObtenerSuscripcionesDisponibles {
    <#
    .SYNOPSIS
        Obtiene lista de suscripciones disponibles para el usuario autenticado.
    
    .DESCRIPTION
        Ejecuta 'az account list' y retorna todas las suscripciones accesibles.
    
    .OUTPUTS
        Array de PSCustomObject con información de suscripciones.
    #>
    [CmdletBinding()]
    param()

    try {
        $subs = az account list --all --output json 2>&1 | ConvertFrom-Json
        Write-Verbose "Se encontraron $($subs.Count) suscripciones disponibles."
        return $subs
    }
    catch {
        Write-Warning "No se pudieron obtener las suscripciones: $_"
        return @()
    }
}

function SeleccionarSubscription {
    <#
    .SYNOPSIS
        Selecciona una suscripción específica como activa.
    
    .DESCRIPTION
        Ejecuta 'az account set' con el GUID proporcionado.
        Valida que la suscripción exista y sea accesible.
    
    .PARAMETER IdentificadorSuscripcion
        GUID de la suscripción a activar.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$IdentificadorSuscripcion
    )

    try {
        Write-Verbose "Intentando activar suscripción: $IdentificadorSuscripcion"
        $null = & az account set --subscription $IdentificadorSuscripcion 2>&1
        
        # Verificar que la suscripción se activó correctamente
        $cuentaActual = ObtenerSesionActual
        if ($cuentaActual.id -ne $IdentificadorSuscripcion) {
            throw "La suscripción $IdentificadorSuscripcion no se pudo activar o no existe."
        }
        
        Write-Verbose "Suscripción activada correctamente: $($cuentaActual.name)"
    }
    catch {
        throw "Error al seleccionar suscripción '$IdentificadorSuscripcion': $_"
    }
}

function SeleccionarSubscriptionInteractiva {
    <#
    .SYNOPSIS
        Presenta menú interactivo para seleccionar suscripción.
    
    .DESCRIPTION
        Muestra lista numerada de suscripciones disponibles y solicita al usuario
        que seleccione cuál desea utilizar. Luego activa la suscripción elegida.
    
    .PARAMETER Suscripciones
        Array de objetos de suscripción obtenidos de 'az account list'.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Suscripciones
    )

    Write-Host "`n=== Suscripciones Azure Disponibles ===" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Suscripciones.Count; $i++) {
        $sub = $Suscripciones[$i]
        $estado = if ($sub.isDefault) { " [ACTUAL]" } else { "" }
        Write-Host "[$($i + 1)] $($sub.name) ($($sub.id))$estado"
    }

    $seleccion = $null
    while (-not $seleccion -or $seleccion -lt 1 -or $seleccion -gt $Suscripciones.Count) {
        $input = Read-Host "`nSeleccione el número de suscripción a utilizar (1-$($Suscripciones.Count))"
        $seleccion = [int]$input
        if ($seleccion -lt 1 -or $seleccion -gt $Suscripciones.Count) {
            Write-Warning "Selección inválida. Debe estar entre 1 y $($Suscripciones.Count)."
        }
    }

    $subSeleccionada = $Suscripciones[$seleccion - 1]
    Write-Verbose "Usuario seleccionó: $($subSeleccionada.name) ($($subSeleccionada.id))"
    
    SeleccionarSubscription -IdentificadorSuscripcion $subSeleccionada.id
}

function ConstruirAzureContext {
    <#
    .SYNOPSIS
        Construye el objeto AzureContext a partir de la sesión actual.
    
    .DESCRIPTION
        Toma la sesión activa de Azure CLI y construye un PSCustomObject con
        toda la información necesaria para operaciones posteriores.
    
    .PARAMETER SesionActual
        Objeto de cuenta Azure obtenido de 'az account show'.
    
    .OUTPUTS
        PSCustomObject con estructura AzureContext.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$SesionActual
    )

    $contexto = [PSCustomObject]@{
        Usuario                    = $SesionActual.user.name
        IdentificadorInquilino     = $SesionActual.tenantId
        NombreInquilino            = $SesionActual.tenantId  # Azure CLI no expone nombre amigable directamente
        IdentificadorSuscripcion   = $SesionActual.id
        NombreSuscripcion          = $SesionActual.name
        Entorno                    = $SesionActual.environmentName
        EstaAutenticado            = $true
        MetodoAutenticacion        = if ($SesionActual.user.type) { $SesionActual.user.type } else { "Unknown" }
    }

    Write-Verbose "AzureContext construido exitosamente para: $($contexto.Usuario)"
    return $contexto
}

#endregion Funciones Privadas

# Exportar función pública
Export-ModuleMember -Function Connect-HermesAzure -ErrorAction SilentlyContinue
