function Create-Project {
    param(
        [Parameter(Mandatory=$true)][string]$NombreProyecto,
        [Parameter(Mandatory=$true)][psobject]$WorkspaceContext
    )
    $Workspace = $WorkspaceContext.Workspace
    $projPath = Join-Path -Path $Workspace -ChildPath $NombreProyecto
    if (Test-Path $projPath) { return @{ Success=$false; Error='Exists'; Path=$projPath } }
    New-Item -ItemType Directory -Path $projPath | Out-Null
    $dirs = @('src','tests','docs','config','.github/workflows','.vscode','logs')
    foreach ($d in $dirs) { New-Item -ItemType Directory -Path (Join-Path $projPath $d) -Force | Out-Null }
    "# $NombreProyecto`n`nProyecto creado por Hermes" | Out-File -FilePath (Join-Path $projPath 'README.md') -Encoding utf8
    "[metadata]\nname = '$NombreProyecto'" | Out-File -FilePath (Join-Path $projPath 'pyproject.toml') -Encoding utf8
    "" | Out-File -FilePath (Join-Path $projPath 'requirements.txt') -Encoding utf8
    "# Python" | Out-File -FilePath (Join-Path $projPath '.gitignore') -Encoding utf8
    git -C $projPath init | Out-Null
    python -m venv (Join-Path $projPath '.venv')
    return @{ Success=$true; Path=$projPath }
}

Export-ModuleMember -Function Create-Project
