$modulePath = "d:\HERMES-ENTERPRISE\motor\kernel\Module\Hermes.Commands"
$files = Get-ChildItem -Path $modulePath -Filter "*.ps1" -Recurse
$totalErrors = 0
$fileErrors = @{}

foreach ($file in $files) {
    $errors = @()
    $null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$errors, [ref]$null)
    $count = $errors.Count
    if ($count -gt 0) {
        $totalErrors += $count
        $fileErrors[$file.Name] = $count
        $hasMessage = $false
        foreach ($e in $errors) {
            if ($e.Message) { $hasMessage = $true; break }
        }
        if ($hasMessage -and $count -le 100) {
            Write-Output "ERRORS in $($file.Name): $count"
            foreach ($e in $errors) {
                if ($e.Message) { Write-Output "  Line $($e.Extent.StartLineNumber): $($e.Message)" }
            }
        } elseif ($hasMessage -and $count -gt 100) {
            Write-Output "ERRORS in $($file.Name): $count (showing first 20)"
            $shown = 0
            foreach ($e in $errors) {
                if ($e.Message -and $shown -lt 20) { Write-Output "  Line $($e.Extent.StartLineNumber): $($e.Message)"; $shown++ }
            }
        } else {
            Write-Output "EMPTY ERRORS in $($file.Name): $count (likely BOM issue - harmless on PS7)"
        }
    } else {
        Write-Output "OK: $($file.Name)"
    }
}

Write-Output "---"
Write-Output "Total files with errors: $($fileErrors.Count)"
Write-Output "Total parse errors: $totalErrors"