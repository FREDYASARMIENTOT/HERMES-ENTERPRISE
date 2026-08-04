<#
.SYNOPSIS
    Cierra un proyecto Hermes.
.DESCRIPTION
    Libera recursos, desconecta proveedores y marca el proyecto como cerrado.
.PARAMETER ProjectPath
    Ruta del proyecto a cerrar.
.PARAMETER Force
    Fuerza el cierre sin confirmar.
#>
function Close-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$ProjectPath,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $ProjectPath = (Resolve-Path $ProjectPath).Path
    if ($PSCmdlet.ShouldProcess($ProjectPath, "Close Hermes project")) {
        try {
            _Close-Project -ProjectPath $ProjectPath
            Write-Host "[OK] Project closed: $ProjectPath" -ForegroundColor Green
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
.PARAMETER ProjectPath
    Ruta del proyecto.
#>
function Update-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$ProjectPath
    )

    $ProjectPath = (Resolve-Path $ProjectPath).Path
    if ($PSCmdlet.ShouldProcess($ProjectPath, "Update Hermes project")) {
        try {
            _Update-Project -ProjectPath $ProjectPath
            Write-Host "[OK] Project updated: $ProjectPath" -ForegroundColor Green
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
.PARAMETER ProjectPath
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
        [string]$ProjectPath,

        [Parameter(Mandatory = $false)]
        [string]$RepositoryName = '',

        [Parameter(Mandatory = $false)]
        [switch]$Private,

        [Parameter(Mandatory = $false)]
        [switch]$NoPush
    )

    $ProjectPath = (Resolve-Path $ProjectPath).Path
    $projectName = Split-Path $ProjectPath -Leaf
    if (-not $RepositoryName) { $RepositoryName = $projectName }

    if ($PSCmdlet.ShouldProcess($ProjectPath, "Publish to GitHub as '$RepositoryName'")) {
        try {
            $result = _Publish-ToGitHub -ProjectPath $ProjectPath -RepositoryName $RepositoryName -Private:$Private -NoPush:$NoPush
            if ($result) {
                Write-Host "[OK] Project published: https://github.com/FREDYASARMIENTOT/$RepositoryName" -ForegroundColor Green
            }
        } catch {
            Write-Error "Failed to publish: $_"
        }
    }
}