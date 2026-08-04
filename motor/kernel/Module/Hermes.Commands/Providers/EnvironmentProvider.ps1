<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : EnvironmentProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Proveedor de entornos virtuales Python (venv/conda) para el Kernel Hermes Enterprise.
    Implementa el contrato IProvider y registra en las tablas EnvironmentHistory y ProjectHistory.
    RC56 — Entornos virtuales configurables.
====================================================================================================
#>

Set-StrictMode -Version Latest

# Load base dependencies
$script:ProviderBase = Join-Path $PSScriptRoot 'ProviderBase.ps1'
if (Test-Path $script:ProviderBase) {
    . $script:ProviderBase
}

<#
.SYNOPSIS
    Crea un nuevo EnvironmentProvider (venv o conda) siguiendo el patrón ProviderBase.
.DESCRIPTION
    Retorna un objeto proveedor con capacidad de crear, activar y eliminar entornos virtuales.
    ProviderType: 'VenvEnvironment' o 'CondaEnvironment'.
.PARAMETER Id
    Identificador único.
.PARAMETER Name
    Nombre descriptivo.
.PARAMETER Version
    Versión semántica.
.PARAMETER ProviderType
    'VenvEnvironment' o 'CondaEnvironment'.
.PARAMETER ProviderConfig
    Configuración: PythonVersion, CondaPath, CondaEnvPath, etc.
#>
function New-EnvironmentProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [ValidateSet('VenvEnvironment', 'CondaEnvironment')]
        [string]$ProviderType,

        [Parameter(Mandatory = $false)]
        [hashtable]$ProviderConfig = @{}
    )

    $base = New-ProviderBase -Id $Id -Name $Name -Version $Version -ProviderType $ProviderType -ProviderConfig $ProviderConfig

    # Extender con propiedades específicas del entorno
    $base | Add-Member -NotePropertyName 'CondaPath' -NotePropertyValue ($ProviderConfig.CondaPath -or '')
    $base | Add-Member -NotePropertyName 'CondaEnvPath' -NotePropertyValue ($ProviderConfig.CondaEnvPath -or '')
    $base | Add-Member -NotePropertyName 'PythonVersion' -NotePropertyValue ($ProviderConfig.PythonVersion -or '')
    $base | Add-Member -NotePropertyName 'VenvPath' -NotePropertyValue ($ProviderConfig.VenvPath -or '')
    $base | Add-Member -NotePropertyName 'LastCreatedEnv' -NotePropertyValue ''

    return $base
}

# ============================================================
# HELPERS (internal)
# ============================================================

function _Get-HermesRootEnv {
    $d = Split-Path -Parent $PSScriptRoot
    $d = Split-Path -Parent $d
    return $d
}

function _New-GuidStringEnv { return [guid]::NewGuid().ToString('N') }

function _Write-EnvironmentHistory {
    param(
        [string]$EnvironmentId,
        [string]$Provider,
        [string]$Action,
        [string]$PythonVersion = '',
        [string]$Result = 'Pending',
        [string]$ProjectName = '',
        [string]$User = ''
    )
    $db = Join-Path (_Get-HermesRootEnv) 'hermes.db'
    if (-not (Test-Path $db)) { return }
    $id = _New-GuidStringEnv
    if ([string]::IsNullOrEmpty($User)) { $User = $env:USERNAME }
    $pv = $PythonVersion.Replace("'", "''")
    $pn = $ProjectName.Replace("'", "''")
    $sql = "INSERT INTO EnvironmentHistory (Id,EnvironmentId,Provider,Action,PythonVersion,Result,ProjectName,User) VALUES ('$id','$EnvironmentId','$Provider','$Action','$pv','$Result','$pn','$User')"
    sqlite3.exe "`"$db`"" $sql 2>$null | Out-Null
}

function _Complete-EnvironmentHistory {
    param(
        [string]$EnvironmentId,
        [string]$Result,
        [string]$ProjectName = ''
    )
    $db = Join-Path (_Get-HermesRootEnv) 'hermes.db'
    if (-not (Test-Path $db)) { return }
    $ts = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $sql = "UPDATE EnvironmentHistory SET EndTime='$ts', Duration = ROUND((julianday('$ts') - julianday(StartTime)) * 86400, 2), Result='$Result' WHERE EnvironmentId='$EnvironmentId' AND Result='Pending'"
    sqlite3.exe "`"$db`"" $sql 2>$null | Out-Null
}

