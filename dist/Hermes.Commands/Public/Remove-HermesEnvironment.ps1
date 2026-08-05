<#
.SYNOPSIS
    Elimina el entorno virtual de un proyecto Hermes.
.DESCRIPTION
    Elimina el entorno virtual (venv/conda) asociado al proyecto.
    Función canónica (RC63).
.PARAMETER ProjectPath
    Ruta del proyecto cuyo entorno se eliminará.
.PARAMETER Force
    Elimina sin confirmación.
.EXAMPLE
    Remove-HermesEnvironment -ProjectPath "C:\Projects\MiProyecto"
#>
function Remove-HermesEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($PSCmdlet.ShouldProcess($Name, "Remove Hermes environment")) {
        Write-Host "[..] Removing environment at '$Name' ..." -ForegroundColor Yellow

        $resolvedPath = Resolve-Path $Name -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Error "Project path not found: $Name"
            return
        }

        $venvPath = Join-Path $resolvedPath.Path '.venv'
        if (Test-Path $venvPath) {
            Remove-Item -Path $venvPath -Recurse -Force
            Write-Host "[OK] Virtual environment removed: $venvPath" -ForegroundColor Green
        } else {
            Write-Host "[WARN] No virtual environment found at: $venvPath" -ForegroundColor Yellow
        }

        $envYmlPath = Join-Path $resolvedPath.Path 'environment.yml'
        if (Test-Path $envYmlPath) {
            Remove-Item -Path $envYmlPath -Force
            Write-Host "[OK] environment.yml removed." -ForegroundColor Green
        }
    }
}