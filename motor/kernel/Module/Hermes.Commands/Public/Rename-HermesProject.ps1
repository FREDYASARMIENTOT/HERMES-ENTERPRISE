<#
.SYNOPSIS
    Renombra un proyecto Hermes.
.DESCRIPTION
    Cambia el nombre de un proyecto Hermes en la base de datos y opcionalmente renombra la carpeta.
.PARAMETER Path
    Ruta del proyecto a renombrar.
.PARAMETER NewName
    Nuevo nombre del proyecto.
.PARAMETER RenameFolder
    También renombra la carpeta del proyecto.
.EXAMPLE
    Rename-HermesProject -Path "C:\Projects\ViejoNombre" -NewName "NuevoNombre"
#>
function Rename-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$NewName,

        [Parameter(Mandatory = $false)]
        [switch]$RenameFolder
    )

    if ($PSCmdlet.ShouldProcess($Path, "Rename Hermes project to '$NewName'")) {
        Write-Host "[..] Renaming project at '$Path' to '$NewName' ..." -ForegroundColor Yellow

        $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Error "Project path not found: $Path"
            return
        }

        $project = _Get-ProjectFromDb -Path $resolvedPath.Path
        if (-not $project) {
            Write-Error "No Hermes project found at: $Path"
            return
        }

        # Update database
        _Update-ProjectInDb -ProjectId $project.Id -PropertyName 'ProjectName' -PropertyValue $NewName
        Write-Host "[OK] Project renamed in database to: $NewName" -ForegroundColor Green

        # Optionally rename folder
        if ($RenameFolder) {
            $parentPath = Split-Path $resolvedPath.Path -Parent
            $newPath = Join-Path $parentPath $NewName
            Rename-Item -Path $resolvedPath.Path -NewName $NewName -ErrorAction Stop
            Write-Host "[OK] Folder renamed to: $newPath" -ForegroundColor Green
        }
    }
}