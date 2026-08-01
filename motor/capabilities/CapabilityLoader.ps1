<#
.SYNOPSIS
    Cargador de capacidades registradas en el framework Hermes.
.DESCRIPTION
    CapabilityLoader.ps1 implementa la carga de capacidades desde archivos .ps1.
    Permite:
    - Cargar definiciones desde rutas especÃ­ficas (Start-CapabilityLoading)
    - Cargar y registrar capacidades automÃ¡ticamente (Load-CapabilityFromPath)
    - Cargar todas las capacidades de un directorio (Load-AllCapabilitiesFromDirectory)
    
    El loader solo carga metadatos y definiciones. No ejecuta las capacidades,
    no accede a proveedores externos, no modifica el Bootstrap Engine.
    
    Cada archivo de capacidad debe contener una funciÃ³n que retorne un objeto
    del tipo Hermes.Capabilities.Definition.
.NOTES
    Sprint: 6.0
    Fase: 6 - Capabilities
    Fecha: 2026-07-10
    VersiÃ³n: 1.0.0
#>

Set-StrictMode -Version Latest

function Start-CapabilityLoading {
    <#
    .SYNOPSIS
        Carga una definiciÃ³n de capacidad desde un archivo .ps1.
    .DESCRIPTION
        Ejecuta el script PowerShell especificado y espera que retorne
        un objeto del tipo Hermes.Capabilities.Definition.
        
        Esta funciÃ³n solo carga la definiciÃ³n en memoria.
        No registra la capacidad en el Registry. Para registrar,
        use Load-CapabilityFromPath.
        
        El archivo debe:
        - Existir fÃ­sicamente
        - Ser ejecutable
        - Retornar un objeto Hermes.Capabilities.Definition
        - No contener dependencias de Azure, GitHub, Docker, etc.
    .PARAMETER RutaArchivoCapacidad
        Ruta absoluta o relativa al archivo .ps1 de la capacidad.
    .OUTPUTS
        PSCustomObject (Hermes.Capabilities.Definition) o lanza error si falla.
    .EXAMPLE
        $def = Start-CapabilityLoading -RutaArchivoCapacidad 'C:\Proyectos\MyCap.ps1'
        Write-Output "Capacidad cargada: $($def.NombreCapacidad)"
    .NOTES
        Esta funciÃ³n NO registra la capacidad.
        Use Load-CapabilityFromPath para cargar y registrar en un solo paso.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RutaArchivoCapacidad
    )
    
    # Validar que la ruta no estÃ© vacÃ­a
    if ([string]::IsNullOrWhiteSpace($RutaArchivoCapacidad)) {
        throw 'El parÃ¡metro RutaArchivoCapacidad es obligatorio.'
    }
    
    # Validar que el archivo exista
    if (-not (Test-Path -Path $RutaArchivoCapacidad -PathType Leaf)) {
        throw "El archivo de capacidad no existe: $RutaArchivoCapacidad"
    }
    
    # Validar que sea un archivo .ps1
    if (-not $RutaArchivoCapacidad.EndsWith('.ps1')) {
        throw "El archivo de capacidad debe tener extensiÃ³n .ps1: $RutaArchivoCapacidad"
    }
    
    # Ejecutar el script y capturar el resultado
    try {
        $resultado = & $RutaArchivoCapacidad
    }
    catch {
        throw "Error al cargar la capacidad desde '$RutaArchivoCapacidad': $_"
    }
    
    # Validar que el resultado sea una definiciÃ³n vÃ¡lida
    if ($null -eq $resultado) {
        throw "El archivo '$RutaArchivoCapacidad' no retornÃ³ ningÃºn objeto."
    }
    
    if ($resultado.PSTypeName -ne 'Hermes.Capabilities.Definition') {
        throw "El archivo '$RutaArchivoCapacidad' debe retornar un objeto de tipo Hermes.Capabilities.Definition, pero retornÃ³: $($resultado.PSTypeName)"
    }
    
    return $resultado
}

