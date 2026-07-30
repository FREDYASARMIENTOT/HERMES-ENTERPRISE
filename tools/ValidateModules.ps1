# tools/ValidateModules.ps1
Param()
$base = Join-Path $PSScriptRoot '..' | Resolve-Path -Relative
$functionsDir = Join-Path $PSScriptRoot '..\motor\bootstrap\functions'
Write-Host "Validating modules in: $functionsDir"
$failed = @()
Get-ChildItem -Path $functionsDir -Filter '*.ps1' -File -ErrorAction Stop | ForEach-Object {
    $file = $_.FullName
    Write-Host "Loading: $file"
    try {
        . $file
        Write-Host "SUCCESS: $($_.Name)"
    } catch {
        Write-Host "FAILED: $($_.Name) - $($_.Exception.Message)"
        $failed += $_.FullName
    }
}
if ($failed.Count -gt 0) {
    Write-Host "Validation failed for $($failed.Count) module(s)."
    exit 1
} else {
    Write-Host "All modules loaded successfully."
    exit 0
}
