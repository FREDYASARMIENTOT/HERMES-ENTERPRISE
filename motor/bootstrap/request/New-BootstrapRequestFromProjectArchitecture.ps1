<#
.SYNOPSIS
    Convierte ProjectArchitecture a BootstrapRequest

.DESCRIPTION
    Función pura que recibe un objeto ProjectArchitecture previamente validado
    y produce un BootstrapRequest completo.

    NO interactúa con el usuario.
    NO ejecuta comandos del sistema operativo.
    NO crea archivos ni carpetas.
    NO consulta Azure ni GitHub.

    Responsabilidad única: convertir modelo arquitectónico abstracto en solicitud física.

.NOTES
    Autor: Hermes Agent
    Fecha: 2026-07-10
    Versión: 1.0.0
    Sprint: 5.5
#>

function New-BootstrapRequestFromProjectArchitecture {
    <#
    .SYNOPSIS
        Crea un BootstrapRequest a partir de ProjectArchitecture

    .DESCRIPTION
        Recibe un objeto ProjectArchitecture validado y retorna un BootstrapRequest
        con todos los campos necesarios para iniciar el proceso de bootstrap.

        Mapeo de propiedades:
        - NombreProyecto → NombreProyecto
        - Descripción → DescripcionProyecto
        - RequiereFrontend → CrearFrontend
        - RequiereBackend → CrearBackend
        - FrameworkFrontend → RuntimeNode (default: "20.11.0")
        - FrameworkBackend → RuntimePython (default: "3.11")
        - RequiereGitHub → ProveedorGit ("GitHub" o "None")
        - RutaProyecto → generado automáticamente ($env:USERPROFILE\NombreProyecto)

        Esta función no interactúa con el usuario. Solo transforma datos.

    .PARAMETER ProjectArchitecture
        Objeto ProjectArchitecture previamente validado

    .OUTPUTS
        PSCustomObject con tipo 'Hermes.Bootstrap.Request'

    .EXAMPLE
        $architecture = New-ProjectArchitecture -NombreProyecto "MiProyecto" ...
        $request = New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $architecture
        # $request ahora está listo para New-BootstrapStateFromRequest

    .NOTES
        - No valida ProjectArchitecture (asume que ya fue validado)
        - No modifica el ProjectArchitecture original (inmutabilidad)
        - No ejecuta acciones sobre el sistema operativo
        - Solo transforma modelo arquitectónico en solicitud física
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$ProjectArchitecture
    )

    # Validar que ProjectArchitecture sea del tipo correcto
    if ($ProjectArchitecture.PSObject.TypeNames[0] -ne 'Hermes.Project.Architecture') {
        throw "El parámetro ProjectArchitecture debe ser del tipo 'Hermes.Project.Architecture'"
    }

    # Extraer propiedades de ProjectArchitecture
    $nombreProyecto = $ProjectArchitecture.NombreProyecto
    $descripcion = $ProjectArchitecture.Descripcion
    $requiereFrontend = $ProjectArchitecture.RequiereFrontend
    $requiereBackend = $ProjectArchitecture.RequiereBackend
    $frameworkFrontend = $ProjectArchitecture.FrameworkFrontend
    $frameworkBackend = $ProjectArchitecture.FrameworkBackend
    $requiereGitHub = $ProjectArchitecture.RequiereGitHub

    # Generar RutaProyecto automáticamente
    $rutaProyecto = Join-Path $env:USERPROFILE $nombreProyecto

    # Mapear RuntimeNode (default: "20.11.0" si requiere frontend)
    $runtimeNode = ""
    if ($requiereFrontend) {
        $runtimeNode = "20.11.0"
    }

    # Mapear RuntimePython (default: "3.11" si requiere backend)
    $runtimePython = ""
    if ($requiereBackend) {
        $runtimePython = "3.11"
    }

    # Mapear ProveedorGit
    $proveedorGit = "None"
    if ($requiereGitHub) {
        $proveedorGit = "GitHub"
    }

    # Construir BootstrapRequest
    try {
        $request = New-BootstrapRequest `
            -NombreProyecto $nombreProyecto `
            -RutaProyecto $rutaProyecto `
            -DescripcionProyecto $descripcion `
            -CrearFrontend $requiereFrontend `
            -CrearBackend $requiereBackend `
            -RuntimeNode $runtimeNode `
            -RuntimePython $runtimePython `
            -ProveedorGit $proveedorGit `
            -CrearGitIgnore $true `
            -CrearEnv $false `
            -AbrirVSCode $true

        return $request
    }
    catch {
        throw "Error al crear BootstrapRequest desde ProjectArchitecture: $_"
    }
}
