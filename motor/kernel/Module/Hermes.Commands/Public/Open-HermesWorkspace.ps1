<#
.SYNOPSIS
    Abre un workspace de Hermes en VSCode.
.DESCRIPTION
    Abre o crea un workspace .code-workspace con los proyectos Hermes registrados.
    Función canónica (RC63).
.PARAMETER WorkspacePath
    Ruta del workspace a abrir o crear.
.PARAMETER Projects
    Lista de rutas de proyectos para incluir en el workspace.
.EXAMPLE
    Open-HermesWorkspace -WorkspacePath "C:\Projects\mi_workspace.code-workspace"
#>
function Open-HermesWorkspace {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string[]]$Projects
    )

    if ($PSCmdlet.ShouldProcess($Path, "Open Hermes workspace")) {
        Write-Host "[..] Opening workspace at '$Path' ..." -ForegroundColor Yellow

        if (-not (Test-Path $Path)) {
            # Create workspace file
            $workspaceConfig = @{
                folders = @(
                    @{ path = (Split-Path $Path -Parent) }
                )
                settings = @{
                    "hermes.workspace" = $Path
                }
            }

            if ($Projects) {
                $workspaceConfig.folders = $Projects | ForEach-Object {
                    @{ path = $_ }
                }
            }

            $workspaceConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $Path -Encoding UTF8
            Write-Host "[OK] Workspace file created: $Path" -ForegroundColor Green
        }

        # Open in VSCode
        code "$Path"
        Write-Host "[OK] Workspace opened in VSCode." -ForegroundColor Green
    }
}