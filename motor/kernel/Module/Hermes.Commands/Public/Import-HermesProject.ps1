<#
.SYNOPSIS
    Importa un proyecto Hermes desde un archivo de exportación.
.DESCRIPTION
    Restaura un proyecto previamente exportado desde un archivo .zip o .json.
.PARAMETER ImportPath
    Ruta al archivo de importación (.zip o .json).
.PARAMETER OutputPath
    Ruta destino donde importar el proyecto.
.PARAMETER Force
    Sobrescribe si el destino ya existe.
.EXAMPLE
    Import-HermesProject -ImportPath "C:\Backups\proyecto_export.zip" -OutputPath "C:\Projects\MiProyecto"
#>
function Import-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Destination,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($PSCmdlet.ShouldProcess($Destination, "Import Hermes project from '$Path'")) {
        Write-Host "[..] Importing project from '$Path' ..." -ForegroundColor Yellow

        $extension = [System.IO.Path]::GetExtension($Path).ToLower()
        if ($extension -eq '.zip') {
            if ((Test-Path $Destination) -and -not $Force) {
                Write-Error "Output path already exists: $Destination. Use -Force to overwrite."
                return
            }
            if ((Test-Path $Destination) -and $Force) {
                Remove-Item -Path $Destination -Recurse -Force
            }
            Expand-Archive -Path $Path -DestinationPath $Destination -Force
            Write-Host "[OK] Project imported successfully to: $Destination" -ForegroundColor Green
        } elseif ($extension -eq '.json') {
            $config = Get-Content -Path $Path -Raw | ConvertFrom-Json
            Write-Host "[OK] Configuration imported from: $Path" -ForegroundColor Green
        } else {
            Write-Error "Unsupported file format: $extension. Use .zip or .json."
        }
    }
}