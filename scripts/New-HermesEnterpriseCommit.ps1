<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : New-HermesEnterpriseCommit.ps1
Propósito:
    Prepara un commit Git encapsulado mediante HERMES Enterprise.
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)][string]$Ruta = ".",
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Mensaje,
    [Parameter(Mandatory = $false)][string]$Patron = ".",
    [Parameter(Mandatory = $false)][switch]$SoloMostrarComandos
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScripts = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScripts
. (Join-Path $RutaRaizRepositorio "motor\providers\WorkspaceProvider.ps1")

$Add = Add-HermesEnterpriseGitChanges -Ruta $Ruta -Patron $Patron
$Commit = Submit-HermesEnterpriseGitCommit -Ruta $Ruta -Mensaje $Mensaje

Write-Host "Add   : $($Add.Comando)" -ForegroundColor Cyan
Write-Host "Commit: $($Commit.Comando)" -ForegroundColor Cyan

if ($SoloMostrarComandos.IsPresent) { return [pscustomobject]@{ Add = $Add; Commit = $Commit } }
