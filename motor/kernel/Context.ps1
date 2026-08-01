<#
.SYNOPSIS
    Implementación del contrato IContext — Contexto compartido de ejecución del Kernel.

.DESCRIPTION
    Context es el primer objeto creado durante el arranque del Kernel y el último
    en ser liberado. Concentra la información base del sistema: rutas, metadatos,
    entorno, versión e identificador de correlación (GUID). Implementa el contrato
    IContext definido en KERNEL_CONTRACT_SPECIFICATION.md (Sección 5, v1.0.0).

    Principios aplicados:
    - Contract First: implementa exactamente el contrato IContext
    - Fail Fast: valida todos los parámetros en el constructor
    - Immutable: el ContextId nunca cambia; las rutas base nunca son null/vacías
    - Event Drive: publica eventos Context.Created, Context.PropertyChanged, Context.Validated

.PARAMETER ProjectName
    Nombre del proyecto. Debe tener entre 3 y 64 caracteres alfanuméricos.

.PARAMETER RepositoryRoot
    Ruta absoluta de la raíz del repositorio. Debe ser una ruta absoluta válida.

.PARAMETER KernelVersion
    Versión del Kernel. Debe ser semántica (X.Y.Z).

.PARAMETER EnvironmentName
    Nombre del entorno. Valores comunes: Desarrollo, Producción, Diagnóstico.

.PARAMETER MotorPath
    Ruta al directorio motor/. Si no se especifica, se asume <RepositoryRoot>\motor.

.PARAMETER ConfigurationPath
    Ruta al directorio de configuración. Si no se especifica, se asume <RepositoryRoot>\configuracion.

.PARAMETER LogsPath
    Ruta al directorio de logs. Si no se especifica, se asume <RepositoryRoot>\logs.

.EXAMPLE
    $context = [Context]::new("HermesEnterprise", "D:\HERMES-ENTERPRISE", "1.0.0", "Desarrollo")

.NOTES
    Contrato: IContext v1.0.0
    Work Package: WP-010
    Fase: F1 Kernel
#>

class Context {
    # --------------------------------------------------------------------------
    # Propiedades privadas
    # --------------------------------------------------------------------------
    hidden [hashtable] $_properties
    hidden [guid] $_contextId
    hidden [datetime] $_createdAt
    hidden [System.Collections.ArrayList] $_eventQueue
    hidden [bool] $_disposed

    # --------------------------------------------------------------------------
    # Constructor
    # --------------------------------------------------------------------------
    Context(
        [string] $ProjectName,
        [string] $RepositoryRoot,
        [string] $KernelVersion,
        [string] $EnvironmentName,
        [string] $MotorPath,
        [string] $ConfigurationPath,
        [string] $LogsPath
    ) {
        # Validar parámetros obligatorios
        $this._ValidateConstructorParameters(
            $ProjectName,
            $RepositoryRoot,
            $KernelVersion,
            $EnvironmentName
        )

        # Inicializar identificadores
        $this._contextId = [guid]::NewGuid()
        $this._createdAt = [datetime]::UtcNow
        $this._disposed = $false
        $this._eventQueue = [System.Collections.ArrayList]::new()

        # Normalizar rutas
        $resolvedRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
        $resolvedMotor = if (-not [string]::IsNullOrEmpty($MotorPath)) {
            [System.IO.Path]::GetFullPath($MotorPath)
        } else {
            [System.IO.Path]::Combine($resolvedRoot, "motor")
        }
        $resolvedConfig = if (-not [string]::IsNullOrEmpty($ConfigurationPath)) {
            [System.IO.Path]::GetFullPath($ConfigurationPath)
        } else {
            [System.IO.Path]::Combine($resolvedRoot, "configuracion")
        }
        $resolvedLogs = if (-not [string]::IsNullOrEmpty($LogsPath)) {
            [System.IO.Path]::GetFullPath($LogsPath)
        } else {
            [System.IO.Path]::Combine($resolvedRoot, "logs")
        }

        # Inicializar propiedades predeterminadas
        $this._properties = @{
            # Propiedades estándar del contrato (nombres en español según KERNEL_CONTRACT_SPECIFICATION.md)
            "NombreProyecto"        = $ProjectName
            "VersionKernel"         = $KernelVersion
            "NombreEntorno"         = $EnvironmentName
            "RutaRaizRepositorio"   = $resolvedRoot
            "RutaMotor"             = $resolvedMotor
            "RutaConfiguracion"     = $resolvedConfig
            "RutaLogs"              = $resolvedLogs
            "FechaCreacion"         = $this._createdAt
            "IdentificadorContexto" = $this._contextId

            # Propiedades adicionales (no estándar, pero útiles para el sistema)
            "VersionContext"        = "1.0.0"
            "Plataforma"            = [System.Environment]::OSVersion.Platform.ToString()
            "Maquina"               = [System.Environment]::MachineName
            "Usuario"               = [System.Environment]::UserName
        }

        # Publicar evento de creación
        $this._EnqueueEvent("Context.Created", @{
            ContextId = $this._contextId
            Version   = $KernelVersion
        })
    }

