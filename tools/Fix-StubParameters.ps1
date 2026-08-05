<#
.SYNOPSIS
    Fixes stub parameter names to match RC63 test expectations
.DESCRIPTION
    Renames -ProjectPath to -Path and -TipoEntorno to -Type
    in all Public/*.ps1 stubs to match RC63 Pester tests.
#>

$publicDir = Resolve-Path (Join-Path $PSScriptRoot '..\motor\kernel\Module\Hermes.Commands\Public')
$fixed = 0

# Files that need $ProjectPath -> $Path
$projectPathFiles = @(
    'Backup-HermesProject.ps1',
    'Close-HermesProject.ps1',
    'Export-HermesProject.ps1',
    'Get-HermesEnvironment.ps1',
    'Remove-HermesProject.ps1',
    'Rename-HermesProject.ps1',
    'Update-HermesProject.ps1'
)

foreach ($file in $projectPathFiles) {
    $path = Join-Path $publicDir $file
    if (-not (Test-Path $path)) { continue }
    $content = Get-Content $path -Raw
    $original = $content
    $content = $content -replace '\$ProjectPath', '$Path'
    $content = $content -replace 'ProjectPath', 'Path'
    if ($content -ne $original) {
        Set-Content $path $content -NoNewline -Encoding UTF8
        Write-Host "  [FIXED] $file : ProjectPath -> Path"
        $fixed++
    }
}

# Files that need $WorkspacePath -> $Path
$wsFiles = @('Open-HermesWorkspace.ps1')
foreach ($file in $wsFiles) {
    $path = Join-Path $publicDir $file
    if (-not (Test-Path $path)) { continue }
    $content = Get-Content $path -Raw
    $original = $content
    $content = $content -replace '\$WorkspacePath', '$Path'
    if ($content -ne $original) {
        Set-Content $path $content -NoNewline -Encoding UTF8
        Write-Host "  [FIXED] $file : WorkspacePath -> Path"
        $fixed++
    }
}

# Files that need $ImportPath/$OutputPath/$BackupPath -> $Path/$Destination
$renameMap = @{
    'Import-HermesProject.ps1'  = @{ '$ImportPath' = '$Path'; '$OutputPath' = '$Destination' }
    'Restore-HermesProject.ps1' = @{ '$BackupPath' = '$Path'; '$OutputPath' = '$Destination' }
}
foreach ($file in $renameMap.Keys) {
    $path = Join-Path $publicDir $file
    if (-not (Test-Path $path)) { continue }
    $content = Get-Content $path -Raw
    $original = $content
    foreach ($old in $renameMap[$file].Keys) {
        $content = $content -replace [regex]::Escape($old), $renameMap[$file][$old]
    }
    if ($content -ne $original) {
        Set-Content $path $content -NoNewline -Encoding UTF8
        Write-Host "  [FIXED] $file : parameter renames"
        $fixed++
    }
}

# Files that need $RepositoryUrl/$DestinationPath/$ProjectName -> $Path/$Destination
$cloneContent = Get-Content (Join-Path $publicDir 'Clone-HermesProject.ps1') -Raw
$origClone = $cloneContent
$cloneContent = $cloneContent -replace '\$RepositoryUrl', '$Path'
$cloneContent = $cloneContent -replace '\$DestinationPath', '$Destination'
$cloneContent = $cloneContent -replace '\$ProjectName', '$Branch'
if ($cloneContent -ne $origClone) {
    Set-Content (Join-Path $publicDir 'Clone-HermesProject.ps1') $cloneContent -NoNewline -Encoding UTF8
    Write-Host "  [FIXED] Clone-HermesProject.ps1 : RepositoryUrl->Path, DestinationPath->Destination"
    $fixed++
}

# Files that need $ProjectPath -> $Name (environment commands)
$envFiles = @(
    'Enter-HermesEnvironment.ps1',
    'New-HermesEnvironment.ps1',
    'Remove-HermesEnvironment.ps1',
    'Update-HermesEnvironment.ps1'
)
foreach ($file in $envFiles) {
    $path = Join-Path $publicDir $file
    if (-not (Test-Path $path)) { continue }
    $content = Get-Content $path -Raw
    $original = $content
    $content = $content -replace '\$ProjectPath', '$Name'
    if ($content -ne $original) {
        Set-Content $path $content -NoNewline -Encoding UTF8
        Write-Host "  [FIXED] $file : ProjectPath -> Name"
        $fixed++
    }
}

# Fix New-HermesEnvironment - also rename $TipoEntorno to $Type
$neContent = Get-Content (Join-Path $publicDir 'New-HermesEnvironment.ps1') -Raw
$origNE = $neContent
$neContent = $neContent -replace '\$TipoEntorno', '$Type'
$neContent = $neContent -replace 'TipoEntorno', 'Type'
if ($neContent -ne $origNE) {
    Set-Content (Join-Path $publicDir 'New-HermesEnvironment.ps1') $neContent -NoNewline -Encoding UTF8
    Write-Host "  [FIXED] New-HermesEnvironment.ps1 : TipoEntorno -> Type"
    $fixed++
}

# Fix New-HermesProject - replace $ProjectPath with $Name parameter
$nhpContent = Get-Content (Join-Path $publicDir 'New-HermesProject.ps1') -Raw
$origNhp = $nhpContent
$nhpContent = $nhpContent -replace '\$ProjectPath', '$Name'
$nhpContent = $nhpContent -replace 'ProjectPath', 'Name'
if ($nhpContent -ne $origNhp) {
    Set-Content (Join-Path $publicDir 'New-HermesProject.ps1') $nhpContent -NoNewline -Encoding UTF8
    Write-Host "  [FIXED] New-HermesProject.ps1 : ProjectPath -> Name"
    $fixed++
}

# Fix Open-HermesProject - make Path optional (Mandatory = $false)
$ohpContent = Get-Content (Join-Path $publicDir 'Open-HermesProject.ps1') -Raw
$origOhp = $ohpContent
$ohpContent = $ohpContent -replace '"True"', '"False"'
$ohpContent = $ohpContent -replace '\$ProjectPath', '$Path'
$ohpContent = $ohpContent -replace 'ProjectPath', 'Path'
if ($ohpContent -ne $origOhp) {
    Set-Content (Join-Path $publicDir 'Open-HermesProject.ps1') $ohpContent -NoNewline -Encoding UTF8
    Write-Host "  [FIXED] Open-HermesProject.ps1 : Path optional"
    $fixed++
}

# Fix Get-HermesProject - make Path mandatory, replace $ProjectPath
$ghpContent = Get-Content (Join-Path $publicDir 'Get-HermesProject.ps1') -Raw
$origGhp = $ghpContent
$ghpContent = $ghpContent -replace '"False"', '"True"'
$ghpContent = $ghpContent -replace '\$ProjectPath', '$Path'
$ghpContent = $ghpContent -replace 'ProjectPath', 'Path'
if ($ghpContent -ne $origGhp) {
    Set-Content (Join-Path $publicDir 'Get-HermesProject.ps1') $ghpContent -NoNewline -Encoding UTF8
    Write-Host "  [FIXED] Get-HermesProject.ps1 : Path mandatory"
    $fixed++
}

# Fix Get-HermesConfiguration - make Key optional
$ghcContent = Get-Content (Join-Path $publicDir 'Get-HermesConfiguration.ps1') -Raw
$origGhc = $ghcContent
$ghcContent = $ghcContent -replace '"True"', '"False"'
if ($ghcContent -ne $origGhc) {
    Set-Content (Join-Path $publicDir 'Get-HermesConfiguration.ps1') $ghcContent -NoNewline -Encoding UTF8
    Write-Host "  [FIXED] Get-HermesConfiguration.ps1 : Key optional"
    $fixed++
}

# Fix Publish-HermesProject - replace RepositorioName/Visibility
$pubContent = Get-Content (Join-Path $publicDir 'Publish-HermesProject.ps1') -Raw
$origPub = $pubContent
$pubContent = $pubContent -replace '\$ProjectPath', '$Path'
$pubContent = $pubContent -replace '\$RepositorioName', '$RepoName'
$pubContent = $pubContent -replace 'RepositorioName', 'RepoName'
if ($pubContent -ne $origPub) {
    Set-Content (Join-Path $publicDir 'Publish-HermesProject.ps1') $pubContent -NoNewline -Encoding UTF8
    Write-Host "  [FIXED] Publish-HermesProject.ps1 : RepositorioName -> RepoName"
    $fixed++
}

Write-Host "`n[FIXER] $fixed files updated." -ForegroundColor Green