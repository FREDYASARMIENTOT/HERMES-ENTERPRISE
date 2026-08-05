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
# CONFIGURACION AZURE (RC69)
# ─────────────────────────────────────────────────────────────────

$script:AZURE_DEFAULTS = [PSCustomObject]@{
    Location                  = 'eastus'
    ResourceGroupAplicaciones = 'RG-Hermes-Proyectos'
    ResourceGroupPlan         = 'RG-Datamining-SII2.0-Dev'
    AppServicePlan            = 'ASP-IAUR'
    StorageAccount            = 'saurhermesproyectos'
    UseSharedInfrastructure   = $true
}

function Invoke-HermesBootstrapAzureConfig {
    <#
    .SYNOPSIS
        Fase interactiva de configuración Azure (RC69).
    .DESCRIPTION
        Pregunta al usuario si desea configurar Azure. Si sí, solicita
        los valores de infraestructura compartida y persiste en
        config/Hermes.Azure.json.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    Write-Host "`n+-- AZURE INFRASTRUCTURE CONFIG (RC69) ----------------------+" -Fo Cyan
    Write-Host "| Configure aqui los valores para infraestructura compartida. |" -Fo Cyan
    Write-Host "| Si omite, se usaran los valores por defecto del wizard.    |" -Fo Cyan
    Write-Host "+-------------------------------------------------------------+`n" -Fo Cyan

    $respuesta = Read-Host "Desea configurar Azure? (s/N)"
    if ($respuesta -notmatch '^(s|S|y|Y|si|SI|Si|yes)$') {
        Write-Host "[OK] Azure config omitida. Se usaran valores por defecto." -Fo Green
        return $null
    }

    Write-Host "[..] Leyendo configuracion actual (si existe)..." -ForegroundColor Gray
    $current = _Read-AzureConfiguration

    $loc = Read-Host "Location [$($current.Location ?? $script:AZURE_DEFAULTS.Location)]"
    if ([string]::IsNullOrWhiteSpace($loc)) { $loc = $current.Location ?? $script:AZURE_DEFAULTS.Location }

    $rgA = Read-Host "ResourceGroupAplicaciones [$($current.ResourceGroupAplicaciones ?? $script:AZURE_DEFAULTS.ResourceGroupAplicaciones)]"
    if ([string]::IsNullOrWhiteSpace($rgA)) { $rgA = $current.ResourceGroupAplicaciones ?? $script:AZURE_DEFAULTS.ResourceGroupAplicaciones }

    $rgP = Read-Host "ResourceGroupPlan [$($current.ResourceGroupPlan ?? $script:AZURE_DEFAULTS.ResourceGroupPlan)]"
    if ([string]::IsNullOrWhiteSpace($rgP)) { $rgP = $current.ResourceGroupPlan ?? $script:AZURE_DEFAULTS.ResourceGroupPlan }

    $asp = Read-Host "AppServicePlan [$($current.AppServicePlan ?? $script:AZURE_DEFAULTS.AppServicePlan)]"
    if ([string]::IsNullOrWhiteSpace($asp)) { $asp = $current.AppServicePlan ?? $script:AZURE_DEFAULTS.AppServicePlan }

    $sa  = Read-Host "StorageAccount [$($current.StorageAccount ?? $script:AZURE_DEFAULTS.StorageAccount)]"
    if ([string]::IsNullOrWhiteSpace($sa)) { $sa = $current.StorageAccount ?? $script:AZURE_DEFAULTS.StorageAccount }

    $sharedStr = if ($current.UseSharedInfrastructure ?? $script:AZURE_DEFAULTS.UseSharedInfrastructure) { 'true' } else { 'false' }
    $si = Read-Host "UseSharedInfrastructure ($sharedStr)"
    if ([string]::IsNullOrWhiteSpace($si)) {
        $sharedBool = [bool]($current.UseSharedInfrastructure ?? $script:AZURE_DEFAULTS.UseSharedInfrastructure)
    } else {
        $sharedBool = ($si -match '^(true|si|s|y|yes|1)$')
    }

    # Build config object
    $configObj = [PSCustomObject][ordered]@{
        Location                  = $loc
        ResourceGroupAplicaciones = $rgA
        ResourceGroupPlan         = $rgP
        AppServicePlan            = $asp
        StorageAccount            = $sa
        UseSharedInfrastructure   = $sharedBool
    }

    # Validate
    $validation = _Validate-AzureConfiguration -Configuration $configObj
    if (-not $validation.IsValid) {
        Write-Host "[X] Validacion fallida:" -Fo Red
        foreach ($err in $validation.Errors) { Write-Host "    - $err" -Fo Red }
        return $null
    }

    # Persist
    try {
        _Write-AzureConfiguration -Configuration $configObj -FilePath $null
        Write-Host "[OK] config/Hermes.Azure.json escrito exitosamente." -Fo Green

        Write-Host "`nResumen:" -Fo Cyan
        Write-Host "  Location               : $loc" -Fo White
        Write-Host "  ResourceGroupAplicaciones: $rgA" -Fo White
        Write-Host "  ResourceGroupPlan      : $rgP" -Fo White
        Write-Host "  AppServicePlan         : $asp" -Fo White
        Write-Host "  StorageAccount         : $sa" -Fo White
        Write-Host "  UseSharedInfrastructure: $sharedBool" -Fo White

        return $configObj
    } catch {
        Write-Host "[X] Error al escribir configuracion: $_" -Fo Red
        return $null
    }
}

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
