<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProjectWizard.ps1
Propósito:
    Resuelve qué hacer cuando no hay proyecto: crear, abrir o clonar. Prepara estructura,
    workspace VS Code, Git local y GitHub MOCK sin ejecutar operaciones destructivas reales.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioProjectWizard = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioProjectWizard "..\providers\ProjectManager.ps1")
. (Join-Path $RutaDirectorioProjectWizard "..\providers\GitManager.ps1")
. (Join-Path $RutaDirectorioProjectWizard "..\providers\GitHubManagers.ps1")
. (Join-Path $RutaDirectorioProjectWizard "..\providers\VSCodeManager.ps1")

function Start-HermesEnterpriseProjectWizard {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$RutaBase = ".",

        [Parameter(Mandatory = $false)]
        [string]$NombreProyecto = "HermesProject",

        [Parameter(Mandatory = $false)]
        [switch]$CrearGit,

        [Parameter(Mandatory = $false)]
        [switch]$CrearGitHub
    )

    $RutaBaseAbsoluta = [System.IO.Path]::GetFullPath($RutaBase)
    $RutaProyecto = New-HermesEnterpriseWorkspaceFolder -RutaBase $RutaBaseAbsoluta -NombreCarpeta $NombreProyecto
    $Proyecto = New-HermesEnterpriseProject -NombreProyecto $NombreProyecto -RutaBase $RutaBaseAbsoluta
    $Workspace = New-HermesEnterpriseVSCodeWorkspaceFile -Ruta $RutaProyecto -NombreWorkspace $NombreProyecto
    $Git = if ($CrearGit.IsPresent) { Initialize-HermesEnterpriseProjectRepository -Ruta $RutaProyecto } else { $null }
    $GitHub = if ($CrearGitHub.IsPresent) { New-HermesEnterpriseGitHubRepository -Nombre $NombreProyecto } else { $null }

    return [pscustomobject][ordered]@{
        Proyecto = $Proyecto
        Workspace = $Workspace
        Git = $Git
        GitHub = $GitHub
        Ruta = $RutaProyecto
    }
}
