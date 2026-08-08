function Initialize-ProyectoGitHubRepo {
    <#
    .SYNOPSIS
        Creates a GitHub repository for the project.
    .PARAMETER ProjectName
        Name of the project (used as repo name).
    .PARAMETER ProjectDir
        Local project directory path.
    .PARAMETER Description
        Repository description.
    .PARAMETER Visibility
        Repository visibility (public/private).
    .OUTPUTS
        Hashtable with repository information.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectName,
        [Parameter(Mandatory)] [string] $ProjectDir,
        [string] $Description = "",
        [ValidateSet("public", "private")] [string] $Visibility = "private"
    )

    $startTime = Get-Date

    $repoName = $ProjectName -replace '\s+', '-' -replace '_', '-' -replace '\.', '-'
    $repoName = $repoName.ToLowerInvariant()

    Write-Host "[GitHub] Creating repository: $repoName"

    # Check if repo already exists
    $existing = $null
    try {
        $existing = gh repo view $repoName --json name 2>&1
        if ($LASTEXITCODE -ne 0) { $existing = $null }
    } catch { $existing = $null }

    if ($existing) {
        Write-Host "[GitHub] Repository already exists: $repoName"
        $created = $false
    }
    else {
        $createOutput = gh repo create $repoName --$Visibility --description $Description 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create GitHub repository: $repoName ($createOutput)"
        }
        Write-Host "[GitHub] Created repository: $repoName"
        $created = $true
    }

    $remoteUrl = "https://github.com/$repoName.git"
    $gitRemote = $null

    $originalDir = Get-Location
    Set-Location $ProjectDir

    try {
        $remotes = git remote 2>&1
        if ($remotes -notcontains "origin") {
            $null = git remote add origin $remoteUrl 2>&1
            Write-Host "[GitHub] Added remote: origin -> $remoteUrl"
        }
        else {
            $null = git remote set-url origin $remoteUrl 2>&1
            Write-Host "[GitHub] Updated remote: origin -> $remoteUrl"
        }
    }
    finally {
        Set-Location $originalDir
    }

    $elapsed = (Get-Date) - $startTime
    $duration = [math]::Round($elapsed.TotalSeconds, 2)

    return @{
        RepoName = $repoName
        RemoteUrl = $remoteUrl
        Created = $created
        Duration = $duration
        Status = "OK"
    }
}

function Push-ProyectoToGitHub {
    <#
    .SYNOPSIS
        Pushes the local repository to GitHub.
    .PARAMETER ProjectDir
        Path to the project directory.
    .PARAMETER Branch
        Branch to push.
    .OUTPUTS
        Hashtable with push status.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectDir,
        [string] $Branch = "main"
    )

    $startTime = Get-Date

    $originalDir = Get-Location
    Set-Location $ProjectDir

    try {
        $pushOut = git push -u origin $Branch 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[GitHub] Push failed, forcing..."
            $pushOut = git push -u origin $Branch --force 2>&1
        }
        Write-Host "[GitHub] Push completed to origin/$Branch"
    }
    finally {
        Set-Location $originalDir
    }

    $elapsed = (Get-Date) - $startTime
    $duration = [math]::Round($elapsed.TotalSeconds, 2)

    return @{
        Branch = $Branch
        Duration = $duration
        Status = "OK"
    }
}

Export-ModuleMember -Function Initialize-ProyectoGitHubRepo, Push-ProyectoToGitHub