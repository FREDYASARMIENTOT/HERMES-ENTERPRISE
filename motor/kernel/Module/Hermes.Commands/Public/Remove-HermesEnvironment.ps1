<#
.SYNOPSIS
    Elimina el entorno virtual de un proyecto Hermes.
.DESCRIPTION
    Elimina el entorno virtual (venv) asociado al proyecto. RC70-D: Conda eliminado.
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

        # RC70-D: environment.yml ya no se usa (Conda eliminado)
    }
}