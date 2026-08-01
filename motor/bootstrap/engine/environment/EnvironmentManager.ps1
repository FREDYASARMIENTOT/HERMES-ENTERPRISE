<#
.SYNOPSIS
    Environment Manager - Paso 3 del Bootstrap Engine.
.DESCRIPTION
    Gestiona el ciclo de vida completo de entornos Python aislados
    para proyectos Hermes Enterprise.
.RESPONSABILIDADES
    - Deteccion de interprete Python
    - Creacion atomica de venvs con rollback
    - Instalacion de dependencias
    - Activacion/desactivacion en sesion actual
    - Publicacion de eventos al EventBus
    - Registro en BootstrapState
.BUDGET
    Maximo 350 lineas.
.NOTES
    No modifica contratos publicos existentes.
    Consumidor de BootstrapState y EventBus.
#>

#region Modulo Environment Manager

<#
.SYNOPSIS
    Detecta el interprete Python disponible en el sistema.
.DESCRIPTION
    Busca Python en este orden:
    1. Variable $env:HERMES_PYTHON (override explicito)
    2. python.exe en PATH
    3. py.exe launcher (Windows)
    4. python3.exe en PATH
.PARAMETER MinimumVersion
    Version minima requerida (default: 3.8)
.OUTPUTS
    PSCustomObject con PythonPath, Version, Source
#>
function Detect-PythonInterpreter {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$MinimumVersion = '3.8'
    )

    Write-Verbose "[EnvironmentManager] Iniciando deteccion de Python..."

    # 1. Override explicito via variable de entorno
    if ($env:HERMES_PYTHON -and (Test-Path -LiteralPath $env:HERMES_PYTHON)) {
        $pythonPath = $env:HERMES_PYTHON
        try {
            $version = & $pythonPath --version 2>&1
            $versionClean = ($version -replace 'Python\s+', '').Trim()
            return [PSCustomObject]@{
                PythonPath = $pythonPath
                Version    = $versionClean
                Source     = 'HERMES_PYTHON'
            }
        }
        catch {
            Write-Warning "HERMES_PYTHON definido pero no ejecutable: $pythonPath"
        }
    }

    # 2. python.exe en PATH
    $pythonCmd = Get-Command -Name 'python' -ErrorAction SilentlyContinue
    if ($pythonCmd -and $pythonCmd.Source) {
        try {
            $version = & $pythonCmd.Source --version 2>&1
            $versionClean = ($version -replace 'Python\s+', '').Trim()
            return [PSCustomObject]@{
                PythonPath = $pythonCmd.Source
                Version    = $versionClean
                Source     = 'PATH:python'
            }
        }
        catch {
            Write-Warning "python.exe encontrado pero no ejecutable."
        }
    }

    # 3. py.exe launcher (Windows)
    if ($IsWindows -or $env:OS -match 'Windows') {
        $pyLauncher = Get-Command -Name 'py' -ErrorAction SilentlyContinue
        if ($pyLauncher -and $pyLauncher.Source) {
            try {
                $version = & $pyLauncher.Source --version 2>&1
                $versionClean = ($version -replace 'Python\s+', '').Trim()
                return [PSCustomObject]@{
                    PythonPath = $pyLauncher.Source
                    Version    = $versionClean
                    Source     = 'py-launcher'
                }
            }
            catch {
                Write-Warning "py.exe launcher encontrado pero no ejecutable."
            }
        }
    }

    # 4. python3.exe en PATH
    $python3Cmd = Get-Command -Name 'python3' -ErrorAction SilentlyContinue
    if ($python3Cmd -and $python3Cmd.Source) {
        try {
            $version = & $python3Cmd.Source --version 2>&1
            $versionClean = ($version -replace 'Python\s+', '').Trim()
            return [PSCustomObject]@{
                PythonPath = $python3Cmd.Source
                Version    = $versionClean
                Source     = 'PATH:python3'
            }
        }
        catch {
            Write-Warning "python3.exe encontrado pero no ejecutable."
        }
    }

    # No se encontro Python
    throw [System.InvalidOperationException]::new(
        "No se encontro un interprete Python valido. " +
        "Instale Python $MinimumVersion+ o configure `$env:HERMES_PYTHON"
    )
}

<#
.SYNOPSIS
    Valida que la version de Python cumpla con el minimo requerido.
