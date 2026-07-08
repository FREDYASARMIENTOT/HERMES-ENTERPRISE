<#
.SYNOPSIS
    Contrato puro del Bootstrap Engine v1.0.
.DESCRIPTION
    Paso 1: SOLO contratos. Sin snapshots, sin domain objects, sin lógica operativa.
    Define el estado compartido y su ciclo de vida (creación, clonación, serialización, validación).
    Inmutabilidad preservada: toda mutación retorna un nuevo objeto.
.NOTES
    Proyecto    : HERMES-ENTERPRISE
    Autor       : Fredy Alejandro Sarmiento Torres
    Version     : 1.0.1 (refactor minimalista)
#>

Set-StrictMode -Version Latest

# ─────────────────────────────────────────────────────────────────
# ENUMS
# ─────────────────────────────────────────────────────────────────

enum BootstrapPhase {
    Fase00 = 0
    Fase01 = 1
    Fase02 = 2
    Fase03 = 3
    Fase04 = 4
    Fase05 = 5
    Fase06 = 6
    Fase07 = 7
    Fase08 = 8
    Fase09 = 9
    Fase10 = 10
    Fase11 = 11
    Fase12 = 12
    Fase13 = 13
}

enum PhaseStatus {
    Pending    = 0
    Running    = 1
    Completed  = 2
    Failed     = 3
    RolledBack = 4
}

# ─────────────────────────────────────────────────────────────────
# TIPO BASE: BootstrapState
# ─────────────────────────────────────────────────────────────────

function New-HermesBootstrapState {
    <#
    .SYNOPSIS
        Constructor del estado inicial del Bootstrap.
    .DESCRIPTION
        Devuelve un objeto inmutable con todos los campos en su estado neutro.
        Los campos complejos (snapshots, logs, etc.) quedan pendientes de
        definición en sprints posteriores.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [guid]$CorrelationId = [guid]::NewGuid()
    )

    return [PSCustomObject][ordered]@{
        PSTypeName   = "Hermes.Bootstrap.BootstrapState"
        Id           = $CorrelationId.ToString()
        Phase        = [BootstrapPhase]::Fase00
        Status       = [PhaseStatus]::Pending
        StartedAt    = [datetime]::UtcNow.ToString("o")
        FinishedAt   = $null
    }
}

function Copy-HermesBootstrapState {
    <#
    .SYNOPSIS
        Clona el estado via JSON round-trip (copia profunda).
    .DESCRIPTION
        Preserva inmutabilidad: el original nunca se modifica.
        Los overrides se aplican solo al clone resultante.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$State,

        [Parameter(Mandatory = $false)]
        [hashtable]$Overrides = @{}
    )

    $json = $State | ConvertTo-Json -Depth 10
    $clon = $json | ConvertFrom-Json

    foreach ($k in $Overrides.Keys) {
        if ($null -eq $clon.PSObject.Properties[$k]) {
            $clon | Add-Member -NotePropertyName $k -NotePropertyValue $Overrides[$k]
        } else {
            $clon.$k = $Overrides[$k]
        }
    }

    if (-not $clon.PSObject.TypeNames.Contains("Hermes.Bootstrap.BootstrapState")) {
        $clon.PSObject.TypeNames.Insert(0, "Hermes.Bootstrap.BootstrapState")
    }
    return $clon
}

# ─────────────────────────────────────────────────────────────────
# SERIALIZACION
# ─────────────────────────────────────────────────────────────────

function ConvertTo-HermesBootstrapJson {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory = $true)][PSCustomObject]$State)
    return ($State | ConvertTo-Json -Depth 10 -Compress:$false)
}

function ConvertFrom-HermesBootstrapJson {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$Json)
    return ($Json | ConvertFrom-Json)
}

# ─────────────────────────────────────────────────────────────────
# VALIDACION
# ─────────────────────────────────────────────────────────────────

function Test-HermesBootstrapState {
    <#
    .SYNOPSIS
        Valida que un PSCustomObject cumpla con el contrato BootstrapState.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][PSCustomObject]$State)

    $errores = [System.Collections.ArrayList]::new()
    $campos  = @("Id", "Phase", "Status", "StartedAt")

    foreach ($c in $campos) {
        if ($null -eq $State.PSObject.Properties[$c]) {
            $null = $errores.Add("Campo requerido ausente: $c")
        }
    }

    if ($null -ne $State.PSObject.Properties["Id"]) {
        if ([string]::IsNullOrWhiteSpace($State.Id)) {
            $null = $errores.Add("Id vacio")
        } elseif (-not [guid]::TryParse($State.Id, [ref][guid]::Empty)) {
            $null = $errores.Add("Id no es GUID valido")
        }
    }

    if (($null -ne $State.PSObject.Properties["Phase"]) -and (-not [Enum]::IsDefined([BootstrapPhase], [int]$State.Phase))) {
        $null = $errores.Add("Phase fuera de enum: $($State.Phase)")
    }
    if (($null -ne $State.PSObject.Properties["Status"]) -and (-not [Enum]::IsDefined([PhaseStatus], [int]$State.Status))) {
        $null = $errores.Add("Status fuera de enum: $($State.Status)")
    }

    return [PSCustomObject][ordered]@{
        PSTypeName = "Hermes.Bootstrap.ValidationResult"
        EsValido   = ($errores.Count -eq 0)
        Errores    = $errores.ToArray()
    }
}