    # Constructor con parámetros mínimos (usa valores por defecto para rutas secundarias)
    Context(
        [string] $ProjectName,
        [string] $RepositoryRoot,
        [string] $KernelVersion,
        [string] $EnvironmentName
    ) {
        # Llamada al constructor completo con valores por defecto
        $this._ValidateConstructorParameters(
            $ProjectName,
            $RepositoryRoot,
            $KernelVersion,
            $EnvironmentName
        )

        $this._contextId = [guid]::NewGuid()
        $this._createdAt = [datetime]::UtcNow
        $this._disposed = $false
        $this._eventQueue = [System.Collections.ArrayList]::new()

        $resolvedRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)

        $this._properties = @{
            "NombreProyecto"        = $ProjectName
            "VersionKernel"         = $KernelVersion
            "NombreEntorno"         = $EnvironmentName
            "RutaRaizRepositorio"   = $resolvedRoot
            "RutaMotor"             = [System.IO.Path]::Combine($resolvedRoot, "motor")
            "RutaConfiguracion"     = [System.IO.Path]::Combine($resolvedRoot, "configuracion")
            "RutaLogs"              = [System.IO.Path]::Combine($resolvedRoot, "logs")
            "FechaCreacion"         = $this._createdAt
            "IdentificadorContexto" = $this._contextId
            "VersionContext"        = "1.0.0"
            "Plataforma"            = [System.Environment]::OSVersion.Platform.ToString()
            "Maquina"               = [System.Environment]::MachineName
            "Usuario"               = [System.Environment]::UserName
        }

