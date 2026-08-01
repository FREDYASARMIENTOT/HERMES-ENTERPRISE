<#
.SYNOPSIS
    Registro central de capacidades disponibles en el framework Hermes.
.DESCRIPTION
    CapabilityRegistry.ps1 implementa un registro in-memory de capacidades.
    Permite:
    - Registrar nuevas capacidades (New-CapabilityRegistration)
    - Consultar capacidades registradas (Get-CapabilityRegistration, Get-AllCapabilityRegistrations)
    - Verificar si una capacidad estÃ¡ disponible (Test-CapabilityRegistration)
    
    El registry mantiene una tabla hash global $script:CapabilityRegistry
    que persiste durante la sesiÃ³n actual de PowerShell.
    
    No implementa ninguna capacidad concreta. No conoce Azure, GitHub, Docker
    ni ningÃºn proveedor especÃ­fico. Solo gestiona metadatos de definiciÃ³n.
.NOTES
    Sprint: 6.0
    Fase: 6 - Capabilities
    Fecha: 2026-07-10
    VersiÃ³n: 1.0.0
#>

Set-StrictMode -Version Latest

# Tabla hash global que almacena todas las capacidades registradas
$script:CapabilityRegistry = @{}

function New-CapabilityRegistration {
    <#
    .SYNOPSIS
        Registra una nueva capacidad en el registry global.
    .DESCRIPTION
        AÃ±ade una definiciÃ³n de capacidad al registro central.
        Si ya existe una capacidad con el mismo nombre, lanza un error
        para evitar duplicados accidentales.
        
        Esta funciÃ³n solo registra metadatos. No ejecuta la capacidad,
        no accede al sistema de archivos, no consulta proveedores externos.
    .PARAMETER DefinicionCapacidad
        Objeto del tipo Hermes.Capabilities.Definition (creado con New-CapabilityDefinition).
    .OUTPUTS
        [bool] - $true si el registro fue exitoso.
    .EXAMPLE
        $definition = New-CapabilityDefinition -NombreCapacidad 'TestCapability'
        $exitoso = New-CapabilityRegistration -DefinicionCapacidad $definition
    .NOTES
        Si el nombre ya existe, la funciÃ³n lanza un error.
        Para reemplazar una capacidad existente, primero use Remove-CapabilityRegistration.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$DefinicionCapacidad
    )
    
    # Validar tipo usando la propiedad Tipo explicita (PSTypeName no es accesible)
    if ($DefinicionCapacidad.Tipo -ne 'Hermes.Capabilities.Definition') {
        throw 'La definicion debe ser del tipo Hermes.Capabilities.Definition.'
    }
    
    # Validar que no exista duplicado
    $nombreCapacidad = $DefinicionCapacidad.NombreCapacidad.Trim().ToLower()
    
    if ($script:CapabilityRegistry.ContainsKey($nombreCapacidad)) {
        throw "La capacidad '$($DefinicionCapacidad.NombreCapacidad)' ya estÃ¡ registrada. Use Remove-CapabilityRegistration primero."
    }
    
    # Registrar con timestamp
    $script:CapabilityRegistry[$nombreCapacidad] = [PSCustomObject]@{
        PSTypeName                  = 'Hermes.Capabilities.Registration'
        DefinicionCapacidad         = $DefinicionCapacidad
        FechaRegistro               = [datetime]::UtcNow
        EstadoRegistro              = 'Registrada'
    }
    
    return $true
}

function Get-CapabilityRegistration {
    <#
    .SYNOPSIS
        Obtiene la definiciÃ³n de una capacidad especÃ­fica del registry.
    .DESCRIPTION
        Busca una capacidad por nombre y devuelve su definiciÃ³n completa.
        Si la capacidad no existe, devuelve $null.
        
        La bÃºsqueda es case-insensitive.
    .PARAMETER NombreCapacidad
        Nombre de la capacidad a buscar.
    .OUTPUTS
        PSCustomObject (Hermes.Capabilities.Definition) o $null si no existe.
    .EXAMPLE
        $def = Get-CapabilityRegistration -NombreCapacidad 'AzureResourceDiscovery'
        if ($def -ne $null) {
            Write-Output "Capacidad encontrada: $($def.NombreCapacidad) v$($def.VersionCapacidad)"
        }
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$NombreCapacidad
    )
    
    if ([string]::IsNullOrWhiteSpace($NombreCapacidad)) {
        throw 'El parÃ¡metro NombreCapacidad es obligatorio.'
    }
    
    $nombreNormalizado = $NombreCapacidad.Trim().ToLower()
    
    if ($script:CapabilityRegistry.ContainsKey($nombreNormalizado)) {
        return $script:CapabilityRegistry[$nombreNormalizado].DefinicionCapacidad
    }
    
    return $null
}

