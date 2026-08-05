<#
.SYNOPSIS
    Cierra un proyecto Hermes.
.DESCRIPTION
    Libera recursos, desconecta proveedores y marca el proyecto como cerrado.
.PARAMETER Path
    Ruta del proyecto a cerrar.
.PARAMETER Force
    Fuerza el cierre sin confirmar.
#>
function Close-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $Path = (Resolve-Path $Path).Path
    if ($PSCmdlet.ShouldProcess($Path, "Close Hermes project")) {
        try {
            _Close-Project -Path $Path
            Write-Host "[OK] Project closed: $Path" -ForegroundColor Green
        } catch {
            Write-Error "Failed to close project: $_"
        }
    }
}

<#
.SYNOPSIS
    Actualiza un proyecto Hermes.
.DESCRIPTION
    Sincroniza el estado del proyecto con la base de datos y archivos de configuración.
.PARAMETER Path
    Ruta del proyecto.
#>
function Update-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$Path
    )

    $Path = (Resolve-Path $Path).Path
    if ($PSCmdlet.ShouldProcess($Path, "Update Hermes project")) {
        try {
            _Update-Project -Path $Path
            Write-Host "[OK] Project updated: $Path" -ForegroundColor Green
        } catch {
            Write-Error "Failed to update project: $_"
        }
    }
}

<#
.SYNOPSIS
    Publica un proyecto Hermes en GitHub.
.DESCRIPTION
    Crea un repositorio en GitHub y sube el proyecto.
.PARAMETER Path
    Ruta del proyecto.
.PARAMETER RepositoryName
    Nombre del repositorio (por defecto: nombre del proyecto).
.PARAMETER Private
    Crea repositorio privado.
.PARAMETER NoPush
    No realiza push inicial.
#>
function Publish-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$RepositoryName = '',

        [Parameter(Mandatory = $false)]
        [switch]$Private,

        [Parameter(Mandatory = $false)]
        [switch]$NoPush
    )

    $Path = (Resolve-Path $Path).Path
    $projectName = Split-Path $Path -Leaf
    if (-not $RepositoryName) { $RepositoryName = $projectName }

    if ($PSCmdlet.ShouldProcess($Path, "Publish to GitHub as '$RepositoryName'")) {
        try {
            $result = _Publish-ToGitHub -Path $Path -RepositoryName $RepositoryName -Private:$Private -NoPush:$NoPush
            if ($result) {
                Write-Host "[OK] Project published: https://github.com/FREDYASARMIENTOT/$RepositoryName" -ForegroundColor Green
            }
        } catch {
            Write-Error "Failed to publish: $_"
        }
    }
}