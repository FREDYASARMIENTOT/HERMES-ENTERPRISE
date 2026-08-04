<#
.SYNOPSIS
    Abre un proyecto Hermes en VSCode.
.DESCRIPTION
    Abre el proyecto en la ruta especificada usando code.
.PARAMETER ProjectPath
    Ruta del proyecto.
#>
function Open-HermesProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$ProjectPath
    )

    $ProjectPath = (Resolve-Path $ProjectPath).Path
    $result = _Open-ProjectInVSCode -ProjectPath $ProjectPath
    if ($result) {
        Write-Host "[OK] Opened $ProjectPath in VSCode" -ForegroundColor Green
    } else {
        Write-Error "Failed to open VSCode."
    }
}