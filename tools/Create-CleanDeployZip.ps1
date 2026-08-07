param(
    [string]$SourceDir = "d:\HERMES-ENTERPRISE\Hermes.Web",
    [string]$OutputZip = "d:\HERMES-ENTERPRISE\Hermes.Web.clean.zip"
)

Add-Type -Assembly System.IO.Compression.FileSystem

if (Test-Path $OutputZip) {
    Remove-Item $OutputZip -Force
}

$rel = [System.IO.Compression.ZipFile]::Open($OutputZip, 'Create')

# 1. Agregar todos los archivos bajo Hermes.Web/ (con prefijo)
Get-ChildItem $SourceDir -Recurse -File | Where-Object {
    $_.DirectoryName -notmatch '__pycache__' -and 
    $_.Extension -ne '.pyc' -and 
    $_.Name -ne '.gitkeep'
} | ForEach-Object {
    $baseName = Split-Path $SourceDir -Leaf
    $relPath = "$baseName/$($_.FullName.Substring($SourceDir.Length + 1) -replace '\\', '/')"
    $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($rel, $_.FullName, $relPath)
    Write-Output "Added: $relPath"
}

# 2. Agregar startup.sh en la raiz del zip (Azure necesita startup.sh en /home/site/wwwroot/)
$DeploymentDir = Join-Path $SourceDir "deployment"
$StartupSrc = Join-Path $DeploymentDir "startup.sh"
if (Test-Path $StartupSrc) {
    $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($rel, $StartupSrc, "startup.sh")
    Write-Output "Added: startup.sh (root)"
}

# 3. Buscar requirements.txt
$RootDir = Split-Path $SourceDir -Parent  # d:\HERMES-ENTERPRISE
$RequirementsSrc = Join-Path $SourceDir "requirements.txt"
if (Test-Path $RequirementsSrc) {
    $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($rel, $RequirementsSrc, "requirements.txt")
    Write-Output "Added: requirements.txt (root)"
}

$rel.Dispose()
$f = Get-Item $OutputZip
Write-Output "Created: $($f.Name) ($($f.Length) bytes)"