<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : VSCodeManager.ps1
Propósito:
    Encapsula todos los comandos de VS Code utilizados por HERMES Enterprise.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Invoke-HermesEnterpriseVSCodeCommand {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory=$true)][ValidateSet("OpenFolder","OpenWorkspace","OpenFolderReuseWindow","NewWorkspace","NewWindow","ListExtensions","GetSettings","InstallExtension")][string]$Operacion,
        [Parameter(Mandatory=$false)][string]$Ruta = "",
        [Parameter(Mandatory=$false)][string]$NombreWorkspace = "workspace",
        [Parameter(Mandatory=$false)][string]$ExtensionId = ""
    )
    switch ($Operacion) {
        "OpenFolder" { $Comando = "code `"$Ruta`"" }
        "OpenFolderReuseWindow" { $Comando = "code --reuse-window `"$Ruta`"" }
        "OpenWorkspace" { $Comando = "code `"$Ruta`"" }
        "NewWorkspace" { $Comando = "code --new-window `"$(Join-Path $Ruta "$NombreWorkspace.code-workspace")`"" }
        "NewWindow" { $Comando = "code --new-window" }
        "ListExtensions" { $Comando = "code --list-extensions" }
        "GetSettings" { $Comando = "code --show-versions" }
        "InstallExtension" { $Comando = "code --install-extension $ExtensionId" }
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

function Test-HermesEnterpriseVSCodeWorkspace {
    [CmdletBinding()][OutputType([bool])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    return Test-Path (Join-Path $Ruta "*.code-workspace") -PathType Leaf
}

function Get-HermesEnterpriseVSCodeExtensions { [CmdletBinding()]param() Invoke-HermesEnterpriseVSCodeCommand -Operacion ListExtensions }
function Get-HermesEnterpriseVSCodeConfiguration { [CmdletBinding()]param() Invoke-HermesEnterpriseVSCodeCommand -Operacion GetSettings }
function Install-HermesEnterpriseVSCodeExtension { [CmdletBinding()]param([Parameter(Mandatory=$true)][string]$ExtensionId) Invoke-HermesEnterpriseVSCodeCommand -Operacion InstallExtension -ExtensionId $ExtensionId }
