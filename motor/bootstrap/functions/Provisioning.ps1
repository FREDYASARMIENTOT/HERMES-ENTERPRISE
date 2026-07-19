function Create-LocalProject {
    param([string]$Nombre)
    $sandboxRoot = Join-Path (Get-Location) 'sandbox'
    $projectPath = Join-Path $sandboxRoot $Nombre
    if (-not (Test-Path $projectPath)) { New-Item -Path $projectPath -ItemType Directory -Force | Out-Null }
    New-Item -Path (Join-Path $projectPath 'src') -ItemType Directory -Force | Out-Null
    return $projectPath
}
