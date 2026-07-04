<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : PluginContracts.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida contratos lógicos para plugins en PowerShell.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Test-HermesEnterprisePluginContract {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombrePlugin)

    $FuncionesRequeridas = @("Install", "Initialize", "Start", "Pause", "Resume", "Stop", "Dispose") | ForEach-Object { "$_-$NombrePlugin" }
    $FuncionesFaltantes = @()

    foreach ($NombreFuncionRequerida in $FuncionesRequeridas) {
        if (-not (Get-Command -Name $NombreFuncionRequerida -ErrorAction SilentlyContinue)) {
            $FuncionesFaltantes += $NombreFuncionRequerida
        }
    }

    return [pscustomobject][ordered]@{
        EsValido = ($FuncionesFaltantes.Count -eq 0)
        Contrato = "IPlugin"
        FuncionesFaltantes = $FuncionesFaltantes
    }
}
