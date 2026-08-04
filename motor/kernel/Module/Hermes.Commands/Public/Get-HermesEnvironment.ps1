<#
.SYNOPSIS
    Obtiene información del entorno virtual de un proyecto.
.DESCRIPTION
    Muestra el estado del entorno virtual (venv o conda) en un proyecto.
.PARAMETER ProjectPath
    Ruta del proyecto.
#>
function Get-HermesEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [string]$ProjectPath
    )

    process {
        if ($ProjectPath) {
            if (-not (Test-Path $ProjectPath)) {
                Write-Error "Path not found: $ProjectPath"
                return
            }
            $ProjectPath = (Resolve-Path $ProjectPath).Path
            return _Get-EnvironmentInfo -ProjectPath $ProjectPath
        }

        # List envs for all registered projects
        return _Get-AllEnvironmentsFromDb
    }
}

<#
.SYNOPSIS
    Actualiza la configuración de un entorno virtual.
.DESCRIPTION
    Actualiza la versión de Python o parámetros del entorno.
.PARAMETER ProjectPath
    Ruta del proyecto.
.PARAMETER PythonVersion
    Nueva versión de Python.
.PARAMETER ProjectName
    Nombre del proyecto (telemetría).
#>
function Update-HermesEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$ProjectPath,

        [Parameter(Mandatory = $false)]
        [string]$PythonVersion = '',

        [Parameter(Mandatory = $false)]
        [string]$ProjectName = ''
    )

    $ProjectPath = (Resolve-Path $ProjectPath).Path
    if (-not $ProjectName) { $ProjectName = Split-Path $ProjectPath -Leaf }

    if ($PSCmdlet.ShouldProcess($ProjectPath, "Update environment")) {
        try {
            _Update-Environment -ProjectPath $ProjectPath -PythonVersion $PythonVersion
            Write-Host "[OK] Environment updated for $ProjectName" -ForegroundColor Green
        } catch {
            Write-Error "Failed to update environment: $_"
        }
    }
}

<#
.SYNOPSIS
    Obtiene la versión actual de Hermes Enterprise.
.DESCRIPTION
    Muestra la versión del módulo y del sistema.
#>
function Get-HermesVersion {
    [CmdletBinding()]
    param()

    $moduleInfo = Get-Module -Name Hermes.Commands
    $manifestPath = Join-Path $PSScriptRoot '..' 'Hermes.Commands.psd1'

    $version = '0.0.0'
    if ($moduleInfo) {
        $version = $moduleInfo.Version.ToString()
    } elseif (Test-Path $manifestPath) {
        $manifest = Import-PowerShellDataFile -Path $manifestPath
        $version = $manifest.ModuleVersion
    }

    return [pscustomobject][ordered]@{
        ModuleName    = 'Hermes.Commands'
        ModuleVersion = $version
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        PythonVersion = _Get-PythonVersion
        OSVersion     = [Environment]::OSVersion.VersionString
    }
}