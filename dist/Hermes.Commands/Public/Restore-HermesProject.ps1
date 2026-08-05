<#
.SYNOPSIS
    Restaura un proyecto Hermes desde un backup.
.DESCRIPTION
    Restaura un proyecto previamente respaldado con Backup-HermesProject.
.PARAMETER BackupPath
    Ruta al archivo .zip de backup.
.PARAMETER OutputPath
    Ruta destino donde restaurar el proyecto.
.PARAMETER Force
    Sobrescribe si el destino ya existe.
.EXAMPLE
    Restore-HermesProject -BackupPath "C:\Backups\proyecto_2024.zip" -OutputPath "C:\Projects\MiProyecto"
#>
function Restore-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Destination,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($PSCmdlet.ShouldProcess($Destination, "Restore Hermes project from '$Path'")) {
        Write-Host "[..] Restoring project from '$Path' ..." -ForegroundColor Yellow

        if ((Test-Path $Destination) -and -not $Force) {
            Write-Error "Output path already exists: $Destination. Use -Force to overwrite."
            return
        }

        if ((Test-Path $Destination) -and $Force) {
            Remove-Item -Path $Destination -Recurse -Force -ErrorAction SilentlyContinue
        }

        Expand-Archive -Path $Path -DestinationPath (Split-Path $Destination -Parent) -Force
        Write-Host "[OK] Project restored to: $Destination" -ForegroundColor Green
    }
}