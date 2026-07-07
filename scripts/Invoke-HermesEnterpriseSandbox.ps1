<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Invoke-HermesEnterpriseSandbox.ps1
Propósito:
    Orquesta el flujo completo del Development Workspace Sandbox usando el ExecutionSupervisor.
    Si ocurre un error, registra, marca FAILED y detiene. No reintenta automáticamente.
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RutaRaizSandbox = "D:\Sandbox",

    [Parameter(Mandatory = $false)]
    [ValidateSet("NoWorkspace", "EmptyFolder", "ExistingProject", "ProjectWithoutGit", "GitWithoutRemote", "GitHubRepository", "ResumeSession", "NewProject", "CloneProject", "MultipleSessions")]
    [string]$Escenario = "EmptyFolder",

    [Parameter(Mandatory = $false)]
    [string]$NombreProyecto = "HermesProject",

    [Parameter(Mandatory = $false)]
    [switch]$Interactive,

    [Parameter(Mandatory = $false)]
    [switch]$NoPause,

    [Parameter(Mandatory = $false)]
    [switch]$OpenVSCode,

    [Parameter(Mandatory = $false)]
    [switch]$SkipSmokeTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScript = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScript

. (Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Initialize-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Invoke-HermesEnterpriseScenario.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Test-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Export-HermesEnterpriseSandboxReport.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseSandboxUserGuide.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseSandboxInstructions.ps1")
. (Join-Path $RutaRaizRepositorio "motor\sandbox\ExecutionLogger.ps1")
. (Join-Path $RutaRaizRepositorio "motor\sandbox\ExecutionDashboard.ps1")
. (Join-Path $RutaRaizRepositorio "motor\sandbox\ExecutionSupervisor.ps1")

Start-HermesEnterpriseExecutionSupervisor -RutaRaizSandbox $RutaRaizSandbox -Escenario $Escenario -NombreProyecto $NombreProyecto -Interactive:$Interactive -NoPause:$NoPause -OpenVSCode:$OpenVSCode -SkipSmokeTest:$SkipSmokeTest
