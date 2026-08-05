<#
.SYNOPSIS
    Desinstala el módulo Hermes.Commands.
.DESCRIPTION
    Elimina el módulo del PSModulePath (CurrentUser y/o AllUsers).
.PARAMETER Scope
    'CurrentUser' (default), 'AllUsers', o 'Both' (elimina de ambos).
.PARAMETER Force
    Elimina sin confirmar.
.EXAMPLE
    Uninstall-Hermes -Scope Both
#>
function Uninstall-Hermes {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('CurrentUser', 'AllUsers', 'Both')]
        [string]$Scope = 'CurrentUser',

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $paths = @()
    if ($Scope -in @('CurrentUser', 'Both')) {
        $paths += Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules\Hermes.Commands'
    }
    if ($Scope -in @('AllUsers', 'Both')) {
        $paths += "$env:ProgramFiles\PowerShell\Modules\Hermes.Commands"
    }

    foreach ($path in $paths) {
        if (Test-Path $path) {
            if ($PSCmdlet.ShouldProcess($path, "Remove Hermes.Commands")) {
                try {
                    # Remove from current session if loaded
                    if (Get-Module -Name Hermes.Commands) {
                        Remove-Module -Name Hermes.Commands -Force -ErrorAction SilentlyContinue
                    }

                    Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                    Write-Host "[OK] Removed: $path" -ForegroundColor Green
                } catch {
                    Write-Error "Failed to remove $path : $_"
                }
            }
        } else {
            Write-Host "[..] Not found: $path" -ForegroundColor Yellow
        }
    }

    Write-Host "[OK] Hermes.Commands uninstalled successfully." -ForegroundColor Green
}