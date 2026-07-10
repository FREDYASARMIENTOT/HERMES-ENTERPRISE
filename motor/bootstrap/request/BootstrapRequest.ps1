<#
.SYNOPSIS
    Define el contrato DTO para solicitudes de bootstrap

.DESCRIPTION
    BootstrapRequest es un objeto inmutable que representa la solicitud
    completa de un usuario para crear un nuevo proyecto Hermes.

    Este DTO desacopla la captura de datos del usuario (que puede venir
    de múltiples interfaces: CLI, VS Code, API) del estado interno del
    motor de bootstrap.

    Flujo arquitectónico:
        Usuario → BootstrapRequestBuilder → BootstrapRequest → ConvertToBootstrapState → BootstrapState → Orquestador

.NOTES
    Autor: Hermes Agent
    Fecha: 2026-07-10
    Versión: 1.0.0

    Principios:
    - Inmutabilidad: una vez creado, no se modifica
    - Validación: todas las propiedades están validadas en el builder
    - Transporte: puede serializarse a JSON sin pérdida de información
    - Extensibilidad: nuevas propiedades se agregan aquí sin romper compatibilidad
#>

function New-BootstrapRequest {
    <#
    .SYNOPSIS
        Construye un nuevo objeto BootstrapRequest

    .DESCRIPTION
        Crea un DTO inmutable con todas las propiedades necesarias para
        iniciar un proceso de bootstrap completo.

    .PARAMETER NombreProyecto
        Nombre del proyecto (3-64 caracteres, A-Za-z0-9_-)

    .PARAMETER RutaProyecto
        Ruta absoluta donde se creará el proyecto

    .PARAMETER RutaEnvironment
        Ruta absoluta del entorno virtual Python (si aplica)

    .PARAMETER CrearFrontend
        Indica si se debe crear estructura de frontend

    .PARAMETER CrearBackend
        Indica si se debe crear estructura de backend

    .PARAMETER ProveedorGit
        Proveedor de git remoto (GitHub, GitLab, bitbucket, None)

    .PARAMETER RutaRepositorioLocal
        Ruta al repositorio local existente (si no es nuevo)

    .PARAMETER CrearNuevoRepositorio
        Indica si se debe crear un nuevo repositorio git

    .PARAMETER URLRemoto
        URL del repositorio remoto (si Clonar o Conectar)

    .PARAMETER AccionRepositorio
        Acción sobre el repositorio (Nuevo, Clonar, Conectar, Ninguno)

    .PARAMETER DescripcionProyecto
        Descripción opcional del proyecto

    .PARAMETER RuntimePython
        Versión de Python requerida (ej: "3.11")

    .PARAMETER RuntimeNode
        Versión de Node.js requerida (ej: "20.11.0")

    .PARAMETER CrearGitIgnore
        Indica si se debe crear archivo .gitignore

    .PARAMETER CrearEnv
        Indica si se debe crear entorno virtual Python

    .PARAMETER AbrirVSCode
        Indica si se debe abrir VS Code al finalizar

    .OUTPUTS
        PSCustomObject con tipo 'Hermes.Bootstrap.Request'
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[a-zA-Z0-9_-]{3,64}$', ErrorMessage = 'Debe tener 3-64 caracteres: letras, números, guiones bajos o guiones')]
        [string]$NombreProyecto,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RutaProyecto,

        [Parameter()]
        [string]$RutaEnvironment = '',

        [Parameter()]
        [bool]$CrearFrontend = $false,

        [Parameter()]
        [bool]$CrearBackend = $false,

        [Parameter()]
        [ValidateSet('GitHub', 'GitLab', 'Bitbucket', 'None')]
        [string]$ProveedorGit = 'None',

        [Parameter()]
        [string]$RutaRepositorioLocal = '',

        [Parameter()]
        [bool]$CrearNuevoRepositorio = $false,

        [Parameter()]
        [string]$URLRemoto = '',

        [Parameter()]
        [ValidateSet('Nuevo', 'Clonar', 'Conectar', 'Ninguno')]
        [string]$AccionRepositorio = 'Ninguno',

        [Parameter()]
        [string]$DescripcionProyecto = '',

        [Parameter()]
        [string]$RuntimePython = '3.11',

        [Parameter()]
        [string]$RuntimeNode = '',

        [Parameter()]
        [bool]$CrearGitIgnore = $true,

        [Parameter()]
        [bool]$CrearEnv = $true,

        [Parameter()]
        [bool]$AbrirVSCode = $true
    )

    # Validaciones cruzadas
    if ($CrearNuevoRepositorio -and $ProveedorGit -eq 'None') {
        throw "No se puede crear un nuevo repositorio sin especificar un proveedor Git"
    }

    if ($AccionRepositorio -eq 'Nuevo' -and [string]::IsNullOrWhiteSpace($URLRemoto)) {
        # URL se genera automáticamente, está OK
    }

    if ($AccionRepositorio -eq 'Clonar' -and [string]::IsNullOrWhiteSpace($URLRemoto)) {
        throw "La acción 'Clonar' requiere especificar una URL remota"
    }

    if ($AccionRepositorio -eq 'Conectar' -and [string]::IsNullOrWhiteSpace($RutaRepositorioLocal)) {
        throw "La acción 'Conectar' requiere especificar una ruta de repositorio local existente"
    }

    if ($CrearBackend -and [string]::IsNullOrWhiteSpace($RuntimePython)) {
        throw "Si se crea backend, debe especificarse una versión de Python"
    }

    if ($CrearFrontend -and [string]::IsNullOrWhiteSpace($RuntimeNode)) {
        throw "Si se crea frontend, debe especificarse una versión de Node.js"
    }

    # Construir objeto inmutable
    $request = [PSCustomObject]@{
        PSTypeName = 'Hermes.Bootstrap.Request'
        
        # Identificación
        NombreProyecto = $NombreProyecto
        RutaProyecto = $RutaProyecto
        DescripcionProyecto = $DescripcionProyecto

        # Estructura
        CrearFrontend = $CrearFrontend
        CrearBackend = $CrearBackend

        # Runtimes
        RuntimePython = $RuntimePython
        RuntimeNode = $RuntimeNode

        # Entorno Python
        RutaEnvironment = $RutaEnvironment
        CrearEnv = $CrearEnv

        # Git y repositorio
        ProveedorGit = $ProveedorGit
        RutaRepositorioLocal = $RutaRepositorioLocal
        CrearNuevoRepositorio = $CrearNuevoRepositorio
        URLRemoto = $URLRemoto
        AccionRepositorio = $AccionRepositorio
        CrearGitIgnore = $CrearGitIgnore

        # Experiencia
        AbrirVSCode = $AbrirVSCode

        # Metadata
        FechaCreacion = [datetime]::UtcNow
        Version = '1.0.0'
    }

    return $request
}

