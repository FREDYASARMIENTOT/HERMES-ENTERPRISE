function Get-ProjectVersion {
    <#
    .SYNOPSIS
        Obtiene la versión del proyecto desde .hermes/bootstrap/CURRENT_STATE.md
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )
    
    $statePath = Join-Path $ProjectRoot ".hermes\bootstrap\CURRENT_STATE.md"
    if (-not (Test-Path $statePath)) {
        return "0.1.0"
    }
    
    $content = Get-Content $statePath -Raw
    if ($content -match '(?m)^version:\s+([^\r\n]+)$') {
        return $matches[1].Trim()
    }
    
    return "0.1.0"
}
