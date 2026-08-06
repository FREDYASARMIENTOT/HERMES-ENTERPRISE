<#
.SYNOPSIS
    Activa el entorno virtual de un proyecto Hermes.
.DESCRIPTION
    Activa el entorno virtual (venv) del proyecto especificado. RC70-D: Conda eliminado.
    Función canónica (RC63).
.PARAMETER ProjectPath
    Ruta del proyecto cuyo entorno virtual se activará.
.EXAMPLE
    Enter-HermesEnvironment -ProjectPath "C:\Projects\MiProyecto"
#>
function Enter-HermesEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    Write-Host "[..] Activating environment for '$Name' ..." -ForegroundColor Yellow

    $resolvedPath = Resolve-Path $Name -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        Write-Error "Project path not found: $Name"
        return
    }

    $venvPath = Join-Path $resolvedPath.Path '.venv'
    $activateScript = Join-Path $venvPath 'Scripts\Activate.ps1'

    if (Test-Path $activateScript) {
        . $activateScript
        Write-Host "[OK] Virtual environment activated at: $venvPath" -ForegroundColor Green
    } else {
        Write-Error "No virtual environment found at: $venvPath"
    }
}