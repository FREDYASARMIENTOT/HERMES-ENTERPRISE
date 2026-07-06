<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : DeveloperContextManager.ps1
Propósito:
    Servicio de alto nivel para obtener o crear un DeveloperContext, administrando la Session
    automáticamente sin interacción del usuario.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioDCM = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioDCM "ContextBuilder.ps1")
. (Join-Path $RutaDirectorioDCM "..\session\SessionManager.ps1")

function New-HermesEnterpriseDeveloperContextManager {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RutaRaizRepositorio
    )

    $RutaNormalizada = [System.IO.Path]::GetFullPath($RutaRaizRepositorio)

    $Manager = [pscustomobject][ordered]@{
        RutaRaizRepositorio = $RutaNormalizada
    }

    $Manager | Add-Member -MemberType ScriptMethod -Name BuildContext -Value {
        param(
            [Parameter(Mandatory = $false)][string]$NombreProyecto = "",
            [Parameter(Mandatory = $false)][string]$RutaWorkspace = ""
        )

        $Ruta = if ([string]::IsNullOrWhiteSpace($RutaWorkspace)) { $this.RutaRaizRepositorio } else { $RutaWorkspace }
        $Nombre = if ([string]::IsNullOrWhiteSpace($NombreProyecto)) { "HermesProject" } else { $NombreProyecto }

        $Session = Open-HermesEnterpriseSession -RutaRaizRepositorio $this.RutaRaizRepositorio
        if ($null -eq $Session) {
            $Session = New-HermesEnterpriseSessionFromContext `
                -RutaRaizRepositorio $this.RutaRaizRepositorio `
                -NombreProyecto $Nombre `
                -RutaWorkspace $Ruta
        }

        $Contexto = Build-HermesEnterpriseDeveloperContext `
            -RutaWorkspace $Ruta `
            -NombreProyecto $Nombre `
            -Session $Session

        $Contexto.Session = $Session
        return $Contexto
    }

    return $Manager
}
