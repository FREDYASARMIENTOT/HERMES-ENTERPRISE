<#
.SYNOPSIS
    Obtiene información del workspace actual de Hermes.
.DESCRIPTION
    Muestra el workspace activo y los proyectos registrados.
    Función canónica (RC63).
.EXAMPLE
    Get-HermesWorkspace
#>
function Get-HermesWorkspace {
    [CmdletBinding()]
    param()

    Write-Host "[..] Getting Hermes workspace information ..." -ForegroundColor Yellow
    $result = _Get-CurrentWorkspace
    if ($result) {
        return $result
    }
    Write-Host "[WARN] No active Hermes workspace found." -ForegroundColor Yellow
    return [pscustomobject]@{
        WorkspacePath = $null
        Projects      = @()
        Status        = 'NoActiveWorkspace'
    }
}