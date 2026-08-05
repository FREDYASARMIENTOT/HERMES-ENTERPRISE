<#
.SYNOPSIS
    Elimina un proyecto Hermes.
.DESCRIPTION
    Elimina la carpeta del proyecto y su registro en la base de datos.
.PARAMETER Path
    Ruta del proyecto a eliminar.
.PARAMETER Force
    Elimina sin confirmar.
#>
function Remove-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($PSCmdlet.ShouldProcess($Path, "Remove Hermes project")) {
        $Path = (Resolve-Path $Path).Path

        # Remove venv if exists
        $venvPath = Join-Path $Path '.venv'
        if (Test-Path $venvPath) {
            Remove-Item -Path $venvPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        # Remove from DB
        _Remove-ProjectFromDb -Path $Path

        # Remove marker
        _Remove-ProjectMarker -Path $Path

        # Remove folder
        if ($Force -or $PSCmdlet.ShouldContinue("Delete folder '$Path'?", "Remove Project")) {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            Write-Host "[OK] Project removed: $Path" -ForegroundColor Green
        }
    }
}