# tools/DryRun.ps1
Param()
Write-Host "Starting Dry-Run (non-destructive)"
$tools = @( 'ValidateModules.ps1' )
foreach ($t in $tools) {
    $path = Join-Path $PSScriptRoot $t
    Write-Host "Running $path"
    $rc = & powershell -NoProfile -ExecutionPolicy Bypass -File $path
    if ($LASTEXITCODE -ne 0) { Write-Host "Tool failed: $t"; exit 1 }
}
Write-Host "Dry-Run completed successfully (no destructive actions were run)."
exit 0
