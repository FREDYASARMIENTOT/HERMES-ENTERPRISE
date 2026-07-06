<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Start-HermesEnterprise.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Script público para iniciar HERMES Enterprise. Carga el Kernel y gestiona la sesión
    de desarrollo: recupera una sesión existente o ejecuta el Session Wizard.
====================================================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$NombreEntorno = "Desarrollo",

    [Parameter(Mandatory = $false)]
    [switch]$DevolverKernel,

    [Parameter(Mandatory = $false)]
    [switch]$DevolverSesion,

    [Parameter(Mandatory = $false)]
    [switch]$DevolverContexto
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScripts = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScripts

. (Join-Path $RutaRaizRepositorio "motor\bootstrap\Bootstrap.ps1")
. (Join-Path $RutaRaizRepositorio "motor\kernel\KernelValidator.ps1")
. (Join-Path $RutaRaizRepositorio "motor\context\DeveloperContextManager.ps1")

$KernelEnterprise = Start-HermesEnterpriseBootstrap -RutaRaizRepositorio $RutaRaizRepositorio -NombreEntorno $NombreEntorno
$ResultadoValidacionKernel = Test-HermesEnterpriseKernel -KernelEnterprise $KernelEnterprise

if (-not $ResultadoValidacionKernel.EsValido) {
    throw "El Kernel Enterprise no superó la validación: $($ResultadoValidacionKernel.Errores -join '; ')"
}

$RutaWorkspace = $RutaRaizRepositorio
$ContextManager = New-HermesEnterpriseDeveloperContextManager -RutaRaizRepositorio $RutaRaizRepositorio
$DeveloperContext = $ContextManager.BuildContext("HermesProject", $RutaWorkspace)
$DeveloperContext.EstadoKernel = $KernelEnterprise

Write-Host "Hermes Enterprise Kernel iniciado correctamente." -ForegroundColor Green
Write-Host "Estado  : $($KernelEnterprise.EstadoKernel)"
Write-Host "Runtime : $($KernelEnterprise.Runtime.EstadoRuntime)"
Write-Host "Sesión  : $($DeveloperContext.Session.IdentificadorSesion)"
Write-Host "Proyecto: $($DeveloperContext.Proyecto.NombreProyecto)"

if ($DevolverContexto.IsPresent) {
    return $DeveloperContext
}

if ($DevolverSesion.IsPresent) {
    return $DeveloperContext.Session
}

if ($DevolverKernel.IsPresent) {
    return $KernelEnterprise
}
