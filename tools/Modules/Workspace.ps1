function Initialize-ProyectoWorkspace {
    <#
    .SYNOPSIS
        Creates the project workspace directory and structure.
    .PARAMETER ProjectName
        Name of the project.
    .PARAMETER OutputDir
        Directory where the project will be created.
    .PARAMETER CorrelationId
        Unique correlation identifier.
    .OUTPUTS
        Hashtable with workspace path information.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectName,
        [Parameter(Mandatory)] [string] $OutputDir,
        [Parameter(Mandatory)] [string] $CorrelationId
    )

    $startTime = Get-Date

    Write-Host "[Workspace] Creating workspace for: $ProjectName"
    Write-Host "[Workspace] Output: $OutputDir"

    if (-not (Test-Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        Write-Host "[Workspace] Created directory: $OutputDir"
    }

    $subdirs = @("backend", "templates", "static", "data", "docs", "scripts")
    foreach ($dir in $subdirs) {
        $fullPath = Join-Path $OutputDir $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
        }
    }

    $elapsed = (Get-Date) - $startTime
    $duration = [math]::Round($elapsed.TotalSeconds, 2)

    Write-Host "[Workspace] Workspace initialized in ${duration}s"

    return @{
        WorkspacePath = $OutputDir
        Subdirs = $subdirs
        Duration = $duration
        Status = "OK"
    }
}

function New-ProyectoWorkspaceFile {
    <#
    .SYNOPSIS
        Creates a VSCode workspace file.
    .PARAMETER ProjectName
        Name of the project.
    .PARAMETER OutputDir
        Directory where the workspace file will be saved.
    .OUTPUTS
        Path to the workspace file.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectName,
        [Parameter(Mandatory)] [string] $OutputDir
    )

    $workspaceFile = Join-Path (Split-Path $OutputDir -Parent) "$ProjectName.code-workspace"
    $workspaceContent = @{
        folders = @(
            @{ path = $OutputDir }
        )
        settings = @{
            "python.defaultInterpreterPath" = "python"
            "files.encoding" = "utf8"
        }
    }
    $workspaceContent | ConvertTo-Json -Depth 3 | Out-File -FilePath $workspaceFile -Encoding UTF8 -Force
    Write-Host "[Workspace] Created workspace file: $workspaceFile"

    return $workspaceFile
}

Export-ModuleMember -Function Initialize-ProyectoWorkspace, New-ProyectoWorkspaceFile