<#
.SYNOPSIS
    Detecta la ruta de conda en el sistema.
#>
function Find-CondaPath {
    $up = (Resolve-Path ~).Path
    $condaPaths = @(
        "$up\miniconda3\condabin\conda.bat",
        "$up\miniconda3\Scripts\conda.exe",
        "$up\miniconda3\condabin\conda.exe",
        "C:\ProgramData\miniconda3\condabin\conda.bat",
        "C:\ProgramData\miniconda3\Scripts\conda.exe",
        "C:\Users\fredya.sarmiento\miniconda3\condabin\conda.bat",
        "C:\Users\fredya.sarmiento\miniconda3\Scripts\conda.exe"
    )
    foreach ($cp in $condaPaths) {
        if (Test-Path $cp) { return $cp }
    }
    # Try finding via where.exe
    try {
        $whereResult = where.exe conda 2>$null
        if ($whereResult) { return $whereResult[0].Trim() }
    } catch { Write-Verbose "Conda not found via where.exe" }
    return $null
}

# ============================================================
# PUBLIC OPERATIONS
# ============================================================

<#
.SYNOPSIS
    Crea un entorno virtual usando venv.
.DESCRIPTION
    Ejecuta python -m venv en el directorio .venv del proyecto.
    Registra en EnvironmentHistory.
.PARAMETER Provider
    Objeto EnvironmentProvider (VenvEnvironment).
.PARAMETER ProjectPath
    Ruta del proyecto donde crear .venv.
.PARAMETER PythonVersion
    Versión de Python a usar (para telemetría).
.PARAMETER ProjectName
    Nombre del proyecto (para telemetría).
#>
function New-VenvEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $false)]
        [string]$PythonVersion = '3.14',

        [Parameter(Mandatory = $false)]
        [string]$ProjectName = ''
    )

    $envId = _New-GuidStringEnv
    _Write-EnvironmentHistory -EnvironmentId $envId -Provider $Provider.ProviderType -Action 'Create' -PythonVersion $PythonVersion -ProjectName $ProjectName

    $venvPath = Join-Path $ProjectPath '.venv'

    if (Test-Path $venvPath) {
        Write-Host "  [OK] venv ya existe en $venvPath" -ForegroundColor Green
        _Complete-EnvironmentHistory -EnvironmentId $envId -Result 'Success' -ProjectName $ProjectName
        $Provider.VenvPath = $venvPath
        $Provider.LastCreatedEnv = $venvPath
        return $true
    }

    Write-Host "  [..] Creando venv en $venvPath (Python $PythonVersion)..." -ForegroundColor Yellow
    try {
        $result = python -m venv $venvPath 2>&1
        if ($LASTEXITCODE -eq 0 -or (Test-Path $venvPath)) {
            Write-Host "  [OK] venv creado en $venvPath" -ForegroundColor Green
            _Complete-EnvironmentHistory -EnvironmentId $envId -Result 'Success' -ProjectName $ProjectName
            $Provider.VenvPath = $venvPath
            $Provider.LastCreatedEnv = $venvPath
            $Provider.Status = 'Running'
            $Provider.IsConnected = $true
            $null = $Provider.Events.Add(@{ Timestamp=(Get-Date).ToString('o'); EventType='Create'; Status='Running' })
            return $true
        } else {
            throw "python -m venv falló: $result"
        }
    } catch {
        Write-Host "  [FAIL] Error creando venv: $_" -ForegroundColor Red
        _Complete-EnvironmentHistory -EnvironmentId $envId -Result 'Failed' -ProjectName $ProjectName
        $null = $Provider.Errors.Add("Error creando venv: $_")
        $Provider.Status = 'Faulted'
        return $false
    }
}

<#
.SYNOPSIS
    Activa un entorno venv (simula conda activate + python -m venv activate).
.DESCRIPTION
    En PowerShell, la activación real requiere ejecutar .venv\Scripts\Activate.ps1.
    Este comando retorna el comando necesario.
.PARAMETER Provider
    Objeto EnvironmentProvider.
.PARAMETER ProjectPath
    Ruta del proyecto.