.PARAMETER Version
    Version semver como string (ej: "3.11.5")
.PARAMETER MinimumVersion
    Version minima requerida (default: "3.8")
.OUTPUTS
    Boolean
#>
function Test-PythonVersion {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Version,

        [string]$MinimumVersion = '3.8'
    )

    try {
        $current = [System.Version]::new($Version)
        $minimum = [System.Version]::new($MinimumVersion)
        return $current -ge $minimum
    }
    catch {
        Write-Warning "Version invalida: $Version"
        return $false
    }
}

<#
.SYNOPSIS
    Crea un venv aislado de forma atomica.
.DESCRIPTION
    Si cualquier paso falla, elimina el venv parcialmente creado
    (rollback total).
.PARAMETER ProjectName
    Nombre del proyecto
.PARAMETER EnvironmentsRoot
    Ruta base de environments (default: D:\Environments)
.PARAMETER PythonPath
    Ruta al interprete Python
.OUTPUTS
    Ruta absoluta del venv creado
#>
function New-IsolatedVenv {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName,

        [string]$EnvironmentsRoot = 'D:\Environments',

        [Parameter(Mandatory)]
        [string]$PythonPath
    )

    $venvPath = Join-Path -Path $EnvironmentsRoot -ChildPath $ProjectName
    $partialCreated = $false

    try {
        Write-Verbose "[EnvironmentManager] Creando venv en: $venvPath"

        # Crear directorio base si no existe
        if (-not (Test-Path -LiteralPath $EnvironmentsRoot)) {
            New-Item -Path $EnvironmentsRoot -ItemType Directory -Force | Out-Null
            Write-Verbose "[EnvironmentManager] Creado directorio base: $EnvironmentsRoot"
        }

        # Verificar si ya existe
        if (Test-Path -LiteralPath $venvPath) {
            Write-Verbose "[EnvironmentManager] Venv ya existe: $venvPath"
            # Validar que sea un venv valido
            $pyvenvCfg = Join-Path -Path $venvPath -ChildPath 'pyvenv.cfg'
            if (-not (Test-Path -LiteralPath $pyvenvCfg)) {
                throw [System.InvalidOperationException]::new(
                    "El directorio $venvPath existe pero no es un venv valido. " +
                    "Elimine manualmente o use otro nombre de proyecto."
                )
            }
            return $venvPath
        }

        # Crear venv
        $partialCreated = $true
        $venvArgs = @('-m', 'venv', $venvPath)
        $process = Start-Process -FilePath $PythonPath `
                                 -ArgumentList $venvArgs `
                                 -Wait `
                                 -PassThru `
                                 -NoNewWindow `
                                 -RedirectStandardError 'NUL' `
                                 -ErrorAction Stop

        if ($process.ExitCode -ne 0) {
            throw [System.InvalidOperationException]::new(
                "Error al crear venv. Codigo de salida: $($process.ExitCode)"
            )
        }

        # Verificar que se creo correctamente
        if (-not (Test-Path -LiteralPath $venvPath)) {
            throw [System.InvalidOperationException]::new(
                "El comando venv completo pero el directorio no existe."
            )
        }

        Write-Verbose "[EnvironmentManager] Venv creado exitosamente: $venvPath"
        return $venvPath
    }
    catch {
        # Rollback: eliminar venv parcialmente creado
        if ($partialCreated -and (Test-Path -LiteralPath $venvPath)) {
            Write-Warning "[EnvironmentManager] Rollback: eliminando venv parcialmente creado..."
            Remove-Item -Path $venvPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        throw
    }
}

<#
.SYNOPSIS
    Instala dependencias en el venv.
.PARAMETER VenvPath
    Ruta absoluta del venv
.PARAMETER RequirementsPath
    Ruta a requirements.txt (opcional)
.PARAMETER ExtraPackages
    Paquetes adicionales a instalar (array)
