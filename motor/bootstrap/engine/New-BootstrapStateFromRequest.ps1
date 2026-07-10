<#
.SYNOPSIS
    Convierte BootstrapRequest a BootstrapState inicial

.DESCRIPTION
    Función pura que recibe un BootstrapRequest validado y crea un BootstrapState 
    en fase inicial (Fase00, Estado=Pendiente). 
    
    NO modifica BootstrapRequest (es inmutable).
    NO ejecuta managers ni crea archivos.
    NO interactúa con el usuario.
    
    Responsabilidad única: construir estado inicial del motor.

.NOTES
    Autor: Hermes Agent
    Fecha: 2026-07-10
    Versión: 1.0.0
#>

function New-BootstrapStateFromRequest {
    <#
    .SYNOPSIS
        Crea un BootstrapState inicial a partir de un BootstrapRequest
    
    .DESCRIPTION
        Recibe un BootstrapRequest validado y retorna un BootstrapState 
        con configuración inicial. El BootstrapState tendrá:
        - Id único (GUID)
        - Fase: Fase00
        - Estado: Pendiente
        - StartedAt: timestamp actual
        - FinishedAt: $null
        
        Esta función no ejecuta ninguna lógica de negocio. Solo construye
        el estado inicial que BootstrapOrchestrator usará para coordinar
        la ejecución de los managers.
    
    .PARAMETER Request
        Objeto BootstrapRequest previamente validado (tipo: Hermes.Bootstrap.Request)
    
    .OUTPUTS
        PSCustomObject con tipo 'Hermes.Bootstrap.BootstrapState'
        - Id (string): GUID único
        - Fase (enum): BootstrapPhase.Fase00
        - Estado (enum): PhaseStatus.Pendiente
        - StartedAt (datetime): Timestamp de creación
        - FinishedAt (datetime): $null
    
    .EXAMPLE
        $request = New-BootstrapRequest -NombreProyecto "MiProyecto" -RutaProyecto "C:\Proyectos\MiProyecto"
        $state = New-BootstrapStateFromRequest -Request $request
        # $state ahora está listo para BootstrapOrchestrator
    
    .NOTES
        - No valida el Request (asume que ya fue validado)
        - No modifica el Request original (inmutabilidad)
        - No ejecuta managers ni crea archivos
        - Solo construye estado inicial
    #>
    
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$Request
    )
    
    # Validar que Request sea del tipo correcto
    if ($Request.PSObject.TypeNames[0] -ne 'Hermes.Bootstrap.Request') {
        throw "El parámetro Request debe ser del tipo 'Hermes.Bootstrap.Request'"
    }
    
    # Validar Request usando Test-BootstrapRequest
    $validacion = Test-BootstrapRequest -Request $Request
    if (-not $validacion.IsValid) {
        $errores = $validacion.Errors -join ', '
        throw "BootstrapRequest inválido: $errores"
    }
    
    # Crear BootstrapState inicial
    $state = New-HermesBootstrapState
    
    # Registrar referencia al Request (solo metadatos, no copia los datos)
    $state | Add-Member -MemberType NoteProperty -Name 'RequestMetadata' -Value @{
        RequestId = [guid]::NewGuid().ToString()
        NombreProyecto = $Request.NombreProyecto
        RutaProyecto = $Request.RutaProyecto
        FechaCreacionRequest = $Request.FechaCreacion
    } -Force
    
    # Registrar timestamp de conversión
    $state | Add-Member -MemberType NoteProperty -Name 'ConversionTimestamp' -Value ([datetime]::UtcNow.ToString('o')) -Force
    
    return $state
}
