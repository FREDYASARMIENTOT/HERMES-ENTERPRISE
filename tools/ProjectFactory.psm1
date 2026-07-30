function New-Project {
    param(
        [Parameter(Mandatory=$true)][string]$NombreProyecto,
        [Parameter(Mandatory=$true)][string]$WorkspaceRoot
    )

    $projPath = Join-Path -Path $WorkspaceRoot -ChildPath $NombreProyecto
    if (Test-Path $projPath) { return @{ Success = $false; Error = 'ProjectExists' } }
    New-Item -ItemType Directory -Path $projPath | Out-Null

    # Structure
    $dirs = @('src','tests','docs','config','.github/workflows','.vscode','logs')
    foreach ($d in $dirs) { New-Item -ItemType Directory -Path (Join-Path $projPath $d) -Force | Out-Null }

    # Files
    "# $NombreProyecto`n
Proyecto creado por Hermes" | Out-File -FilePath (Join-Path $projPath 'README.md') -Encoding utf8
    "[metadata]\nname = '$NombreProyecto'" | Out-File -FilePath (Join-Path $projPath 'pyproject.toml') -Encoding utf8
    "" | Out-File -FilePath (Join-Path $projPath 'requirements.txt') -Encoding utf8
    "" | Out-File -FilePath (Join-Path $projPath 'requirements-dev.txt') -Encoding utf8
    "# Python" | Out-File -FilePath (Join-Path $projPath '.gitignore') -Encoding utf8

    # Git init
    git -C $projPath init | Out-Null

    # venv
    python -m venv (Join-Path $projPath '.venv')

    return @{ Success=$true; Path=$projPath }
}

Export-ModuleMember -Function New-Project
