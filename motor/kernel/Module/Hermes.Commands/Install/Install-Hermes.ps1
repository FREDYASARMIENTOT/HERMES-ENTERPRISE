<#
.SYNOPSIS
    Instala el módulo Hermes.Commands globalmente.
.DESCRIPTION
    Copia el módulo a $PSModulePath y configura el perfil de PowerShell.
.PARAMETER Scope
    'CurrentUser' (default) o 'AllUsers'.
.PARAMETER Force
    Sobrescribe instalación existente.
#>
function Install-Hermes {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser',

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($Scope -eq 'CurrentUser') {
        $destRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
    } else {
        $destRoot = "$env:ProgramFiles\PowerShell\Modules"
    }

    $moduleName = 'Hermes.Commands'
    $sourceDir = Split-Path $PSScriptRoot -Parent
    $destDir = Join-Path $destRoot $moduleName

    if ($PSCmdlet.ShouldProcess($destDir, "Install Hermes.Commands ($Scope)")) {
        try {
            # Remove existing if force
            if ((Test-Path $destDir) -and $Force) {
                Remove-Item -Path $destDir -Recurse -Force -ErrorAction Stop
            }

            # Create destination
            if (-not (Test-Path $destRoot)) {
                New-Item -Path $destRoot -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }

            # Copy all files
            Copy-Item -Path $sourceDir -Destination $destDir -Recurse -Force -ErrorAction Stop

            Write-Host "[OK] Hermes.Commands installed to: $destDir" -ForegroundColor Green
            Write-Host "[..] To load the module, run: Import-Module Hermes.Commands" -ForegroundColor Cyan
        } catch {
            Write-Error "Installation failed: $_"
        }
    }
}

# Self-execute when dot-sourced directly
if ($MyInvocation.InvocationName -eq '.') {
    Install-Hermes -Scope CurrentUser -Force
}