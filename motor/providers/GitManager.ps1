<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : GitManager.ps1
Propósito:
    Wrappers PowerShell para operaciones Git locales. No ejecutan automáticamente.
====================================================================================================
#>
Set-StrictMode -Version Latest

$SCRIPT:HermesEnterpriseGitOperations = @("init","status","branch","remote","add","commit","clone","fetch","pull","push")

function Invoke-HermesEnterpriseGitCommand {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory=$true)][ValidateSet("init","status","branch","remote","add","commit","clone","fetch","pull","push")][string]$Operacion,
        [Parameter(Mandatory=$false)][string]$Ruta = ".",
        [Parameter(Mandatory=$false)][string[]]$Argumentos = @()
    )
    if ($SCRIPT:HermesEnterpriseGitOperations -notcontains $Operacion) { throw "Operación Git no soportada: $Operacion" }
    return [pscustomobject][ordered]@{ Operacion = $Operacion; Ruta = $Ruta; Comando = "git $Operacion $($Argumentos -join ' ')".Trim(); Estado = "Prepared"; Salida = $null }
}

function Initialize-HermesEnterpriseGitRepository { [CmdletBinding()]param([Parameter(Mandatory=$true)][string]$Ruta) Invoke-HermesEnterpriseGitCommand -Operacion init -Ruta $Ruta }
function Get-HermesEnterpriseGitStatus { [CmdletBinding()]param([Parameter(Mandatory=$false)][string]$Ruta = ".") Invoke-HermesEnterpriseGitCommand -Operacion status -Ruta $Ruta }
function Get-HermesEnterpriseGitBranch { [CmdletBinding()]param([Parameter(Mandatory=$false)][string]$Ruta = ".") Invoke-HermesEnterpriseGitCommand -Operacion branch -Ruta $Ruta }
function Get-HermesEnterpriseGitRemote { [CmdletBinding()]param([Parameter(Mandatory=$false)][string]$Ruta = ".") Invoke-HermesEnterpriseGitCommand -Operacion remote -Ruta $Ruta -Argumentos @("-v") }
function Add-HermesEnterpriseGitChanges { [CmdletBinding()]param([Parameter(Mandatory=$false)][string]$Ruta = ".",[Parameter(Mandatory=$false)][string]$Patron = ".") Invoke-HermesEnterpriseGitCommand -Operacion add -Ruta $Ruta -Argumentos @($Patron) }
function Submit-HermesEnterpriseGitCommit { [CmdletBinding()]param([Parameter(Mandatory=$false)][string]$Ruta = ".",[Parameter(Mandatory=$true)][string]$Mensaje) Invoke-HermesEnterpriseGitCommand -Operacion commit -Ruta $Ruta -Argumentos @("-m", "`"$Mensaje`"") }
function Copy-HermesEnterpriseGitRepository { [CmdletBinding()]param([Parameter(Mandatory=$true)][string]$Url,[Parameter(Mandatory=$true)][string]$RutaLocal) Invoke-HermesEnterpriseGitCommand -Operacion clone -Ruta $RutaLocal -Argumentos @($Url) }
function Update-HermesEnterpriseGitRemote { [CmdletBinding()]param([Parameter(Mandatory=$false)][string]$Ruta = ".") Invoke-HermesEnterpriseGitCommand -Operacion fetch -Ruta $Ruta }
function Sync-HermesEnterpriseGitBranch { [CmdletBinding()]param([Parameter(Mandatory=$false)][string]$Ruta = ".") Invoke-HermesEnterpriseGitCommand -Operacion pull -Ruta $Ruta }
function Publish-HermesEnterpriseGitCommits { [CmdletBinding()]param([Parameter(Mandatory=$false)][string]$Ruta = ".") Invoke-HermesEnterpriseGitCommand -Operacion push -Ruta $Ruta }

function Test-HermesEnterpriseGitRepository {
    [CmdletBinding()][OutputType([bool])]
    param([Parameter(Mandatory=$true)][string]$Ruta)
    return Test-Path (Join-Path $Ruta ".git")
}
