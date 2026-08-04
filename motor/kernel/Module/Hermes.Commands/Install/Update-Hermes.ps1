<#
.SYNOPSIS
    Actualiza el módulo Hermes.Commands.
.DESCRIPTION
    Actualiza el módulo desde el repositorio local o GitHub.
.PARAMETER SourcePath
    Ruta del origen (opcional, por defecto busca en el repo).
.PARAMETER Scope
    'CurrentUser' (default) o 'AllUsers'.
#>
function Update-Hermes {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false)]
        [string]$SourcePath = '',

        [Parameter(Mandatory = $false)]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser'
    )

    # Determine source path
    if (-not $SourcePath) {
        # Try to find source in the HERMES-ENTERPRISE repo
        $possiblePaths = @(
            Join-Path $env:USERPROFILE 'HERMES-ENTERPRISE\motor\kernel\Module\Hermes.Commands',
            Join-Path (Get-Location).Path 'motor\kernel\Module\Hermes.Commands',
            Join-Path $PSScriptRoot '..'  # current module directory
        )
        foreach ($p in $possiblePaths) {
            $manifestTest = Join-Path $p 'Hermes.Commands.psd1'
            if (Test-Path $manifestTest) {
                $SourcePath = $p
                break
            }
        }
    }

    if (-not $SourcePath -or -not (Test-Path (Join-Path $SourcePath 'Hermes.Commands.psd1'))) {
        Write-Error "Source path not found. Provide -SourcePath or run from HERMES-ENTERPRISE repo."
        return
    }

    $SourcePath = (Resolve-Path $SourcePath).Path

    if ($Scope -eq 'CurrentUser') {
        $destRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
    } else {
        $destRoot = "$env:ProgramFiles\PowerShell\Modules"
    }

    $destDir = Join-Path $destRoot 'Hermes.Commands'

    if ($PSCmdlet.ShouldProcess($destDir, "Update Hermes.Commands from '$SourcePath'")) {
        try {
            # Remove old version
            if (Test-Path $destDir) {
                Remove-Item -Path $destDir -Recurse -Force -ErrorAction Stop
            }

            # Ensure destination exists
            if (-not (Test-Path $destRoot)) {
                New-Item -Path $destRoot -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }

            # Copy new version
            Copy-Item -Path $SourcePath -Destination $destDir -Recurse -Force -ErrorAction Stop

            # Reload if loaded
            if (Get-Module -Name Hermes.Commands) {
                Remove-Module -Name Hermes.Commands -Force -ErrorAction SilentlyContinue
                Import-Module Hermes.Commands -Force
            }

            Write-Host "[OK] Hermes.Commands updated to: $destDir" -ForegroundColor Green
            Write-Host "[..] Version: $( (Import-PowerShellDataFile (Join-Path $destDir 'Hermes.Commands.psd1')).ModuleVersion )" -ForegroundColor Cyan
        } catch {
            Write-Error "Update failed: $_"
        }
    }
}