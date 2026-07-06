<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProjectManager.ps1
Propósito:
    Gestiona proyectos locales y sus descriptores. No depende de GitHub ni proveedores externos.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioProjectManager = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioProjectManager "ProjectDescriptor.ps1")
. (Join-Path $RutaDirectorioProjectManager "GitManager.ps1")
. (Join-Path $RutaDirectorioProjectManager "VSCodeManager.ps1")

function Select-HermesEnterpriseWorkspaceFolder {
    [CmdletBinding()][OutputType([string])]
    param([Parameter(Mandatory=$false)][string]$RutaPredeterminada = ".")
    $RutaAbsoluta = (Resolve-Path -Path $RutaPredeterminada -ErrorAction SilentlyContinue).Path
    if (-not $RutaAbsoluta) { $RutaAbsoluta = (Resolve-Path -Path ".").Path }
    return $RutaAbsoluta
}

function New-HermesEnterpriseWorkspaceFolder {
    [CmdletBinding()][OutputType([string])]
    param([Parameter(Mandatory=$true)][string]$RutaBase,[Parameter(Mandatory=$true)][string]$NombreCarpeta)
    $RutaCompleta = Join-Path $RutaBase $NombreCarpeta
    if (-not (Test-Path $RutaCompleta)) { New-Item -ItemType Directory -Path $RutaCompleta -Force | Out-Null }
    return (Resolve-Path $RutaCompleta).Path
}

function Test-HermesEnterpriseWorkspaceFolderExists {
    [CmdletBinding()][OutputType([bool])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    return Test-Path $Ruta
}

function New-HermesEnterpriseProject {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$NombreProyecto,[Parameter(Mandatory=$false)][string]$RutaBase = ".",[Parameter(Mandatory=$false)][string]$LenguajePrincipal = "",[Parameter(Mandatory=$false)][string]$TipoProyecto = "")
    $Ruta = New-HermesEnterpriseWorkspaceFolder -RutaBase $RutaBase -NombreCarpeta $NombreProyecto
    return New-HermesEnterpriseProjectDescriptor -NombreProyecto $NombreProyecto -RutaLocal $Ruta -LenguajePrincipal $LenguajePrincipal -TipoProyecto $TipoProyecto
}

function Select-HermesEnterpriseProject {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    return New-HermesEnterpriseProjectDescriptor -NombreProyecto (Split-Path $Ruta -Leaf) -RutaLocal $Ruta
}

function Open-HermesEnterpriseProject {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    $Descriptor = Select-HermesEnterpriseProject -Ruta $Ruta
    $Descriptor.RepositorioGit = Test-HermesEnterpriseGitRepository -Ruta $Ruta
    $Descriptor.WorkspaceVSCode = Test-HermesEnterpriseVSCodeWorkspace -Ruta $Ruta
    $Descriptor.EstadoGit = "Detected"
    return $Descriptor
}

function Initialize-HermesEnterpriseProjectRepository {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    return [pscustomobject][ordered]@{ Proyecto = $Ruta; GitInit = (Initialize-HermesEnterpriseGitRepository -Ruta $Ruta); Estado = "Prepared" }
}

function Get-HermesEnterpriseProjectState {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    return [pscustomobject][ordered]@{ Descriptor = (Open-HermesEnterpriseProject -Ruta $Ruta); GitStatus = (Get-HermesEnterpriseGitStatus -Ruta $Ruta) }
}

function New-HermesEnterpriseProjectReadme {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$Ruta,[Parameter(Mandatory=$true)][string]$NombreProyecto,[Parameter(Mandatory=$false)][string]$Descripcion = "")
    $RutaReadme = Join-Path $Ruta "README.md"
    $Contenido = "# $NombreProyecto`n`n$Descripcion`n"
    return [pscustomobject][ordered]@{ RutaArchivo = $RutaReadme; Contenido = $Contenido; Estado = "Prepared" }
}
