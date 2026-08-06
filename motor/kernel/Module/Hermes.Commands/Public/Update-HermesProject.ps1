<#
.SYNOPSIS
    Actualiza la configuración de un proyecto Hermes.
.DESCRIPTION
    Actualiza propiedades del proyecto registrado en la base de datos.
    Función canónica (RC63) — Redirect Stub: actualiza desde RC56.
.PARAMETER Path
    Ruta del proyecto a actualizar.
.PARAMETER ProjectName
    Nuevo nombre del proyecto (opcional).
.PARAMETER TipoEntorno
    Nuevo tipo de entorno (venv). RC70-D: Conda eliminado.
.EXAMPLE
    Update-HermesProject -Path "C:\Projects\MiProyecto" -ProjectName "NuevoNombre"
#>
function Update-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$ProjectName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('venv')]
        [string]$TipoEntorno
    )

    if ($PSCmdlet.ShouldProcess($Path, "Update Hermes project configuration")) {
        Write-Host "[..] Updating project at '$Path' ..." -ForegroundColor Yellow

        $Path = Resolve-Path $Path -ErrorAction SilentlyContinue
        if (-not $Path) {
            Write-Error "Project path not found: $Path"
            return
        }

        $project = _Get-ProjectFromDb -Path $Path.Path
        if (-not $project) {
            Write-Error "No Hermes project found at: $Path"
            return
        }

        if ($ProjectName) {
            _Update-ProjectInDb -ProjectId $project.Id -PropertyName 'ProjectName' -PropertyValue $ProjectName
            Write-Host "[OK] Project name updated to: $ProjectName" -ForegroundColor Green
        }

        if ($TipoEntorno) {
            _Update-ProjectInDb -ProjectId $project.Id -PropertyName 'TipoEntorno' -PropertyValue $TipoEntorno
            Write-Host "[OK] Environment type updated to: $TipoEntorno" -ForegroundColor Green
        }

        if (-not $ProjectName -and -not $TipoEntorno) {
            Write-Host "[WARN] No changes specified. Use -ProjectName and/or -TipoEntorno." -ForegroundColor Yellow
        }
    }
}