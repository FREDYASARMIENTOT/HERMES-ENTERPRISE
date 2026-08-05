<#
.SYNOPSIS
    Obtiene información del entorno virtual de un proyecto Hermes.
.DESCRIPTION
    Muestra el estado del entorno virtual (venv/conda) de un proyecto.
    Función canónica (RC63).
.PARAMETER Path
    Ruta del proyecto. Si se omite, usa el directorio actual.
.EXAMPLE
    Get-HermesEnvironment -Path "C:\Projects\MiProyecto"
#>
function Get-HermesEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path
    )

    if (-not $Path) {
        $Path = Get-Location
    }

    Write-Host "[..] Getting environment info for '$Path' ..." -ForegroundColor Yellow

    $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        Write-Error "Project path not found: $Path"
        return
    }

    $result = _Get-EnvironmentInfo -Path $resolvedPath.Path
    if ($result) {
        return $result
    }

    Write-Host "[WARN] No virtual environment found." -ForegroundColor Yellow
    return [pscustomobject]@{
        Path     = $resolvedPath.Path
        EnvironmentType = $null
        PythonVersion   = $null
        Status          = 'NotFound'
    }
}