<#
.SYNOPSIS
    Cierra el workspace activo de Hermes.
.DESCRIPTION
    Cierra el workspace actual en VSCode y elimina el registro de workspace activo.
    Función canónica (RC63).
.EXAMPLE
    Close-HermesWorkspace
#>
function Close-HermesWorkspace {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    if ($PSCmdlet.ShouldProcess('Active workspace', 'Close Hermes workspace')) {
        Write-Host "[..] Closing active Hermes workspace ..." -ForegroundColor Yellow
        _Close-CurrentWorkspace
        Write-Host "[OK] Workspace closed." -ForegroundColor Green
    }
}