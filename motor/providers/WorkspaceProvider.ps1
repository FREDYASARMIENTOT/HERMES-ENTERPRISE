<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : WorkspaceProvider.ps1
Propósito:
    Gestiona proyectos locales, repositorios Git, workspaces de VS Code e integración con Hermes.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioWorkspaceProvider = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioWorkspaceProvider "ProjectDescriptor.ps1")

$SCRIPT:HermesEnterpriseWorkspaceGitOps = @("init","status","branch","remote","add","commit","clone","fetch","pull","push")

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

function Test-HermesEnterpriseWorkspaceGitRepository {
    [CmdletBinding()][OutputType([bool])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    return Test-Path (Join-Path $Ruta ".git")
}

function Test-HermesEnterpriseWorkspaceVSCodeWorkspace {
    [CmdletBinding()][OutputType([bool])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    return Test-Path (Join-Path $Ruta "*.code-workspace") -PathType Leaf
}

function Invoke-HermesEnterpriseGitCommand {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory=$true)][ValidateSet("init","status","branch","remote","add","commit","clone","fetch","pull","push")][string]$Operacion,
        [Parameter(Mandatory=$false)][string]$Ruta = ".",
        [Parameter(Mandatory=$false)][string[]]$Argumentos = @()
    )
    if ($SCRIPT:HermesEnterpriseWorkspaceGitOps -notcontains $Operacion) { throw "Operación Git no soportada: $Operacion" }
    return [pscustomobject][ordered]@{ Operacion = $Operacion; Ruta = $Ruta; Comando = "git $Operacion $($Argumentos -join ' ')".Trim(); Estado = "Prepared"; Salida = $null }
}

function Invoke-HermesEnterpriseVSCodeCommand {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory=$true)][ValidateSet("OpenFolder","OpenWorkspace","NewWorkspace","NewWindow","ListExtensions","GetSettings")][string]$Operacion,
        [Parameter(Mandatory=$false)][string]$Ruta = "",
        [Parameter(Mandatory=$false)][string]$NombreWorkspace = "workspace"
    )
    switch ($Operacion) {
        "OpenFolder" { $Comando = "code `"$Ruta`"" }
        "OpenWorkspace" { $Comando = "code `"$Ruta`"" }
        "NewWorkspace" { $Comando = "code --new-window `"$(Join-Path $Ruta "$NombreWorkspace.code-workspace")`"" }
        "NewWindow" { $Comando = "code --new-window" }
        "ListExtensions" { $Comando = "code --list-extensions" }
        "GetSettings" { $Comando = "code --show-versions" }
    }
    return [pscustomobject][ordered]@{ Operacion = $Operacion; Ruta = $Ruta; Comando = $Comando; Estado = "Prepared" }
}

function New-HermesEnterpriseVSCodeWorkspaceFile {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$Ruta,[Parameter(Mandatory=$true)][string]$NombreWorkspace)
    return [pscustomobject][ordered]@{
        RutaArchivo = (Join-Path $Ruta "$NombreWorkspace.code-workspace")
        Contenido = '{"folders":[{"path":"."}],"settings":{},"extensions":{"recommendations":[]}}'
        Estado = "Prepared"
    }
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
    $Descriptor.RepositorioGit = Test-HermesEnterpriseWorkspaceGitRepository -Ruta $Ruta
    $Descriptor.WorkspaceVSCode = Test-HermesEnterpriseWorkspaceVSCodeWorkspace -Ruta $Ruta
    return $Descriptor
}

function Initialize-HermesEnterpriseProjectRepository {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    return [pscustomobject][ordered]@{ Proyecto = $Ruta; GitInit = (Invoke-HermesEnterpriseGitCommand -Operacion init -Ruta $Ruta); Estado = "Prepared" }
}

function Get-HermesEnterpriseProjectState {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    return [pscustomobject][ordered]@{ Descriptor = (Open-HermesEnterpriseProject -Ruta $Ruta); GitStatus = (Invoke-HermesEnterpriseGitCommand -Operacion status -Ruta $Ruta) }
}
