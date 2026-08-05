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
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$Path
    )

    $Path = (Resolve-Path $Path).Path
    $result = _Open-ProjectInVSCode -Path $Path
    if ($result) {
        Write-Host "[OK] Opened $Path in VSCode" -ForegroundColor Green
    } else {
        Write-Error "Failed to open VSCode."
    }
}