<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : WorkspaceProvider.ps1
Propósito:
    Orquestador del Developer Workspace. Importa ProjectManager, GitManager y VSCodeManager
    para exponer una superficie unificada de gestión de proyectos locales.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioWorkspaceProvider = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioWorkspaceProvider "ProjectManager.ps1")
. (Join-Path $RutaDirectorioWorkspaceProvider "GitManager.ps1")
. (Join-Path $RutaDirectorioWorkspaceProvider "VSCodeManager.ps1")

function Get-HermesEnterpriseWorkspaceSummary {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    return [pscustomobject][ordered]@{
        Proyecto = (Open-HermesEnterpriseProject -Ruta $Ruta)
        TieneGit = (Test-HermesEnterpriseGitRepository -Ruta $Ruta)
        TieneWorkspaceVSCode = (Test-HermesEnterpriseVSCodeWorkspace -Ruta $Ruta)
        ComandosDisponibles = @("New-HermesEnterpriseProject", "Open-HermesEnterpriseProject", "Invoke-HermesEnterpriseGitCommand", "Invoke-HermesEnterpriseVSCodeCommand")
    }
}
