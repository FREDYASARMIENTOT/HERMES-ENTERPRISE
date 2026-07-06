<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProjectDescriptor.ps1
Propósito:
    Descriptor portable de un proyecto local. No depende de GitHub ni de proveedores externos.
====================================================================================================
#>
Set-StrictMode -Version Latest

function New-HermesEnterpriseProjectDescriptor {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$NombreProyecto,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$RutaLocal,
        [Parameter(Mandatory=$false)][string]$RepositorioGit = "",
        [Parameter(Mandatory=$false)][string]$WorkspaceVSCode = "",
        [Parameter(Mandatory=$false)][string]$BranchActual = "",
        [Parameter(Mandatory=$false)][string]$EstadoGit = "Unknown",
        [Parameter(Mandatory=$false)][datetime]$FechaCreacion = (Get-Date),
        [Parameter(Mandatory=$false)][string]$LenguajePrincipal = "",
        [Parameter(Mandatory=$false)][string]$TipoProyecto = "",
        [Parameter(Mandatory=$false)][string]$Descripcion = ""
    )
    return [pscustomobject][ordered]@{
        NombreProyecto = $NombreProyecto
        RutaLocal = $RutaLocal
        RepositorioGit = $RepositorioGit
        WorkspaceVSCode = $WorkspaceVSCode
        BranchActual = $BranchActual
        EstadoGit = $EstadoGit
        FechaCreacion = $FechaCreacion
        LenguajePrincipal = $LenguajePrincipal
        TipoProyecto = $TipoProyecto
        Descripcion = $Descripcion
    }
}