#>
function Install-Dependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VenvPath,

        [string]$RequirementsPath,

        [string[]]$ExtraPackages = @()
    )

    # Usar python -m pip en lugar de pip directo para compatibilidad universal
    $pythonExe = if ($IsWindows -or $env:OS -match 'Windows') {
        Join-Path -Path $VenvPath -ChildPath 'Scripts\python.exe'
    }
    else {
        Join-Path -Path $VenvPath -ChildPath 'bin/python'
    }

    if (-not (Test-Path -LiteralPath $pythonExe)) {
        throw [System.InvalidOperationException]::new(
            "python no encontrado en el venv: $pythonExe"
        )
    }

    # Actualizar pip (via python -m pip para compatibilidad Python 3.12+)
    Write-Verbose "[EnvironmentManager] Actualizando pip..."
    & $pythonExe -m pip install --upgrade pip --quiet 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw [System.InvalidOperationException]::new(
            "Error al actualizar pip. Codigo: $LASTEXITCODE"
        )
    }

    # Instalar requirements si existe
    if ($RequirementsPath -and (Test-Path -LiteralPath $RequirementsPath)) {
        Write-Verbose "[EnvironmentManager] Instalando dependencias desde: $RequirementsPath"
        & $pythonExe -m pip install -r $RequirementsPath --quiet 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw [System.InvalidOperationException]::new(
                "Error al instalar requirements.txt. Codigo: $LASTEXITCODE"
            )
        }
    }

    # Instalar paquetes extra
    if ($ExtraPackages.Count -gt 0) {
        Write-Verbose "[EnvironmentManager] Instalando paquetes extra: $($ExtraPackages -join ', ')"
        & $pythonExe -m pip install @ExtraPackages --quiet 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw [System.InvalidOperationException]::new(
                "Error al instalar paquetes extra. Codigo: $LASTEXITCODE"
            )
        }
    }

    Write-Verbose "[EnvironmentManager] Dependencias instaladas correctamente."
}

<#
.SYNOPSIS
    Activa el venv en la sesion actual.
.PARAMETER VenvPath
    Ruta absoluta del venv
#>
function Enter-HermesEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VenvPath
    )

    if (-not (Test-Path -LiteralPath $VenvPath)) {
        throw [System.ArgumentException]::new(
            "Venv no encontrado: $VenvPath"
        )
    }

    $scriptsDir = if ($IsWindows -or $env:OS -match 'Windows') {
        Join-Path -Path $VenvPath -ChildPath 'Scripts'
    }
    else {
        Join-Path -Path $VenvPath -ChildPath 'bin'
    }

    if (-not (Test-Path -LiteralPath $scriptsDir)) {
        throw [System.InvalidOperationException]::new(
            "Directorio de scripts no encontrado: $scriptsDir"
        )
    }

    # Guardar PATH original para restaurar despues
    if (-not (Get-Variable -Name 'HermesOriginalPath' -Scope Global -ErrorAction SilentlyContinue)) {
        $script:HermesOriginalPath = $env:PATH
    }

    # Prepend scripts dir al PATH
    $env:PATH = "$scriptsDir;$env:PATH"

    # Establecer variable de entorno VIRTUAL_ENV
    $env:VIRTUAL_ENV = $VenvPath

    Write-Verbose "[EnvironmentManager] Venv activado: $VenvPath"
}

<#
.SYNOPSIS
    Desactiva el venv restaurando el PATH original.
#>
function Exit-HermesEnvironment {
    [CmdletBinding()]
    param()

    if (Get-Variable -Name 'HermesOriginalPath' -Scope Global -ErrorAction SilentlyContinue) {
        $env:PATH = $script:HermesOriginalPath
        Remove-Variable -Name 'HermesOriginalPath' -Scope Global -Force
    }

    if ($env:VIRTUAL_ENV) {
        Remove-Item -Path Env:VIRTUAL_ENV -ErrorAction SilentlyContinue
    }

    Write-Verbose "[EnvironmentManager] Venv desactivado."
}

<#
.SYNOPSIS
    Verifica la salud del venv.
.PARAMETER VenvPath
    Ruta absoluta del venv
.OUTPUTS
    PSCustomObject con estado detallado
