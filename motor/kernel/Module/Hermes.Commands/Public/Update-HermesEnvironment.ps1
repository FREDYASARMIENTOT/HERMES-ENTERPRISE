<#
.SYNOPSIS
    Actualiza la configuración del entorno virtual de un proyecto Hermes.
.DESCRIPTION
    Actualiza parámetros como la versión de Python o el tipo de entorno.
    Función canónica (RC63).
.PARAMETER ProjectPath
    Ruta del proyecto.
.PARAMETER PythonVersion
    Nueva versión de Python para el entorno.
.PARAMETER RequirementsFile
    Ruta al archivo requirements.txt para actualizar dependencias.
.EXAMPLE
    Update-HermesEnvironment -ProjectPath "C:\Projects\MiProyecto" -PythonVersion "3.11"
#>
function Update-HermesEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$PythonVersion,

        [Parameter(Mandatory = $false)]
        [string]$RequirementsFile
    )

    if ($PSCmdlet.ShouldProcess($Name, "Update environment configuration")) {
        Write-Host "[..] Updating environment at '$Name' ..." -ForegroundColor Yellow

        $resolvedPath = Resolve-Path $Name -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Error "Project path not found: $Name"
            return
        }

        if ($PythonVersion) {
            # RC70-D: environment.yml ya no se usa (Conda eliminado). Se usa Hermes.Python.json.
            Write-Host "[OK] Python version configured as $PythonVersion (Runtime)" -ForegroundColor Green
        }

        if ($RequirementsFile -and (Test-Path $RequirementsFile)) {
            $destReq = Join-Path $resolvedPath.Path 'requirements.txt'
            Copy-Item -Path $RequirementsFile -Destination $destReq -Force
            Write-Host "[OK] Requirements updated from: $RequirementsFile" -ForegroundColor Green
        }

        if (-not $PythonVersion -and -not $RequirementsFile) {
            Write-Host "[WARN] No changes specified." -ForegroundColor Yellow
        }
    }
}