#>
function Enter-VenvEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $activateScript = Join-Path $ProjectPath '.venv\Scripts\Activate.ps1'
    if (Test-Path $activateScript) {
        Write-Host "  [OK] Activar venv: & `"$activateScript`"" -ForegroundColor Green
        return "& `"$activateScript`""
    }
    Write-Host "  [WARN] No se encontró $activateScript" -ForegroundColor Yellow
    return $null
}

<#
.SYNOPSIS
    Elimina un entorno venv.
.PARAMETER Provider
    Objeto EnvironmentProvider.
.PARAMETER ProjectPath
    Ruta del proyecto.
.PARAMETER ProjectName
    Nombre del proyecto (telemetría).
#>
function Remove-VenvEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $false)]
        [string]$ProjectName = ''
    )

    $envId = _New-GuidStringEnv
    _Write-EnvironmentHistory -EnvironmentId $envId -Provider $Provider.ProviderType -Action 'Remove' -ProjectName $ProjectName

    $venvPath = Join-Path $ProjectPath '.venv'
    if (Test-Path $venvPath) {
        try {
            Remove-Item -Path $venvPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] venv eliminado: $venvPath" -ForegroundColor Green
            _Complete-EnvironmentHistory -EnvironmentId $envId -Result 'Success' -ProjectName $ProjectName
            return $true
        } catch {
            Write-Host "  [FAIL] Error eliminando venv: $_" -ForegroundColor Red
            _Complete-EnvironmentHistory -EnvironmentId $envId -Result 'Failed' -ProjectName $ProjectName
            return $false
        }
    } else {
        Write-Host "  [OK] venv no existe (nada que eliminar)" -ForegroundColor Green
        _Complete-EnvironmentHistory -EnvironmentId $envId -Result 'Success' -ProjectName $ProjectName
        return $true
    }
}

<#
.SYNOPSIS
    Crea un entorno Conda.
.DESCRIPTION
    Ejecuta conda env create -f environment.yml o conda create -n.
.PARAMETER Provider
    Objeto EnvironmentProvider (CondaEnvironment).
.PARAMETER ProjectPath
    Ruta del proyecto.
.PARAMETER EnvironmentName
    Nombre del entorno Conda.
.PARAMETER PythonVersion
    Versión de Python.
.PARAMETER ProjectName
    Nombre del proyecto (telemetría).
#>
function New-CondaEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$EnvironmentName,

        [Parameter(Mandatory = $false)]
        [string]$PythonVersion = '3.14',

        [Parameter(Mandatory = $false)]
        [string]$ProjectName = ''
    )

    $envId = _New-GuidStringEnv
    _Write-EnvironmentHistory -EnvironmentId $envId -Provider $Provider.ProviderType -Action 'Create' -PythonVersion $PythonVersion -ProjectName $ProjectName

    $conda = Find-CondaPath
    if (-not $conda) {
        Write-Host "  [FAIL] Conda no encontrado. Instale Miniconda o Anaconda" -ForegroundColor Red
        _Complete-EnvironmentHistory -EnvironmentId $envId -Result 'Failed' -ProjectName $ProjectName
        return $false
    }

    # Ensure conda in PATH
    $up = (Resolve-Path ~).Path
    $env:PATH = "$up\miniconda3;$up\miniconda3\Scripts;$up\miniconda3\condabin;$up\miniconda3\Library\bin;$env:PATH"

    # Check if env already exists
    $envList = & $conda env list 2>&1 | Out-String
    if ($envList -match "\b$EnvironmentName\b") {
        Write-Host "  [OK] Conda environment $EnvironmentName ya existe" -ForegroundColor Green
        _Complete-EnvironmentHistory -EnvironmentId $envId -Result 'Success' -ProjectName $ProjectName
        $Provider.LastCreatedEnv = $EnvironmentName
        return $true
    }

    # Create environment.yml if not exists
    $envYml = Join-Path $ProjectPath 'environment.yml'
    if (-not (Test-Path $envYml)) {
        $content = @"
name: $EnvironmentName
channels:
  - defaults
  - conda-forge
dependencies:
  - python=$PythonVersion
  - pip
prefix: C:\Users\fredya.sarmiento\.conda\envs\$EnvironmentName
"@
        $content | Out-File -FilePath $envYml -Encoding utf8 -Force
    }

    Write-Host "  [..] Creando Conda environment $EnvironmentName (Python $PythonVersion)..." -ForegroundColor Yellow
    & $conda env create -f $envYml 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Conda environment $EnvironmentName creado" -ForegroundColor Green
        _Complete-EnvironmentHistory -EnvironmentId $envId -Result 'Success' -ProjectName $ProjectName
        $Provider.LastCreatedEnv = $EnvironmentName
        $Provider.Status = 'Running'
        $Provider.IsConnected = $true
        return $true
    } else {
        # Fallback: try conda create -n directly
        Write-Host "  [..] Fallback: conda create -n $EnvironmentName python=$PythonVersion" -ForegroundColor Yellow
        & $conda create -y -n $EnvironmentName python=$PythonVersion pip 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Conda environment $EnvironmentName creado (fallback)" -ForegroundColor Green
            _Complete-EnvironmentHistory -EnvironmentId $envId -Result 'Success' -ProjectName $ProjectName
            $Provider.LastCreatedEnv = $EnvironmentName
            $Provider.Status = 'Running'
            $Provider.IsConnected = $true
            return $true
        }
        Write-Host "  [FAIL] Error creando Conda environment $EnvironmentName" -ForegroundColor Red
        _Complete-EnvironmentHistory -EnvironmentId $envId -Result 'Failed' -ProjectName $ProjectName
        $null = $Provider.Errors.Add("Error creando Conda environment $EnvironmentName")
        $Provider.Status = 'Faulted'
        return $false
    }
}

