<#
.SYNOPSIS
    Obtiene información de proyectos Hermes.
.DESCRIPTION
    Lista proyectos registrados o muestra info de un proyecto específico.
.PARAMETER Path
    Ruta del proyecto (opcional). Si se omite, lista todos los proyectos.
#>
function Get-HermesProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path
    )

    if ($Path) {
        if (-not (Test-Path $Path)) {
            Write-Error "Path not found: $Path"
            return
        }
        $Path = (Resolve-Path $Path).Path
        return _Get-ProjectInfo -Path $Path
    }

    # List all projects from DB
    return _Get-AllProjectsFromDb
}