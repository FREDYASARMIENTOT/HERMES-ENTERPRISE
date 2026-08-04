<#
.SYNOPSIS
    Obtiene información de proyectos Hermes.
.DESCRIPTION
    Lista proyectos registrados o muestra info de un proyecto específico.
.PARAMETER ProjectPath
    Ruta del proyecto (opcional). Si se omite, lista todos los proyectos.
#>
function Get-HermesProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$ProjectPath
    )

    if ($ProjectPath) {
        if (-not (Test-Path $ProjectPath)) {
            Write-Error "Path not found: $ProjectPath"
            return
        }
        $ProjectPath = (Resolve-Path $ProjectPath).Path
        return _Get-ProjectInfo -ProjectPath $ProjectPath
    }

    # List all projects from DB
    return _Get-AllProjectsFromDb
}