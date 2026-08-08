function New-ProyectoDeployZip {
    <#
    .SYNOPSIS
        Creates a deploy ZIP excluding .git, .github, .vscode, logs, __pycache__, *.pyc, temp.
    .PARAMETER SourceDir
        Project directory to package.
    .PARAMETER OutputPath
        Path for the ZIP file.
    .PARAMETER ExcludePatterns
        Array of patterns to exclude (default: .git .github .vscode logs __pycache__ *.pyc temp).
    .OUTPUTS
        Hashtable with ZIP info.
    #>
    param(
        [Parameter(Mandatory)] [string] $SourceDir,
        [Parameter(Mandatory)] [string] $OutputPath,
        [string[]] $ExcludePatterns = @()
    )

    $startTime = Get-Date

    if (-not (Test-Path $SourceDir)) {
        throw "Source directory not found: $SourceDir"
    }

    $outputDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $outputDir)) {
        $null = New-Item -Path $outputDir -ItemType Directory -Force
    }

    if (Test-Path $OutputPath) {
        Remove-Item -Path $OutputPath -Force
    }

    if ($ExcludePatterns.Count -eq 0) {
        $ExcludePatterns = @(".git", ".github", ".vscode", "logs", "__pycache__", "*.pyc", "temp")
    }

    Write-Host "[Packaging] Creating ZIP: $OutputPath"

    $originalDir = Get-Location
    Set-Location $SourceDir

    try {
        $null = Get-Command 7z -ErrorAction SilentlyContinue
        if ($?) {
            $excludeArgs = $ExcludePatterns | ForEach-Object { "-x!$_" }
            $null = & 7z a -tzip $OutputPath . -r @excludeArgs -bso0 -bsp0 2>&1
            Write-Host "[Packaging] ZIP created with 7z"
        } else {
            throw "7z not available"
        }
    }
    catch {
        Write-Host "[Packaging] 7z not available, using Compress-Archive" -ForegroundColor Yellow
        $items = Get-ChildItem -Path $SourceDir
        $compressParams = @{
            Path = $items.FullName
            DestinationPath = $OutputPath
            Force = $true
        }
        if ($PSVersionTable.PSVersion.Major -ge 5) {
            $compressParams.CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
        }
        Compress-Archive @compressParams
    }
    finally {
        Set-Location $originalDir
    }

    $fileInfo = Get-Item $OutputPath
    $sha256 = (Get-FileHash -Path $OutputPath -Algorithm SHA256).Hash

    Write-Host "[Packaging] ZIP created: $OutputPath"
    Write-Host "[Packaging] Size: $([math]::Round($fileInfo.Length / 1KB, 2)) KB"
    Write-Host "[Packaging] SHA256: $sha256"

    $elapsed = (Get-Date) - $startTime
    $duration = [math]::Round($elapsed.TotalSeconds, 2)

    return @{
        ZipPath = $OutputPath
        SizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
        SHA256 = $sha256
        Duration = $duration
        Status = "OK"
    }
}

function Test-DeployZipIntegrity {
    <#
    .SYNOPSIS
        Validates the deploy ZIP structure and integrity.
    .PARAMETER ZipPath
        Path to the ZIP file.
    .OUTPUTS
        Hashtable with validation results.
    #>
    param(
        [Parameter(Mandatory)] [string] $ZipPath
    )

    if (-not (Test-Path $ZipPath)) {
        throw "ZIP file not found: $ZipPath"
    }

    $fileInfo = Get-Item $ZipPath
    $hash = Get-FileHash -Path $ZipPath -Algorithm SHA256

    $requiredFiles = @("main.py", "requirements.txt", "startup.sh", ".gitignore")
    $foundFiles = @()

    try {
        $null = Get-Command 7z -ErrorAction SilentlyContinue
        if ($?) {
            $zipContent = & 7z l $ZipPath -ba 2>&1
            foreach ($file in $requiredFiles) {
                if ($zipContent -match [regex]::Escape($file)) {
                    $foundFiles += $file
                }
            }
        } else {
            throw "7z not available"
        }
    }
    catch {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        $entries = $zip.Entries.FullName
        $zip.Dispose()

        foreach ($file in $requiredFiles) {
            if ($entries -contains $file) {
                $foundFiles += $file
            }
        }
    }

    $missing = $requiredFiles | Where-Object { $_ -notin $foundFiles }

    return @{
        ZipPath = $ZipPath
        SizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
        SHA256 = $hash.Hash
        RequiredFilesFound = $foundFiles.Count
        RequiredFilesTotal = $requiredFiles.Count
        MissingFiles = $missing
        Valid = ($missing.Count -eq 0)
    }
}

Export-ModuleMember -Function New-ProyectoDeployZip, Test-DeployZipIntegrity