function Load-CapabilityFromPath {
    <#
    .SYNOPSIS
        Carga y registra una capacidad desde un archivo .ps1.
    .DESCRIPTION
        Combina la carga de la definiciÃ³n (Start-CapabilityLoading) con
        el registro automÃ¡tico en el CapabilityRegistry.
        
        Este es el mÃ©todo recomendado para agregar una nueva capacidad
        al framework de manera declarativa.
        
        Pasos que realiza:
        1. Valida que el archivo exista y sea ejecutable
        2. Ejecuta el script para obtener la definiciÃ³n
        3. Registra la capacidad en el CapabilityRegistry
        4. Retorna la definiciÃ³n registrada
        
        Si la capacidad ya estÃ¡ registrada, lanza un error.
    .PARAMETER RutaArchivoCapacidad
        Ruta absoluta o relativa al archivo .ps1 de la capacidad.
    .OUTPUTS
        PSCustomObject (Hermes.Capabilities.Definition) - La definiciÃ³n registrada.
    .EXAMPLE
        $def = Load-CapabilityFromPath -RutaArchivoCapacidad 'C:\Capabilities\Azure.ps1'
        Write-Output "Capacidad registrada: $($def.NombreCapacidad) v$($def.VersionCapacidad)"
    .NOTES
        Si la capacidad ya existe en el registry, use Remove-CapabilityRegistration
        antes de intentar cargarla nuevamente.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RutaArchivoCapacidad
    )
    
    # Cargar la definiciÃ³n desde el archivo
    $definicion = Start-CapabilityLoading -RutaArchivoCapacidad $RutaArchivoCapacidad
    
    # Registrar en el CapabilityRegistry
    $null = New-CapabilityRegistration -DefinicionCapacidad $definicion
    
    return $definicion
}

function Load-AllCapabilitiesFromDirectory {
    <#
    .SYNOPSIS
        Carga y registra todas las capacidades de un directorio.
    .DESCRIPTION
        Busca recursivamente archivos .ps1 en el directorio especificado
        y carga cada uno como una capacidad independiente.
        
        Cada archivo debe cumplir con el contrato de capacidad:
        - Retornar un objeto Hermes.Capabilities.Definition
        - No tener dependencias externas (Azure, GitHub, Docker)
        - Ser auto-contenido
        
        Los archivos que no cumplan el contrato se ignoran con una advertencia.
    .PARAMETER RutaDirectorioCapacidades
        Ruta absoluta o relativa al directorio que contiene las capacidades.
    .PARAMETER BuscarRecursivamente
        Si estÃ¡ presente, busca en subdirectorios. Por defecto, solo busca en el directorio raÃ­z.
    .OUTPUTS
        PSCustomObject[] - Arreglo de definiciones cargadas y registradas.
    .EXAMPLE
        $cargadas = Load-AllCapabilitiesFromDirectory -RutaDirectorioCapacidades 'C:\Proyecto\capabilities'
        Write-Output "Total de capacidades cargadas: $($cargadas.Count)"
    .EXAMPLE
        $cargadas = Load-AllCapabilitiesFromDirectory -RutaDirectorioCapacidades 'C:\Proyecto\capabilities' -BuscarRecursivamente
        foreach ($cap in $cargadas) {
            Write-Output "  - $($cap.NombreCapacidad) v$($cap.VersionCapacidad)"
        }
    .NOTES
        Esta funciÃ³n ignora archivos que:
        - No tienen extensiÃ³n .ps1
        - Lanzan excepciones al ejecutarse
        - No retornan un objeto Hermes.Capabilities.Definition
        - Ya estÃ¡n registrados en el CapabilityRegistry
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RutaDirectorioCapacidades,
        
        [Parameter(Mandatory = $false)]
        [switch]$BuscarRecursivamente
    )
    
    # Validar que la ruta del directorio exista
    if (-not (Test-Path -Path $RutaDirectorioCapacidades -PathType Container)) {
        throw "El directorio de capacidades no existe: $RutaDirectorioCapacidades"
    }
    
    # Construir parÃ¡metros para Get-ChildItem
    $parametrosBusqueda = @{
        Path   = $RutaDirectorioCapacidades
        Filter = '*.ps1'
        File   = $true
    }
    
    if ($BuscarRecursivamente) {
        $parametrosBusqueda['Recurse'] = $true
    }
    
    # Buscar todos los archivos .ps1
    $archivosCapacidad = Get-ChildItem @parametrosBusqueda
    
    if ($null -eq $archivosCapacidad -or $archivosCapacidad.Count -eq 0) {
        Write-Warning "No se encontraron archivos .ps1 en el directorio: $RutaDirectorioCapacidades"
        return @()
    }
    
    # Cargar cada capacidad
    $definicionesCargadas = [System.Collections.ArrayList]::new()
    
    foreach ($archivo in $archivosCapacidad) {
        try {
            $definicion = Load-CapabilityFromPath -RutaArchivoCapacidad $archivo.FullName
            $null = $definicionesCargadas.Add($definicion)
        }
        catch {
            Write-Warning "No se pudo cargar la capacidad desde '$($archivo.FullName)': $_"
        }
    }
    
    return $definicionesCargadas.ToArray()
}
