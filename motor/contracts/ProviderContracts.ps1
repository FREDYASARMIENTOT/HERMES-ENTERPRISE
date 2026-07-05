<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderContracts.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida contratos lógicos para providers sin incorporar operaciones de IA ni proveedores reales.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Test-HermesEnterpriseProviderContract {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreProvider)

    $FuncionesRequeridas = @(
        "Initialize",
        "Connect",
        "Disconnect",
        "ValidateConfiguration",
        "GetProviderInformation"
    ) | ForEach-Object { "$_-$NombreProvider" }

    $FuncionesFaltantes = @()
    foreach ($NombreFuncionRequerida in $FuncionesRequeridas) {
        if (-not (Get-Command -Name $NombreFuncionRequerida -ErrorAction SilentlyContinue)) {
            $FuncionesFaltantes += $NombreFuncionRequerida
        }
    }

    return [pscustomobject][ordered]@{
        EsValido = ($FuncionesFaltantes.Count -eq 0)
        Contrato = "IProvider"
        FuncionesFaltantes = $FuncionesFaltantes
    }
}
