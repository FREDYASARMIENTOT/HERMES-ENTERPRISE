<#
.SYNOPSIS
    Wizard interactivo para el Bootstrap Engine (Sprint 2).
.DESCRIPTION
    Recolección mínima: nombre del proyecto con validación regex estricta.
    Case-sensitive. Sin lógica de creación de archivos (Sprint 3+).
.NOTES
    Proyecto  : HERMES-ENTERPRISE
    Autor     : Fredy Alejandro Sarmiento Torres
    Version   : 2.0.0 (Sprint 2 - minimalista)
#>

Set-StrictMode -Version Latest

# Regex canónica del proyecto (única fuente de verdad).
$script:HERMES_NOMBRE_REGEX = '^[A-Za-z][A-Za-z0-9_-]{2,63}$'

# ─────────────────────────────────────────────────────────────────
# VALIDACION DE NOMBRE
# ─────────────────────────────────────────────────────────────────

function Test-HermesBootstrapNombreProyecto {
    <#
    .SYNOPSIS
        Valida nombre de proyecto contra regex estricta.
    .DESCRIPTION
        Reglas: inicio con letra, 3-64 caracteres, A-Za-z0-9_-.
        Case-sensitive preservado.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Nombre)

    $err = [System.Collections.ArrayList]::new()

    if ([string]::IsNullOrWhiteSpace($Nombre)) {
        $null = $err.Add('Nombre vacio')
    } elseif ($Nombre.Length -lt 3 -or $Nombre.Length -gt 64) {
        $null = $err.Add("Longitud $($Nombre.Length) fuera de rango [3,64]")
    } elseif (-not ($Nombre.Substring(0,1) -match '^[A-Za-z]$')) {
        $null = $err.Add('Debe iniciar con letra')
    } elseif ($Nombre -notmatch $script:HERMES_NOMBRE_REGEX) {
        $null = $err.Add('Contiene caracteres no permitidos (solo A-Za-z0-9_-)')
    }

    return [PSCustomObject][ordered]@{
        PSTypeName = 'Hermes.Bootstrap.ValidationResult'
        EsValido   = ($err.Count -eq 0)
        Errores    = $err.ToArray()
    }
}

# ─────────────────────────────────────────────────────────────────
# WIZARD
# ─────────────────────────────────────────────────────────────────

function Invoke-HermesBootstrapWizardNombre {
    <#
    .SYNOPSIS
        Solicita y valida nombre de proyecto en loop hasta obtener uno válido.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Write-Host "`n+-- HERMES BOOTSTRAP - Wizard (Sprint 2) -------------------+" -Fo Cyan
    Write-Host "| Reglas: 3-64 chars, inicio letra, A-Za-z0-9_-             |" -Fo Cyan
    Write-Host "+-------------------------------------------------------------+`n" -Fo Cyan

    do {
        $nombre = Read-Host 'Nombre del proyecto'
        $v = Test-HermesBootstrapNombreProyecto -Nombre $nombre
        if ($v.EsValido) {
            Write-Host "[OK] $nombre" -Fo Green
            return $nombre
        }
        Write-Host "[X] $($v.Errores -join '; ')" -Fo Red
        Write-Host "    ejemplos: PY_Encuesta_Percepcion, MiProyecto2026, Mi-Proyecto" -Fo Gray
    } while ($true)
}

function Invoke-HermesBootstrapWizard {
    <#
    .SYNOPSIS
        Wizard Sprint 2: recoleccion minima del nombre.
    .DESCRIPTION
        Devuelve un objeto WizardResult. El resto de preguntas
        pertenecen a sprints posteriores.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $nombre = Invoke-HermesBootstrapWizardNombre

    return [PSCustomObject][ordered]@{
        PSTypeName       = 'Hermes.Bootstrap.WizardResult'
        NombreProyecto   = $nombre
        Timestamp        = [datetime]::UtcNow.ToString('o')
        SprintCompletado = 2
    }
}
