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

    $locDefault = if ($null -ne $current.Location) { $current.Location } else { $script:AZURE_DEFAULTS.Location }
    $loc = Read-Host "Location [$locDefault]"
    if ([string]::IsNullOrWhiteSpace($loc)) { $loc = $locDefault }

    $rgADefault = if ($null -ne $current.ResourceGroupAplicaciones) { $current.ResourceGroupAplicaciones } else { $script:AZURE_DEFAULTS.ResourceGroupAplicaciones }
    $rgA = Read-Host "ResourceGroupAplicaciones [$rgADefault]"
    if ([string]::IsNullOrWhiteSpace($rgA)) { $rgA = $rgADefault }

    $rgPDefault = if ($null -ne $current.ResourceGroupPlan) { $current.ResourceGroupPlan } else { $script:AZURE_DEFAULTS.ResourceGroupPlan }
    $rgP = Read-Host "ResourceGroupPlan [$rgPDefault]"
    if ([string]::IsNullOrWhiteSpace($rgP)) { $rgP = $rgPDefault }

    $aspDefault = if ($null -ne $current.AppServicePlan) { $current.AppServicePlan } else { $script:AZURE_DEFAULTS.AppServicePlan }
    $asp = Read-Host "AppServicePlan [$aspDefault]"
    if ([string]::IsNullOrWhiteSpace($asp)) { $asp = $aspDefault }

    $saDefault = if ($null -ne $current.StorageAccount) { $current.StorageAccount } else { $script:AZURE_DEFAULTS.StorageAccount }
    $sa  = Read-Host "StorageAccount [$saDefault]"
    if ([string]::IsNullOrWhiteSpace($sa)) { $sa = $saDefault }

    $sharedCurrent = if ($null -ne $current.UseSharedInfrastructure) { $current.UseSharedInfrastructure } else { $script:AZURE_DEFAULTS.UseSharedInfrastructure }
    $sharedStr = if ($sharedCurrent) { 'true' } else { 'false' }
    $si = Read-Host "UseSharedInfrastructure ($sharedStr)"
    if ([string]::IsNullOrWhiteSpace($si)) {
        $sharedBool = [bool]($sharedCurrent)
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

function Invoke-HermesBootstrapValidacionRuntime {
    <#
    .SYNOPSIS
        Fase de validacion del Runtime Python Hermes Enterprise (RC70-D).
    .DESCRIPTION
        Verifica:
          - Hermes.Python.json existe en config/
          - python.exe existe en la ruta especificada
          - pip.exe existe en la ruta especificada
          - El entorno virtual existe
          - pyvenv.cfg existe
          - requirements.txt existe
        NO intenta reparar automaticamente.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    Write-Host "`n+-- VALIDACION RUNTIME PYTHON (RC70-D) ----------------------+" -Fo Cyan
    Write-Host "| Verificando el entorno virtual Hermes Enterprise...          |" -Fo Cyan
    Write-Host "+-------------------------------------------------------------+`n" -Fo Cyan

    $errores = [System.Collections.ArrayList]::new()
    $configPath = Join-Path $PSScriptRoot "..\..\..\config\Hermes.Python.json"

    # 1. Verificar que Hermes.Python.json existe
    if (-not (Test-Path $configPath)) {
        $null = $errores.Add("config\Hermes.Python.json no encontrado en: $configPath")
    } else {
        Write-Host "[OK] config/Hermes.Python.json encontrado." -Fo Green
        $config = Get-Content $configPath -Raw | ConvertFrom-Json

        # 2. Verificar python.exe
        if (Test-Path $config.RutaPython) {
            try {
                $ver = & $config.RutaPython --version 2>&1
                Write-Host "[OK] Python Runtime: $($ver.Trim())" -Fo Green
            } catch {
                $null = $errores.Add("python.exe no ejecutable en: $($config.RutaPython)")
            }
        } else {
            $null = $errores.Add("python.exe no encontrado en: $($config.RutaPython)")
        }

        # 3. Verificar pip.exe
        if (Test-Path $config.RutaPip) {
            try {
                $ver = & $config.RutaPip --version 2>&1
                Write-Host "[OK] Pip Runtime: $($ver.Trim())" -Fo Green
            } catch {
                $null = $errores.Add("pip.exe no ejecutable en: $($config.RutaPip)")
            }
        } else {
            $null = $errores.Add("pip.exe no encontrado en: $($config.RutaPip)")
        }

        # 4. Verificar entorno virtual existe
        if (Test-Path $config.RutaEntornoVirtual) {
            Write-Host "[OK] Entorno virtual existe: $($config.RutaEntornoVirtual)" -Fo Green
        } else {
            $null = $errores.Add("Entorno virtual no encontrado en: $($config.RutaEntornoVirtual)")
        }

        # 5. Verificar pyvenv.cfg
        $pyvenv = Join-Path $config.RutaEntornoVirtual "pyvenv.cfg"
        if (Test-Path $pyvenv) {
            Write-Host "[OK] pyvenv.cfg encontrado." -Fo Green
        } else {
            $null = $errores.Add("pyvenv.cfg no encontrado en el entorno virtual.")
        }

        # 6. Verificar requirements.txt
        $reqsPath = Join-Path $PSScriptRoot "..\..\..\$($config.ArchivoRequirements)"
        if (Test-Path $reqsPath) {
            Write-Host "[OK] $($config.ArchivoRequirements) encontrado." -Fo Green
        } else {
            $null = $errores.Add("$($config.ArchivoRequirements) no encontrado en: $reqsPath")
        }
    }

    if ($errores.Count -gt 0) {
        Write-Host "`n[X] ERRORES DE VALIDACION DEL RUNTIME PYTHON:" -Fo Red
        foreach ($err in $errores) {
            Write-Host "    - $err" -Fo Red
        }
        Write-Host "`n[!] Ejecute Install-HermesPythonRuntime.ps1 para crear el Runtime." -Fo Magenta
        Write-Host "    Luego ejecute este wizard nuevamente." -Fo Magenta
        return [PSCustomObject][ordered]@{
            PSTypeName = 'Hermes.Bootstrap.RuntimeValidationResult'
            EsValido   = $false
            Errores    = $errores.ToArray()
        }
    }

    Write-Host "`n[OK] Runtime Python Hermes Enterprise validado correctamente." -Fo Green
    return [PSCustomObject][ordered]@{
        PSTypeName = 'Hermes.Bootstrap.RuntimeValidationResult'
        EsValido   = $true
        Errores    = @()
    }
}

function Invoke-HermesBootstrapWizard {
    <#
    .SYNOPSIS
        Wizard Sprint 2: recoleccion minima del nombre + validacion Runtime.
    .DESCRIPTION
        Devuelve un objeto WizardResult. Incluye validacion del Runtime
        Python Hermes Enterprise (RC70-D).
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $nombre = Invoke-HermesBootstrapWizardNombre

    # RC70-D: Validacion del Runtime Python
    $runtimeValidation = Invoke-HermesBootstrapValidacionRuntime

    return [PSCustomObject][ordered]@{
        PSTypeName          = 'Hermes.Bootstrap.WizardResult'
        NombreProyecto      = $nombre
        RuntimeValidation   = $runtimeValidation
        Timestamp           = [datetime]::UtcNow.ToString('o')
        SprintCompletado    = 3
    }
}
