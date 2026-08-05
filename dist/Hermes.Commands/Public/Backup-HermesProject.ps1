<#
.SYNOPSIS
    Realiza un backup de un proyecto Hermes.
.DESCRIPTION
    Crea un archivo .zip del proyecto excluyendo .venv.
.PARAMETER Path
    Ruta del proyecto.
.PARAMETER OutputPath
    Ruta del archivo .zip de backup (opcional).
#>
function Backup-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ''
    )

    $Path = (Resolve-Path $Path).Path
    $projectName = Split-Path $Path -Leaf
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

    if (-not $OutputPath) {
        $parentDir = Split-Path $Path -Parent
        $OutputPath = Join-Path $parentDir "${projectName}-backup-${timestamp}.zip"
    }

    if ($PSCmdlet.ShouldProcess($Path, "Backup to '$OutputPath'")) {
        try {
            _Export-ProjectArchive -Path $Path -OutputPath $OutputPath -ExcludeVenv
            Write-Host "[OK] Backup created: $OutputPath" -ForegroundColor Green
        } catch {
            Write-Error "Failed to backup: $_"
        }
    }
}

<#
.SYNOPSIS
    Restaura un proyecto Hermes desde un backup.
.DESCRIPTION
    Restaura un proyecto desde un archivo .zip de backup.
.PARAMETER Path
    Ruta del archivo .zip de backup.
.PARAMETER DestinationPath
    Ruta destino para la restauración.
.PARAMETER Force
    Sobrescribe si existe.
#>
function Restore-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "File not found: '{0}'")]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$DestinationPath = '',

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if (-not $DestinationPath) {
        $parentDir = Split-Path (Get-Location).Path
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        $DestinationPath = Join-Path $parentDir $baseName
        # Clean trailing -backup-* suffix for cleaner name
        $DestinationPath = $DestinationPath -replace '-backup-\d{8}-\d{6}$', ''
    }

    if ($PSCmdlet.ShouldProcess($Path, "Restore to '$DestinationPath'")) {
        try {
            _Import-ProjectArchive -Path $Path -DestinationPath $DestinationPath -Force:$Force
            Write-Host "[OK] Project restored to $DestinationPath" -ForegroundColor Green
        } catch {
            Write-Error "Failed to restore: $_"
        }
    }
}

<#
.SYNOPSIS
    Obtiene información de un workspace Hermes.
.DESCRIPTION
    Lista proyectos en un workspace o muestra info del workspace actual.
.PARAMETER WorkspacePath
    Ruta del workspace (opcional).
#>
function Get-HermesWorkspace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$WorkspacePath
    )

    if ($WorkspacePath -and (Test-Path $WorkspacePath)) {
        $WorkspacePath = (Resolve-Path $WorkspacePath).Path
    }

    return _Get-WorkspaceInfo -WorkspacePath $WorkspacePath
}

<#
.SYNOPSIS
    Abre un workspace Hermes.
.DESCRIPTION
    Abre un workspace (directorio con múltiples proyectos Hermes) en VSCode.
.PARAMETER WorkspacePath
    Ruta del workspace.
#>
function Open-HermesWorkspace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$WorkspacePath
    )

    $WorkspacePath = (Resolve-Path $WorkspacePath).Path
    try {
        $result = _Open-Workspace -WorkspacePath $WorkspacePath
        if ($result) {
            Write-Host "[OK] Workspace opened: $WorkspacePath" -ForegroundColor Green
        }
    } catch {
        Write-Error "Failed to open workspace: $_"
    }
}

<#
.SYNOPSIS
    Cierra un workspace Hermes.
.DESCRIPTION
    Cierra todos los proyectos abiertos en el workspace.
.PARAMETER WorkspacePath
    Ruta del workspace.
.PARAMETER Force
    Fuerza el cierre sin confirmar.
#>
function Close-HermesWorkspace {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$WorkspacePath,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $WorkspacePath = (Resolve-Path $WorkspacePath).Path
    if ($PSCmdlet.ShouldProcess($WorkspacePath, "Close Hermes workspace")) {
        try {
            _Close-Workspace -WorkspacePath $WorkspacePath
            Write-Host "[OK] Workspace closed: $WorkspacePath" -ForegroundColor Green
        } catch {
            Write-Error "Failed to close workspace: $_"
        }
    }
}