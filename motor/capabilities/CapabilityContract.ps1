<#
.SYNOPSIS
    Define el contrato de una capacidad reutilizable dentro del framework Hermes.
.DESCRIPTION
    CapabilityContract.ps1 contiene los constructores y tipos que representan
    una capacidad abstracta. No implementa logica concreta ni conoce proveedores
    especificos. Solo define datos.
    
    Este archivo define:
    - New-CapabilityRequirement: crea un requisito de la capacidad
    - New-CapabilityOutcome: describe un resultado esperado
    - New-CapabilityDefinition: crea una definicion completa de capacidad
    
    El contrato es puro: no ejecuta nada, no consulta nada, no persiste nada.
.NOTES
    Sprint: 6.0 | Fase: 6 - Capabilities
    Fecha: 2026-07-10 | Version: 1.0.0
#>

Set-StrictMode -Version Latest

function New-CapabilityRequirement {
    <#
    .SYNOPSIS
        Crea un requerimiento que una capacidad debe cumplir.
    .DESCRIPTION
        Un requisito describe una condicion necesaria antes de ejecutar la capacidad.
    .PARAMETER NombreRequisito
        Nombre unico del requisito dentro de la capacidad.
    .PARAMETER DescripcionRequisito
        Descripcion libre del requisito.
    .PARAMETER EsObligatorio
        Indica si la capacidad no puede ejecutarse sin este requisito.
    .OUTPUTS
        PSCustomObject de tipo Hermes.Capabilities.Requisito
    .EXAMPLE
        $req = New-CapabilityRequirement -NombreRequisito 'TokenActivo' -EsObligatorio $true
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreRequisito,
        
        [Parameter()]
        [string]$DescripcionRequisito = '',
        
        [Parameter()]
        [bool]$EsObligatorio = $true
    )
    
    $obj = [PSCustomObject]@{
        PSTypeName           = 'Hermes.Capabilities.Requisito'
        NombreRequisito      = $NombreRequisito.Trim()
        DescripcionRequisito = $DescripcionRequisito.Trim()
        EsObligatorio        = $EsObligatorio
    }
    
    # Propiedad leible explicita (PSTypeName no es accesible desde el objeto)
    $obj.PSObject.Properties.Add([PSNoteProperty]::new('Tipo', 'Hermes.Capabilities.Requisito'))
    return $obj
}

function New-CapabilityOutcome {
    <#
    .SYNOPSIS
        Crea un resultado esperado tras ejecutar una capacidad.
    .DESCRIPTION
        Describe un artefacto o efecto que produce la capacidad.
    .PARAMETER NombreResultado
        Nombre identificador del resultado.
    .PARAMETER DescripcionResultado
        Descripcion libre del resultado.
    .PARAMETER TipoResultado
        Tipo logico: Recurso, Archivo, Estado, Otro.
    .OUTPUTS
        PSCustomObject de tipo Hermes.Capabilities.Resultado
    .EXAMPLE
        $out = New-CapabilityOutcome -NombreResultado 'ResourceGroup' -TipoResultado 'Recurso'
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreResultado,
        
        [Parameter()]
        [string]$DescripcionResultado = '',
        
        [Parameter()]
        [ValidateSet('Recurso', 'Archivo', 'Estado', 'Otro')]
        [string]$TipoResultado = 'Otro'
    )
    
    $obj = [PSCustomObject]@{
        PSTypeName           = 'Hermes.Capabilities.Resultado'
        NombreResultado      = $NombreResultado.Trim()
        DescripcionResultado = $DescripcionResultado.Trim()
        TipoResultado        = $TipoResultado
    }
    
    $obj.PSObject.Properties.Add([PSNoteProperty]::new('Tipo', 'Hermes.Capabilities.Resultado'))
    return $obj
}

function New-CapabilityDefinition {
    <#
    .SYNOPSIS
        Crea la definicion formal de una capacidad.
    .DESCRIPTION
        Devuelve un objeto declarativo con nombre unico, descripcion, version,
        requisitos y resultados. NO ejecuta ni registra nada.
    .PARAMETER NombreCapacidad
        Identificador unico (ej: 'AzureResourceDiscovery').
    .PARAMETER DescripcionCapacidad
        Descripcion breve del proposito.
    .PARAMETER VersionCapacidad
        Version semantica (ej: '1.0.0').
    .PARAMETER RequisitosCapacidad
        Arreglo de New-CapabilityRequirement.
    .PARAMETER ResultadosCapacidad
        Arreglo de New-CapabilityOutcome.
    .OUTPUTS
        PSCustomObject de tipo Hermes.Capabilities.Definition
    .EXAMPLE
        $def = New-CapabilityDefinition -NombreCapacidad 'MiCapacidad'
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreCapacidad,
        
        [Parameter()]
        [string]$DescripcionCapacidad = '',
        
        [Parameter()]
        [string]$VersionCapacidad = '1.0.0',
        
        [Parameter()]
        [System.Collections.ArrayList]$RequisitosCapacidad,
        
        [Parameter()]
        [System.Collections.ArrayList]$ResultadosCapacidad
    )
    
    # Validar requisitos si existen
    $requisitosFinal = if ($null -eq $RequisitosCapacidad) { [System.Collections.ArrayList]::new() } else { $RequisitosCapacidad }
    $resultadosFinal = if ($null -eq $ResultadosCapacidad) { [System.Collections.ArrayList]::new() } else { $ResultadosCapacidad }
    
    foreach ($req in $requisitosFinal) {
        if ($req.Tipo -ne 'Hermes.Capabilities.Requisito') {
            throw "Elemento en RequisitosCapacidad no es de tipo Hermes.Capabilities.Requisito"
        }
    }
    
    foreach ($res in $resultadosFinal) {
        if ($res.Tipo -ne 'Hermes.Capabilities.Resultado') {
            throw "Elemento en ResultadosCapacidad no es de tipo Hermes.Capabilities.Resultado"
        }
    }
    
    $obj = [PSCustomObject]@{
        PSTypeName          = 'Hermes.Capabilities.Definition'
        NombreCapacidad     = $NombreCapacidad.Trim()
        DescripcionCapacidad = $DescripcionCapacidad.Trim()
        VersionCapacidad    = $VersionCapacidad.Trim()
        RequisitosCapacidad = $requisitosFinal
        ResultadosCapacidad = $resultadosFinal
    }
    
    $obj.PSObject.Properties.Add([PSNoteProperty]::new('Tipo', 'Hermes.Capabilities.Definition'))
    return $obj
}
