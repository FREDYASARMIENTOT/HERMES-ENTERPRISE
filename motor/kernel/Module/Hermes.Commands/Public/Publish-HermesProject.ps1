<#
.SYNOPSIS
    Publica un proyecto Hermes en GitHub.
.DESCRIPTION
    Crea un repositorio en GitHub y realiza push del proyecto.
    Función canónica (RC63).
.PARAMETER ProjectPath
    Ruta del proyecto a publicar.
.PARAMETER RepoName
    Nombre del repositorio en GitHub (opcional, por defecto nombre del proyecto).
.PARAMETER Visibility
    Visibilidad del repositorio: 'Public' o 'Private'.
.PARAMETER NoPush
    Solo crea el repositorio remoto sin hacer push.
.EXAMPLE
    Publish-HermesProject -ProjectPath "C:\Projects\MiProyecto" -Visibility Public
#>
function Publish-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$RepoName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Public', 'Private')]
        [string]$Visibility = 'Public',

        [Parameter(Mandatory = $false)]
        [switch]$NoPush
    )

    if ($PSCmdlet.ShouldProcess($Path, "Publish Hermes project to GitHub")) {
        Write-Host "[..] Publishing project at '$Path' to GitHub ..." -ForegroundColor Yellow

        $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Error "Project path not found: $Path"
            return
        }

        $project = _Get-ProjectFromDb -ProjectPath $resolvedPath.Path
        if (-not $project) {
            Write-Error "No Hermes project found at: $Path"
            return
        }

        $repoName = if ($RepoName) { $RepoName } else { $project.ProjectName }
        $result = _Publish-ToGitHub -ProjectPath $resolvedPath.Path -RepoName $repoName -Visibility $Visibility -NoPush:$NoPush

        if ($result) {
            Write-Host "[OK] Project published to GitHub: $repoName" -ForegroundColor Green
        } else {
            Write-Error "Failed to publish project to GitHub."
        }
    }
}