<#
.SYNOPSIS
    Exporta un proyecto Hermes a un archivo.
.DESCRIPTION
    Empaqueta un proyecto Hermes en un archivo .zip para respaldo o transferencia.
.PARAMETER Path
    Ruta del proyecto a exportar.
.PARAMETER OutputPath
    Ruta del archivo .zip de salida.
.PARAMETER IncludeHistory
    Incluye datos históricos de la base de datos.
.EXAMPLE
    Export-HermesProject -Path "C:\Projects\MiProyecto" -OutputPath "C:\Backups\mi_proyecto.zip"
#>
function Export-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeHistory
    )

    if ($PSCmdlet.ShouldProcess($Path, "Export Hermes project")) {
        Write-Host "[..] Exporting project at '$Path' ..." -ForegroundColor Yellow

        $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Error "Project path not found: $Path"
            return
        }

        $projectName = Split-Path $resolvedPath.Path -Leaf
        $exportFile = if ($OutputPath) { $OutputPath } else { Join-Path (Get-Location).Path "$projectName.zip" }

        if (Test-Path $exportFile) {
            Write-Error "Output file already exists: $exportFile"
            return
        }

        Compress-Archive -Path $resolvedPath.Path -DestinationPath $exportFile
        Write-Host "[OK] Project exported to: $exportFile" -ForegroundColor Green
    }
}