<#
.SYNOPSIS
    Activa un entorno Conda.
.DESCRIPTION
    Retorna el comando conda activate para el entorno.
.PARAMETER Provider
    Objeto EnvironmentProvider.
.PARAMETER EnvironmentName
    Nombre del entorno.
#>
function Enter-CondaEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider,

        [Parameter(Mandatory = $true)]
        [string]$EnvironmentName
    )

    Write-Host "  [OK] Activar conda: conda activate $EnvironmentName" -ForegroundColor Green
    return "conda activate $EnvironmentName"
}

<#
.SYNOPSIS
    Elimina un entorno Conda.
.PARAMETER Provider
    Objeto EnvironmentProvider.
.PARAMETER EnvironmentName
    Nombre del entorno.
.PARAMETER ProjectName
    Nombre del proyecto (telemetría).
#>
function Remove-CondaEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Provider,

        [Parameter(Mandatory = $true)]
        [string]$EnvironmentName,

        [Parameter(Mandatory = $false)]
        [string]$ProjectName = ''
    )

    $envId = _New-GuidStringEnv
    _Write-EnvironmentHistory -EnvironmentId $envId -Provider $Provider.ProviderType -Action 'Remove' -ProjectName $ProjectName

    $conda = Find-CondaPath
    if (-not $conda) {
        Write-Host "  [WARN] Conda no encontrado" -ForegroundColor Yellow
        _Complete-EnvironmentHistory -EnvironmentId $envId -Result 'Success' -ProjectName $ProjectName
        return $true
    }

    $up = (Resolve-Path ~).Path
    $env:PATH = "$up\miniconda3;$up\miniconda3\Scripts;$up\miniconda3\condabin;$up\miniconda3\Library\bin;$env:PATH"

    & $conda env remove -n $EnvironmentName -y 2>$null | Out-Null
    Write-Host "  [OK] Conda environment $EnvironmentName eliminado" -ForegroundColor Green
    _Complete-EnvironmentHistory -EnvironmentId $envId -Result 'Success' -ProjectName $ProjectName
    return $true
}

<#
.SYNOPSIS
    Obtiene el estado actual del proveedor de entorno.
.PARAMETER Provider
    Objeto EnvironmentProvider.
#>
function Get-EnvironmentProviderStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject]$Provider
    )

    process {
        return [pscustomobject][ordered]@{
            Id              = $Provider.Id
            Name            = $Provider.Name
            Version         = $Provider.Version
            ProviderType    = $Provider.ProviderType
            Status          = $Provider.Status
            IsConnected     = $Provider.IsConnected
            PythonVersion   = $Provider.PythonVersion
            VenvPath        = $Provider.VenvPath
            CondaPath       = $Provider.CondaPath
            LastCreatedEnv  = $Provider.LastCreatedEnv
            ErrorCount      = $Provider.Errors.Count
            LastConnection  = $Provider.LastConnection
        }
    }
}

Write-Verbose '[EnvironmentProvider] Module loaded.'