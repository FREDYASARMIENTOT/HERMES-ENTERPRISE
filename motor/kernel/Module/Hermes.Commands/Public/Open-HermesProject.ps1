<#
.SYNOPSIS
    Abre un proyecto Hermes en VSCode.
.DESCRIPTION
    Abre el proyecto en la ruta especificada usando code.
.PARAMETER Path
    Ruta del proyecto.
#>
function Open-HermesProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path = ''
    )

    if (-not $Path) {
        $Path = Get-Location
    }
    $resolvedPath = if (Test-Path $Path) { (Resolve-Path $Path).Path } else { $Path }
    $result = _Open-ProjectInVSCode -Path $resolvedPath
    if ($result) {
        Write-Host "[OK] Opened $resolvedPath in VSCode" -ForegroundColor Green
        return $true
    } else {
        Write-Error "Failed to open VSCode."
        return $false
    }
}