function Test-BootstrapRequest {
    <#
    .SYNOPSIS
        Valida un objeto BootstrapRequest

    .DESCRIPTION
        Verifica que el objeto pasado sea un BootstrapRequest válido
        y que todas sus propiedades cumplan las reglas de negocio.

    .PARAMETER Request
        Objeto BootstrapRequest a validar

    .OUTPUTS
        PSCustomObject con IsValid (bool) y Errors (string[])
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Request
    )

    $errors = @()

    # Verificar tipo
    if ($Request.PSObject.TypeNames[0] -ne 'Hermes.Bootstrap.Request') {
        $errors += "El objeto no es de tipo 'Hermes.Bootstrap.Request'"
        return [PSCustomObject]@{
            IsValid = $false
            Errors = $errors
        }
    }

    # Validar propiedades obligatorias
    if ([string]::IsNullOrWhiteSpace($Request.NombreProyecto)) {
        $errors += "NombreProyecto no puede estar vacío"
    }

    if ($Request.NombreProyecto -notmatch '^[a-zA-Z0-9_-]{3,64}$') {
        $errors += "NombreProyecto debe tener 3-64 caracteres: letras, números, guiones bajos o guiones"
    }

    if ([string]::IsNullOrWhiteSpace($Request.RutaProyecto)) {
        $errors += "RutaProyecto no puede estar vacía"
    }

    # Validar consistencia de repositorio
    if ($Request.CrearNuevoRepositorio -and $Request.ProveedorGit -eq 'None') {
        $errors += "No se puede crear un nuevo repositorio sin especificar un proveedor Git"
    }

    if ($Request.AccionRepositorio -eq 'Clonar' -and [string]::IsNullOrWhiteSpace($Request.URLRemoto)) {
        $errors += "La acción 'Clonar' requiere especificar una URL remota"
    }

    if ($Request.AccionRepositorio -eq 'Conectar' -and [string]::IsNullOrWhiteSpace($Request.RutaRepositorioLocal)) {
        $errors += "La acción 'Conectar' requiere especificar una ruta de repositorio local existente"
    }

    # Validar consistencia de runtimes
    if ($Request.CrearBackend -and [string]::IsNullOrWhiteSpace($Request.RuntimePython)) {
        $errors += "Si se crea backend, debe especificarse una versión de Python"
    }

    if ($Request.CrearFrontend -and [string]::IsNullOrWhiteSpace($Request.RuntimeNode)) {
        $errors += "Si se crea frontend, debe especificarse una versión de Node.js"
    }

    return [PSCustomObject]@{
        IsValid = $errors.Count -eq 0
        Errors = $errors
    }
}
