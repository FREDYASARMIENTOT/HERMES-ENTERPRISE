<#
.SYNOPSIS
    Clona un repositorio GitHub como proyecto Hermes.
.DESCRIPTION
    Clona un repositorio y lo registra como proyecto Hermes.
.PARAMETER RepositoryUrl
    URL del repositorio GitHub.
.PARAMETER DestinationPath
    Ruta destino (opcional).
.PARAMETER ProjectName
    Nombre del proyecto (opcional).
.PARAMETER Branch
    Rama a clonar (opcional).
.PARAMETER NoInit
    No inicializa venv después de clonar.
#>
function Clone-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$Destination = '',

        [Parameter(Mandatory = $false)]
        [string]$Branch = '',

        [Parameter(Mandatory = $false)]
        [switch]$NoInit
    )

    if ($PSCmdlet.ShouldProcess($Path, "Clone Hermes project")) {
        try {
            $result = _Clone-FromGitHub -RepositoryUrl $Path -DestinationPath $Destination -ProjectName $Path.Split('/')[-1] -Branch $Branch -NoInit:$NoInit
            if ($result) {
                Write-Host "[OK] Project cloned: $($result.ProjectPath)" -ForegroundColor Green
                return $result
            }
        } catch {
            Write-Error "Failed to clone: $_"
        }
    }
}

<#
.SYNOPSIS
    Importa un proyecto Hermes desde un archivo.
.DESCRIPTION
    Importa un proyecto desde un archivo de backup o exportación (.zip o .json).
.PARAMETER Path
    Ruta del archivo de importación.
.PARAMETER DestinationPath
    Ruta destino para el proyecto importado.
.PARAMETER Force
    Sobrescribe si existe.
#>
function Import-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "File not found: '{0}'")]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($PSCmdlet.ShouldProcess($Path, "Import Hermes project to '$Destination'")) {
        try {
            _Import-ProjectArchive -Path $Path -DestinationPath $Destination -Force:$Force
            Write-Host "[OK] Project imported to $Destination" -ForegroundColor Green
        } catch {
            Write-Error "Failed to import: $_"
        }
    }
}

<#
.SYNOPSIS
    Exporta un proyecto Hermes a un archivo.
.DESCRIPTION
    Exporta un proyecto como archivo .zip para backup o distribución.
.PARAMETER ProjectPath
    Ruta del proyecto.
.PARAMETER OutputPath
    Ruta del archivo de salida.
.PARAMETER ExcludeVenv
    Excluye el directorio .venv.
#>
function Export-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeVenv
    )

    $ProjectPath = (Resolve-Path $ProjectPath).Path
    if ($PSCmdlet.ShouldProcess($ProjectPath, "Export to '$OutputPath'")) {
        try {
            _Export-ProjectArchive -ProjectPath $ProjectPath -OutputPath $OutputPath -ExcludeVenv:$ExcludeVenv
            Write-Host "[OK] Project exported to $OutputPath" -ForegroundColor Green
        } catch {
            Write-Error "Failed to export: $_"
        }
    }
}