function Get-AllCapabilityRegistrations {
    <#
    .SYNOPSIS
        Devuelve todas las capacidades registradas.
    .DESCRIPTION
        Retorna un arreglo con las definiciones de todas las capacidades
        actualmente registradas en el registry.
        
        El orden no estÃ¡ garantizado (depende del hashtable interno).
    .OUTPUTS
        PSCustomObject[] - Arreglo de definiciones de capacidades.
    .EXAMPLE
        $todas = Get-AllCapabilityRegistrations
        Write-Output "Total de capacidades registradas: $($todas.Count)"
        $todas | ForEach-Object { Write-Output "  - $($_.NombreCapacidad)" }
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()
    
    $definiciones = @()
    
    foreach ($entry in $script:CapabilityRegistry.Values) {
        $definiciones += $entry.DefinicionCapacidad
    }
    
    return $definiciones
}

function Test-CapabilityRegistration {
    <#
    .SYNOPSIS
        Verifica si una capacidad estÃ¡ registrada.
    .DESCRIPTION
        Comprueba si existe una capacidad con el nombre especificado
        en el registry actual.
        
        La bÃºsqueda es case-insensitive.
    .PARAMETER NombreCapacidad
        Nombre de la capacidad a verificar.
    .OUTPUTS
        [bool] - $true si la capacidad existe, $false en caso contrario.
    .EXAMPLE
        if (Test-CapabilityRegistration -NombreCapacidad 'AzureResourceDiscovery') {
            Write-Output "La capacidad Azure estÃ¡ disponible."
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)][string]$NombreCapacidad
    )
    
    if ([string]::IsNullOrWhiteSpace($NombreCapacidad)) {
        return $false
    }
    
    $nombreNormalizado = $NombreCapacidad.Trim().ToLower()
    return $script:CapabilityRegistry.ContainsKey($nombreNormalizado)
}

function Remove-CapabilityRegistration {
    <#
    .SYNOPSIS
        Elimina una capacidad del registry.
    .DESCRIPTION
        Remueve una capacidad registrada por nombre.
        Si la capacidad no existe, no lanza error (diseÃ±o idempotente).
        
        Use esta funciÃ³n antes de registrar una nueva versiÃ³n de una capacidad
        que ya existe en el registry.
    .PARAMETER NombreCapacidad
        Nombre de la capacidad a eliminar.
    .OUTPUTS
        [bool] - $true si la capacidad fue eliminada, $false si no existÃ­a.
    .EXAMPLE
        $eliminado = Remove-CapabilityRegistration -NombreCapacidad 'OldCapability'
        Write-Output "Capacidad eliminada: $eliminado"
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)][string]$NombreCapacidad
    )
    
    if ([string]::IsNullOrWhiteSpace($NombreCapacidad)) {
        return $false
    }
    
    $nombreNormalizado = $NombreCapacidad.Trim().ToLower()
    
    if ($script:CapabilityRegistry.ContainsKey($nombreNormalizado)) {
        $null = $script:CapabilityRegistry.Remove($nombreNormalizado)
        return $true
    }
    
    return $false
}

function Get-CapabilityRegistrationCount {
    <#
    .SYNOPSIS
        Devuelve el nÃºmero total de capacidades registradas.
    .DESCRIPTION
        Retorna un conteo de cuÃ¡ntas capacidades hay actualmente
        en el registry global.
    .OUTPUTS
        [int] - Cantidad de capacidades registradas.
    .EXAMPLE
        $cantidad = Get-CapabilityRegistrationCount
        Write-Output "Capacidades registradas: $cantidad"
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param()
    
    return $script:CapabilityRegistry.Count
}

function Clear-AllCapabilityRegistrations {
    <#
    .SYNOPSIS
        Elimina todas las capacidades del registry.
    .DESCRIPTION
        Limpia completamente el registry global de capacidades.
        
        Esta funciÃ³n es Ãºtil para pruebas unitarias o para reiniciar
        el estado del sistema de capacidades durante el desarrollo.
        
        Use con precauciÃ³n en producciÃ³n.
    .OUTPUTS
        [void]
    .EXAMPLE
        Clear-AllCapabilityRegistrations
        Write-Output "Registry de capacidades limpiado."
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    
    $script:CapabilityRegistry.Clear()
}