#>
function Test-HermesEnvironment {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$VenvPath
    )

    $result = [PSCustomObject]@{
        VenvPath    = $VenvPath
        Exists      = $false
        Valid       = $false
        PythonPath  = $null
        PipPath     = $null
        Version     = $null
        Message     = ''
    }

    # Verificar existencia
    $result.Exists = Test-Path -LiteralPath $VenvPath
    if (-not $result.Exists) {
        $result.Message = 'Venv no encontrado'
        return $result
    }

    # Verificar pyvenv.cfg
    $pyvenvCfg = Join-Path -Path $VenvPath -ChildPath 'pyvenv.cfg'
    if (-not (Test-Path -LiteralPath $pyvenvCfg)) {
        $result.Message = 'pyvenv.cfg no encontrado - venv corrupto'
        return $result
    }

    # Verificar python
    $pythonExe = if ($IsWindows -or $env:OS -match 'Windows') {
        Join-Path -Path $VenvPath -ChildPath 'Scripts\python.exe'
    }
    else {
        Join-Path -Path $VenvPath -ChildPath 'bin/python'
    }

    if (-not (Test-Path -LiteralPath $pythonExe)) {
        $result.Message = 'Python no encontrado en el venv'
        return $result
    }

    $result.PythonPath = $pythonExe

    # Verificar pip
    $pipExe = if ($IsWindows -or $env:OS -match 'Windows') {
        Join-Path -Path $VenvPath -ChildPath 'Scripts\pip.exe'
    }
    else {
        Join-Path -Path $VenvPath -ChildPath 'bin/pip'
    }

    if (-not (Test-Path -LiteralPath $pipExe)) {
        $result.Message = 'pip no encontrado en el venv'
        return $result
    }

    $result.PipPath = $pipExe

    # Obtener version
    try {
        $versionOutput = & $pythonExe --version 2>&1
        $result.Version = ($versionOutput -replace 'Python\s+', '').Trim()
    }
    catch {
        $result.Message = 'Error al consultar version de Python'
        return $result
    }

    $result.Valid = $true
    $result.Message = 'Venv valido y funcional'

    return $result
}

<#
.SYNOPSIS
    Obtiene el estado del environment.
.PARAMETER ProjectName
    Nombre del proyecto
.PARAMETER EnvironmentsRoot
    Ruta base de environments
.OUTPUTS
    PSCustomObject con metadata del environment
#>
function Get-HermesEnvironmentStatus {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName,

        [string]$EnvironmentsRoot = 'D:\Environments'
    )

    $venvPath = Join-Path -Path $EnvironmentsRoot -ChildPath $ProjectName

    $status = Test-HermesEnvironment -VenvPath $venvPath

    return [PSCustomObject]@{
        ProjectName   = $ProjectName
        VenvPath      = $venvPath
        Exists        = $status.Exists
        IsValid       = $status.Valid
        PythonVersion = $status.Version
        IsActive      = ($env:VIRTUAL_ENV -eq $venvPath)
        Message       = $status.Message
    }
}

<#
.SYNOPSIS
    Orquesta la creacion completa del environment.
.DESCRIPTION
    Funcion principal que coordina:
    1. Deteccion de Python
    2. Creacion de venv
    3. Instalacion de dependencias
    4. Validacion
    5. Registro en BootstrapState
.PARAMETER BootstrapState
    Estado actual del bootstrap
.PARAMETER EnvironmentsRoot
    Ruta base de environments (default: D:\Environments)
.PARAMETER RequirementsPath
    Ruta a requirements.txt (opcional)
.PARAMETER ExtraPackages
    Paquetes adicionales (opcional)
.OUTPUTS
    BootstrapState actualizado
