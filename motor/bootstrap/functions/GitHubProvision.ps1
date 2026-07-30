function GitHubProvision {
    param(
        [string]$RepoPath,
        [string]$RepoName
    )
    Write-Host "[PROVISION] Iniciando GitHubProvision para $RepoName"
    Escribir-ProgresoHermes -Evento 'Inicio' -Paso 'GitHubProvision' -Detalle $RepoName

    # Inicializar git si no existe
    if (-not (Test-Path (Join-Path $RepoPath '.git'))) {
        Push-Location $RepoPath
        git init | Out-Null
        git add . | Out-Null
        git commit -m "initial commit" | Out-Null
        Pop-Location
        Escribir-ProgresoHermes -Evento 'Progreso' -Paso 'GitInit' -Detalle 'Git inicializado'
    } else {
        Escribir-ProgresoHermes -Evento 'Progreso' -Paso 'GitInit' -Detalle 'Git ya inicializado'
    }

    # Crear repo en GitHub real usando gh
    try {
        $createCmd = "gh repo create $RepoName --public --source=$RepoPath --remote=origin --push --confirm"
        iex $createCmd
        Escribir-ProgresoHermes -Evento 'Exito' -Paso 'GitHubCreate' -Detalle $RepoName
    } catch {
        Escribir-ProgresoHermes -Evento 'Fallo' -Paso 'GitHubCreate' -Detalle $_
        throw $_
    }

    # Verificar
    try {
        $view = iex "gh repo view $RepoName --json name,url" | Out-String
        Escribir-ProgresoHermes -Evento 'Progreso' -Paso 'GitHubVerify' -Detalle $view
    } catch {
        Escribir-ProgresoHermes -Evento 'Fallo' -Paso 'GitHubVerify' -Detalle $_
        throw $_
    }
}