        $this._EnqueueEvent("Context.Created", @{
            ContextId = $this._contextId
            Version   = $KernelVersion
        })
    }

    # --------------------------------------------------------------------------
    # Métodos públicos del contrato IContext
    # --------------------------------------------------------------------------

    # Obtiene una propiedad del contexto
    [object] GetProperty([string] $Name) {
        $this._AssertNotDisposed()
        $this._AssertPropertyNameNotEmpty($Name)

        if (-not $this._properties.ContainsKey($Name)) {
            throw [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]"La propiedad '$Name' no existe en el contexto.",
                "ERR_CONTEXT_PROPERTY_NOT_FOUND",
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $Name
            )
        }

        return $this._properties[$Name]
    }

    # Establece una propiedad del contexto
    [void] SetProperty([string] $Name, [object] $Value) {
        $this._AssertNotDisposed()
        $this._AssertPropertyNameNotEmpty($Name)

        [object] $oldValue = $null
        $hasOldValue = $this._properties.ContainsKey($Name)
        if ($hasOldValue) {
            $oldValue = $this._properties[$Name]
        }

        $this._properties[$Name] = $Value

        # Publicar evento de cambio si es una propiedad existente
        if ($hasOldValue) {
            $this._EnqueueEvent("Context.PropertyChanged", @{
                PropertyName = $Name
                OldValue     = $oldValue
                NewValue     = $Value
            })
        }
    }

    # Verifica si una propiedad existe
    [bool] HasProperty([string] $Name) {
        $this._AssertNotDisposed()
        if ([string]::IsNullOrEmpty($Name)) {
            return $false
        }
        return $this._properties.ContainsKey($Name)
    }

    # Devuelve todas las propiedades
    [hashtable] GetAllProperties() {
        $this._AssertNotDisposed()
        return $this._properties.Clone()
    }

    # Devuelve el identificador único del contexto
    [guid] GetContextId() {
        $this._AssertNotDisposed()
        return $this._contextId
    }

    # Devuelve la fecha de creación
    [datetime] GetCreatedAt() {
        $this._AssertNotDisposed()
        return $this._createdAt
    }

    # Devuelve la versión del Kernel
    [string] GetVersion() {
        $this._AssertNotDisposed()
        return $this._properties["VersionKernel"]
    }

    # Devuelve el nombre del entorno
    [string] GetEnvironment() {
        $this._AssertNotDisposed()
        return $this._properties["NombreEntorno"]
    }

    # Devuelve la ruta raíz del repositorio
    [string] GetRepositoryRoot() {
        $this._AssertNotDisposed()
        return $this._properties["RutaRaizRepositorio"]
    }

    # Devuelve la ruta del directorio motor
    [string] GetMotorPath() {
        $this._AssertNotDisposed()
        return $this._properties["RutaMotor"]
    }

    # Devuelve la ruta de configuración
    [string] GetConfigurationPath() {
        $this._AssertNotDisposed()
        return $this._properties["RutaConfiguracion"]
    }

    # Devuelve la ruta de logs
    [string] GetLogsPath() {
        $this._AssertNotDisposed()
        return $this._properties["RutaLogs"]
    }

    # Valida que el contexto tenga todos los campos requeridos
    [bool] Validate() {
        $this._AssertNotDisposed()
        $errors = [System.Collections.ArrayList]::new()

        # Validar propiedades requeridas
        $requiredProperties = @(
            "NombreProyecto", "VersionKernel", "NombreEntorno",
            "RutaRaizRepositorio", "RutaMotor", "RutaConfiguracion", "RutaLogs"
        )

        foreach ($prop in $requiredProperties) {
            if (-not $this._properties.ContainsKey($prop)) {
                [void]$errors.Add("Propiedad requerida '$prop' no encontrada.")
                continue
            }

            $value = $this._properties[$prop]
            if ($null -eq $value -or ([string]::IsNullOrEmpty($value.ToString()))) {
                [void]$errors.Add("Propiedad requerida '$prop' está vacía o nula.")
            }
        }

        # Validar formato de versión semántica si existe
        if ($this._properties.ContainsKey("VersionKernel") -and $null -ne $this._properties["VersionKernel"]) {
            $versionPattern = '^\d+\.\d+\.\d+$'
            $version = $this._properties["VersionKernel"].ToString()
            if (-not ($version -match $versionPattern)) {
                [void]$errors.Add("'VersionKernel' no tiene formato semántico (X.Y.Z). Valor: $version")
            }
        }

        # Validar rutas absolutas
        $pathProperties = @("RutaRaizRepositorio", "RutaMotor", "RutaConfiguracion", "RutaLogs")
        foreach ($prop in $pathProperties) {
            if ($this._properties.ContainsKey($prop) -and $null -ne $this._properties[$prop]) {
                $path = $this._properties[$prop].ToString()
                if (-not [System.IO.Path]::IsPathRooted($path)) {
                    [void]$errors.Add("'$prop' no es una ruta absoluta. Valor: $path")
                }
            }
        }

        # Validar longitud del nombre del proyecto
        if ($this._properties.ContainsKey("NombreProyecto") -and $null -ne $this._properties["NombreProyecto"]) {
            $projectName = $this._properties["NombreProyecto"].ToString()
            if ($projectName.Length -lt 3 -or $projectName.Length -gt 64) {
                [void]$errors.Add("'NombreProyecto' debe tener entre 3 y 64 caracteres. Longitud actual: $($projectName.Length)")
            }
        }

        $isValid = $errors.Count -eq 0

        # Publicar evento de validación
        $this._EnqueueEvent("Context.Validated", @{
            IsValid = $isValid
            Errors  = @($errors.ToArray())
        })

        return $isValid
    }

    # --------------------------------------------------------------------------
    # Métodos de ciclo de vida
    # --------------------------------------------------------------------------

    # Libera recursos del contexto
    [void] Dispose() {
        if ($this._disposed) {
            return
        }
        $this._disposed = $true
        $this._properties.Clear()
        $this._eventQueue.Clear()
    }

    # Verifica si el contexto está disponible
    [bool] IsDisposed() {
        return $this._disposed
    }

    # Obtiene y limpia la cola de eventos pendientes
    [object[]] DrainEventQueue() {
        $events = @($this._eventQueue.ToArray())
        $this._eventQueue.Clear()
        return $events
    }

    # --------------------------------------------------------------------------
    # Métodos privados de validación
    # --------------------------------------------------------------------------

    # Valida que el contexto no esté disposed
    hidden [void] _AssertNotDisposed() {
        if ($this._disposed) {
            throw [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]"El contexto ya fue liberado (Disposed). No se pueden realizar operaciones.",
                "ERR_CONTEXT_DISPOSED",
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
        }
    }

    # Valida que el nombre de propiedad no esté vacío
    hidden [void] _AssertPropertyNameNotEmpty([string] $Name) {
        if ([string]::IsNullOrEmpty($Name)) {
            throw [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]"El nombre de la propiedad no puede estar vacío.",
                "ERR_CONTEXT_PROPERTY_INVALID",
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $Name
            )
        }
    }

    # Valida los parámetros del constructor
    hidden [void] _ValidateConstructorParameters(
        [string] $ProjectName,
        [string] $RepositoryRoot,
        [string] $KernelVersion,
        [string] $EnvironmentName
    ) {
        # Validar nombre del proyecto
        if ([string]::IsNullOrEmpty($ProjectName)) {
            throw [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]"'ProjectName' no puede estar vacío.",
                "ERR_CONTEXT_PROPERTY_INVALID",
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $ProjectName
            )
        }
        if ($ProjectName.Length -lt 3 -or $ProjectName.Length -gt 64) {
            throw [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]"'ProjectName' debe tener entre 3 y 64 caracteres. Longitud actual: $($ProjectName.Length)",
                "ERR_CONTEXT_PROPERTY_INVALID",
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $ProjectName
            )
        }

        # Validar ruta raíz
        if ([string]::IsNullOrEmpty($RepositoryRoot)) {
            throw [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]"'RepositoryRoot' no puede estar vacío.",
                "ERR_CONTEXT_PROPERTY_INVALID",
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $RepositoryRoot
            )
        }
        if (-not [System.IO.Path]::IsPathRooted($RepositoryRoot)) {
            throw [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]"'RepositoryRoot' debe ser una ruta absoluta. Valor actual: $RepositoryRoot",
                "ERR_CONTEXT_PROPERTY_INVALID",
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $RepositoryRoot
            )
        }

        # Validar versión del Kernel
        if ([string]::IsNullOrEmpty($KernelVersion)) {
            throw [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]"'KernelVersion' no puede estar vacío.",
                "ERR_CONTEXT_PROPERTY_INVALID",
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $KernelVersion
            )
        }
        $versionPattern = '^\d+\.\d+\.\d+$'
        if ($KernelVersion -notmatch $versionPattern) {
            throw [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]"'KernelVersion' debe tener formato semántico (X.Y.Z). Valor actual: $KernelVersion",
                "ERR_CONTEXT_PROPERTY_INVALID",
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $KernelVersion
            )
        }

        # Validar nombre del entorno
        if ([string]::IsNullOrEmpty($EnvironmentName)) {
            throw [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]"'EnvironmentName' no puede estar vacío.",
                "ERR_CONTEXT_PROPERTY_INVALID",
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $EnvironmentName
            )
        }
    }

    # --------------------------------------------------------------------------
    # Métodos privados de eventos
    # --------------------------------------------------------------------------

    # Encola un evento para publicación futura
    hidden [void] _EnqueueEvent([string] $EventName, [hashtable] $Payload) {
        $evt = @{
            id        = [guid]::NewGuid()
            eventName = $EventName
            timestamp = [datetime]::UtcNow.ToString("o")
            source    = "Context"
            payload   = $Payload
        }
        [void]$this._eventQueue.Add($evt)
    }
}
