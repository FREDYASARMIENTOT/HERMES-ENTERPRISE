<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Start-HermesEnterpriseDevelopmentSession.ps1
Propósito:
    Inicia una sesión de desarrollo con HERMES Enterprise, cargando el Kernel y los providers
    de Workspace y GitHub en modo simulado.
====================================================================================================
#>
[CmdletBinding()]
param([Parameter(Mandatory=$false)][switch]$DevolverContexto)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScripts = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScripts

. (Join-Path $RutaRaizRepositorio "motor\bootstrap\Bootstrap.ps1")
. (Join-Path $RutaRaizRepositorio "motor\kernel\KernelValidator.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\WorkspaceProvider.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\GitHubProvider.ps1")

$KernelEnterprise = Start-HermesEnterpriseBootstrap -RutaRaizRepositorio $RutaRaizRepositorio -NombreEntorno "Desarrollo"
$ResultadoValidacionKernel = Test-HermesEnterpriseKernel -KernelEnterprise $KernelEnterprise
if (-not $ResultadoValidacionKernel.EsValido) { throw "El Kernel Enterprise no superó la validación: $($ResultadoValidacionKernel.Errores -join '; ')" }

$GitHubProvider = New-HermesEnterpriseGitHubProvider
$GitHubProvider.ConfiguracionProvider = @{ UsuarioGitHub = "hermes-enterprise" }
Connect-GitHubProvider -ContextoProvider $GitHubProvider | Out-Null

$ContextoDesarrollo = [pscustomobject][ordered]@{
    Kernel = $KernelEnterprise
    GitHubProvider = $GitHubProvider
    RutaRaizRepositorio = $RutaRaizRepositorio
    SesionIniciada = (Get-Date)
}

Write-Host "Sesión de desarrollo HERMES Enterprise iniciada." -ForegroundColor Green
if ($DevolverContexto.IsPresent) { return $ContextoDesarrollo }
