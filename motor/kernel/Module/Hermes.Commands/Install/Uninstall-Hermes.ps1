<#
.SYNOPSIS
    Desinstala el módulo Hermes.Commands.
.DESCRIPTION
    Elimina el módulo del PSModulePath.
.PARAMETER Scope
    'CurrentUser' (default) o 'AllUsers'.
.PARAMETER Force
    Elimina sin confirmar.
#>
function Uninstall-Hermes {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('CurrentUser', 'AllUsers')]
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

    if ($Scope -eq 'CurrentUser') {
        $paths = @(Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules\Hermes.Commands')
    } else {
        $paths = @("$env:ProgramFiles\PowerShell\Modules\Hermes.Commands")
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
}