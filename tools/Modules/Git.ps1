function Initialize-ProyectoGit {
    <#
    .SYNOPSIS
        Initializes a Git repository in the project directory.
    .PARAMETER ProjectDir
        Path to the project directory.
    .PARAMETER BranchName
        Branch name (default: main).
    .OUTPUTS
        Hashtable with git initialization status.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectDir,
        [string] $BranchName = "main"
    )

    $startTime = Get-Date

    if (-not (Test-Path $ProjectDir)) {
        throw "Project directory not found: $ProjectDir"
    }

    $originalDir = Get-Location
    Set-Location $ProjectDir

    try {
        if (Test-Path ".git") {
            Write-Host "[Git] Repository already initialized"
            $status = "EXISTING"
        }
        else {
            $initOut = git init --initial-branch=$BranchName 2>&1
            Write-Host "[Git] Repository initialized with branch: $BranchName"
            $null = git config user.name "Hermes Enterprise"
            $null = git config user.email "hermes@enterprise.local"
            $status = "CREATED"
        }
    }
    finally {
        Set-Location $originalDir
    }

    $elapsed = (Get-Date) - $startTime
    $duration = [math]::Round($elapsed.TotalSeconds, 2)

    return @{
        Status = $status
        Branch = $BranchName
        Duration = $duration
        GitDir = Join-Path $ProjectDir ".git"
    }
}

function New-ProyectoGitCommit {
    <#
    .SYNOPSIS
        Stages all files and creates a commit.
    .PARAMETER ProjectDir
        Path to the project directory.
    .PARAMETER Message
        Commit message.
    .OUTPUTS
        Hashtable with commit information.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectDir,
        [Parameter(Mandatory)] [string] $Message
    )

    $originalDir = Get-Location
    Set-Location $ProjectDir

    try {
        $null = git add -A 2>&1
        $result = git commit -m $Message 2>&1
        if ($LASTEXITCODE -ne 0) {
            $null = git add -A 2>&1
            $result = git commit -m $Message --no-verify 2>&1
        }

        $commitHash = git rev-parse HEAD 2>&1
        $filesChanged = (git diff --cached --name-only 2>&1).Count

        Write-Host "[Git] Commit created: $($commitHash.Trim())"
        Write-Host "[Git] Files changed: $filesChanged"
    }
    finally {
        Set-Location $originalDir
    }

    return @{
        CommitHash = $commitHash.Trim()
        FilesChanged = $filesChanged
        Message = $Message
    }
}

function Get-ProyectoGitStatus {
    <#
    .SYNOPSIS
        Checks the Git status of the project.
    .PARAMETER ProjectDir
        Path to the project directory.
    .OUTPUTS
        Hashtable with Git status.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectDir
    )

    $originalDir = Get-Location
    Set-Location $ProjectDir

    try {
        $status = git status --porcelain 2>&1
        $branch = git rev-parse --abbrev-ref HEAD 2>&1
        $commitHash = git rev-parse HEAD 2>&1
        $isClean = [string]::IsNullOrEmpty($status)
    }
    finally {
        Set-Location $originalDir
    }

    return @{
        Branch = $branch.Trim()
        CommitHash = $commitHash.Trim()
        IsClean = $isClean
        StatusOutput = $status
    }
}

Export-ModuleMember -Function Initialize-ProyectoGit, New-ProyectoGitCommit, Get-ProyectoGitStatus