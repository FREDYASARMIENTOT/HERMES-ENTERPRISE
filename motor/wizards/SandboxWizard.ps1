<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : SandboxWizard.ps1
Propósito:
    Wizard para crear un Sandbox. Pregunta únicamente la ruta base y el escenario.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Start-HermesEnterpriseSandboxWizard {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)][string]$RutaRaizSandbox = "D:\Sandbox",
        [Parameter(Mandatory = $false)][string]$Escenario = "EmptyFolder"
    )

    return [pscustomobject][ordered]@{
        RutaRaizSandbox = $RutaRaizSandbox
        Escenario       = $Escenario
    }
}