#>
function Initialize-HermesEnvironment {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$BootstrapState,

        [string]$EnvironmentsRoot = 'D:\Environments',

        [string]$RequirementsPath,

        [string[]]$ExtraPackages = @()
    )

    $projectName = $BootstrapState.ProjectName

    Write-Verbose "[EnvironmentManager] Inicializando environment para: $projectName"

    # Publicar evento de inicio
    # if (Get-Command -Name 'Publish-Event' -ErrorAction SilentlyContinue) {
    #     Publish-Event -Name "Bootstrap.Environment.Started" -Data @{
    #         ProjectName = $projectName
    #         EnvironmentsRoot = $EnvironmentsRoot
    #     }
    # }

    try {
        # 1. Detectar Python
        Write-Verbose "[EnvironmentManager] Paso 1/4: Detectando interprete Python..."
        $pythonInfo = Detect-PythonInterpreter
        Write-Verbose "[EnvironmentManager] Python encontrado: $($pythonInfo.PythonPath) (v$($pythonInfo.Version))"

        # Validar version
        if (-not (Test-PythonVersion -Version $pythonInfo.Version -MinimumVersion '3.8')) {
            throw [System.InvalidOperationException]::new(
                "Python $($pythonInfo.Version) no cumple version minima requerida (3.8+)"
            )
        }

        # 2. Crear venv
        Write-Verbose "[EnvironmentManager] Paso 2/4: Creando venv aislado..."
        $venvPath = New-IsolatedVenv -ProjectName $projectName `
                                     -EnvironmentsRoot $EnvironmentsRoot `
                                     -PythonPath $pythonInfo.PythonPath

        # 3. Instalar dependencias
        Write-Verbose "[EnvironmentManager] Paso 3/4: Instalando dependencias..."
        Install-Dependencies -VenvPath $venvPath `
                            -RequirementsPath $RequirementsPath `
                            -ExtraPackages $ExtraPackages

        # 4. Validar venv
        Write-Verbose "[EnvironmentManager] Paso 4/4: Validando environment..."
        $envStatus = Test-HermesEnvironment -VenvPath $venvPath

        if (-not $envStatus.Valid) {
            throw [System.InvalidOperationException]::new(
                "Venv creado pero invalido: $($envStatus.Message)"
            )
        }

        # Construir metadata del environment
        $environmentData = [PSCustomObject]@{
            VenvPath      = $venvPath
            PythonPath    = $pythonInfo.PythonPath
            PythonVersion = $pythonInfo.Version
            CreatedAt     = (Get-Date).ToString('o')
            Status        = 'Ready'
        }

        # Actualizar BootstrapState
        # NOTA: BootstrapState.SetEnvironment() debe existir del Paso 1
        if ($BootstrapState -is [PSCustomObject] -and
            $BootstrapState.PSObject.Properties.Name -contains 'Environment') {
            $BootstrapState.Environment = $environmentData
        }
        else {
            $BootstrapState | Add-Member -NotePropertyName 'Environment' `
                                        -NotePropertyValue $environmentData `
                                        -Force
        }

        # Publicar evento de completado
        # if (Get-Command -Name 'Publish-Event' -ErrorAction SilentlyContinue) {
        #     Publish-Event -Name "Bootstrap.Environment.Completed" -Data @{
        #         ProjectName = $projectName
        #         VenvPath = $venvPath
        #         PythonVersion = $pythonInfo.Version
        #     }
        # }

        Write-Verbose "[EnvironmentManager] Environment inicializado exitosamente."

        return $BootstrapState
    }
    catch {
        # Publicar evento de fallo
        # if (Get-Command -Name 'Publish-Event' -ErrorAction SilentlyContinue) {
        #     Publish-Event -Name "Bootstrap.Environment.Failed" -Data @{
        #         ProjectName = $projectName
        #         Error = $_.Exception.Message
        #     }
        # }

        Write-Error "[EnvironmentManager] Error al inicializar environment: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Alias de alto nivel para Initialize-HermesEnvironment.
.DESCRIPTION
    Funcion de conveniencia que usa New-HermesEnvironment como
    nombre mas intuitivo para el flujo principal.
.PARAMETER BootstrapState
    Estado actual del bootstrap
.PARAMETER EnvironmentsRoot
    Ruta base de environments
.PARAMETER RequirementsPath
    Ruta a requirements.txt
.PARAMETER ExtraPackages
    Paquetes adicionales
.OUTPUTS
    BootstrapState actualizado
#>
function New-HermesEnvironment {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$BootstrapState,

        [string]$EnvironmentsRoot = 'D:\Environments',

        [string]$RequirementsPath,

        [string[]]$ExtraPackages = @()
    )

    return Initialize-HermesEnvironment -BootstrapState $BootstrapState `
                                       -EnvironmentsRoot $EnvironmentsRoot `
                                       -RequirementsPath $RequirementsPath `
                                       -ExtraPackages $ExtraPackages
}

#endregion

# Funciones publicas disponibles tras dot-source:
#   New-HermesEnvironment
#   Initialize-HermesEnvironment
#   Enter-HermesEnvironment
#   Exit-HermesEnvironment
#   Get-HermesEnvironmentStatus
#   Test-HermesEnvironment
#   Detect-PythonInterpreter
#   Test-PythonVersion
#   New-IsolatedVenv
#   Install-Dependencies
