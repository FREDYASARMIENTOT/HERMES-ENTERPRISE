function Crear-RepositorioGitHubProyecto {
    <#
    .SYNOPSIS
        Crea un repositorio en GitHub para el proyecto.
    .PARAMETER ProjectName
        Nombre del proyecto (se usará como nombre del repositorio).
    .PARAMETER ProjectDir
        Ruta local del directorio del proyecto.
    .PARAMETER Description
        Descripción del repositorio.
    .PARAMETER Visibility
        Visibilidad del repositorio (public/private).
    .OUTPUTS
        Hashtable con la información del repositorio creado.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectName,
        [Parameter(Mandatory)] [string] $ProjectDir,
        [string] $Description = "",
        [ValidateSet("public", "private")] [string] $Visibility = "private"
    )

    $horaInicio = Get-Date

    $nombreRepositorio = $ProjectName -replace '\s+', '-' -replace '_', '-' -replace '\.', '-'
    $nombreRepositorio = $nombreRepositorio.ToLowerInvariant()

    Write-Host "[GitHub] Creando repositorio: $nombreRepositorio"

    # Verifica si el repositorio ya existe
    $existente = $null
    try {
        $existente = gh repo view $nombreRepositorio --json name 2>&1
        if ($LASTEXITCODE -ne 0) { $existente = $null }
    } catch { $existente = $null }

    if ($existente) {
        Write-Host "[GitHub] El repositorio ya existe: $nombreRepositorio"
        $creado = $false
    }
    else {
        $salidaCreacion = gh repo create $nombreRepositorio --$Visibility --description $Description 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Error al crear repositorio en GitHub: $nombreRepositorio ($salidaCreacion)"
        }
        Write-Host "[GitHub] Repositorio creado: $nombreRepositorio"
        $creado = $true
    }

    $urlRemoto = "https://github.com/$nombreRepositorio.git"

    $directorioOriginal = Get-Location
    Set-Location $ProjectDir

    try {
        $remotos = git remote 2>&1
        if ($remotos -notcontains "origin") {
            $null = git remote add origin $urlRemoto 2>&1
            Write-Host "[GitHub] Remoto agregado: origin -> $urlRemoto"
        }
        else {
            $null = git remote set-url origin $urlRemoto 2>&1
            Write-Host "[GitHub] Remoto actualizado: origin -> $urlRemoto"
        }
    }
    finally {
        Set-Location $directorioOriginal
    }

    $tiempoTranscurrido = (Get-Date) - $horaInicio
    $duracion = [math]::Round($tiempoTranscurrido.TotalSeconds, 2)

    return @{
        RepoName = $nombreRepositorio
        RemoteUrl = $urlRemoto
        Created = $creado
        Duration = $duracion
        Status = "OK"
    }
}

function Publicar-ProyectoEnGitHub {
    <#
    .SYNOPSIS
        Publica (push) el repositorio local en GitHub.
    .PARAMETER ProjectDir
        Ruta al directorio del proyecto.
    .PARAMETER Branch
        Rama a publicar.
    .OUTPUTS
        Hashtable con el estado de la publicación.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectDir,
        [string] $Branch = "main"
    )

    $horaInicio = Get-Date

    $directorioOriginal = Get-Location
    Set-Location $ProjectDir

    try {
        $salidaPublicacion = git push -u origin $Branch 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[GitHub] Publicación fallida, reintentando con --force..."
            $salidaPublicacion = git push -u origin $Branch --force 2>&1
        }
        Write-Host "[GitHub] Publicación completada en origin/$Branch"
    }
    finally {
        Set-Location $directorioOriginal
    }

    $tiempoTranscurrido = (Get-Date) - $horaInicio
    $duracion = [math]::Round($tiempoTranscurrido.TotalSeconds, 2)

    return @{
        Branch = $Branch
        Duration = $duracion
        Status = "OK"
    }
}

function Establecer-SecretosGitHubAcciones {
    <#
    .SYNOPSIS
        Configura los secretos de GitHub Actions necesarios para la autenticación OIDC en Azure.
        Utiliza gh secret set para almacenar credenciales de forma segura sin exponerlas.
    .PARAMETER RepoName
        Nombre del repositorio en GitHub (OWNER/REPO).
    .PARAMETER AzureClientId
        Client ID de Azure App Registration para identidad federada OIDC.
    .PARAMETER AzureTenantId
        Tenant ID de Azure.
    .PARAMETER AzureSubscriptionId
        Subscription ID de Azure.
    .OUTPUTS
        Hashtable con el estado de configuración de secretos.
    .NOTES
        Esta función utiliza GitHub CLI (gh) para establecer secretos.
        Nunca escribe secretos en archivos, registros o salida estándar.
    #>
    param(
        [Parameter(Mandatory)] [string] $RepoName,
        [Parameter(Mandatory)] [string] $AzureClientId,
        [Parameter(Mandatory)] [string] $AzureTenantId,
        [Parameter(Mandatory)] [string] $AzureSubscriptionId
    )

    $horaInicio = Get-Date
    $resultados = @{}

    Write-Host "[GitHub] Configurando secretos de Actions para: $RepoName"

    # Secreto AZURE_CLIENT_ID
    $null = gh secret set AZURE_CLIENT_ID --repo $RepoName --body $AzureClientId 2>&1
    if ($LASTEXITCODE -eq 0) {
        $resultados["AZURE_CLIENT_ID"] = "OK"
        Write-Host "[GitHub] Secreto AZURE_CLIENT_ID configurado"
    } else {
        $resultados["AZURE_CLIENT_ID"] = "FAIL"
        Write-Warning "[GitHub] Error al configurar AZURE_CLIENT_ID"
    }

    # Secreto AZURE_TENANT_ID
    $null = gh secret set AZURE_TENANT_ID --repo $RepoName --body $AzureTenantId 2>&1
    if ($LASTEXITCODE -eq 0) {
        $resultados["AZURE_TENANT_ID"] = "OK"
        Write-Host "[GitHub] Secreto AZURE_TENANT_ID configurado"
    } else {
        $resultados["AZURE_TENANT_ID"] = "FAIL"
        Write-Warning "[GitHub] Error al configurar AZURE_TENANT_ID"
    }

    # Secreto AZURE_SUBSCRIPTION_ID
    $null = gh secret set AZURE_SUBSCRIPTION_ID --repo $RepoName --body $AzureSubscriptionId 2>&1
    if ($LASTEXITCODE -eq 0) {
        $resultados["AZURE_SUBSCRIPTION_ID"] = "OK"
        Write-Host "[GitHub] Secreto AZURE_SUBSCRIPTION_ID configurado"
    } else {
        $resultados["AZURE_SUBSCRIPTION_ID"] = "FAIL"
        Write-Warning "[GitHub] Error al configurar AZURE_SUBSCRIPTION_ID"
    }

    $tiempoTranscurrido = (Get-Date) - $horaInicio
    $duracion = [math]::Round($tiempoTranscurrido.TotalSeconds, 2)

    return @{
        Status = if ($resultados.Values -notcontains "FAIL") { "OK" } else { "PARCIAL" }
        Secrets = $resultados
        Duration = $duracion
    }
}

Export-ModuleMember -Function Crear-RepositorioGitHubProyecto, Publicar-ProyectoEnGitHub, Establecer-SecretosGitHubAcciones