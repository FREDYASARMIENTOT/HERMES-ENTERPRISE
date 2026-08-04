<#
.SYNOPSIS
    Elimina un proyecto Hermes.
.DESCRIPTION
    Elimina la carpeta del proyecto y su registro en la base de datos.
.PARAMETER ProjectPath
    Ruta del proyecto a eliminar.
.PARAMETER Force
    Elimina sin confirmar.
#>
function Remove-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$ProjectPath,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($PSCmdlet.ShouldProcess($ProjectPath, "Remove Hermes project")) {
        $ProjectPath = (Resolve-Path $ProjectPath).Path

        # Remove venv if exists
        $venvPath = Join-Path $ProjectPath '.venv'
        if (Test-Path $venvPath) {
            Remove-Item -Path $venvPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        # Remove from DB
        _Remove-ProjectFromDb -ProjectPath $ProjectPath

        # Remove marker
        _Remove-ProjectMarker -ProjectPath $ProjectPath

        # Remove folder
        if ($Force -or $PSCmdlet.ShouldContinue("Delete folder '$ProjectPath'?", "Remove Project")) {
            Remove-Item -Path $ProjectPath -Recurse -Force -ErrorAction Stop
            Write-Host "[OK] Project removed: $ProjectPath" -ForegroundColor Green
        }
    }
}