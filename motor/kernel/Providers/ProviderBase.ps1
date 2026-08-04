<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProviderBase.ps1  (REDIRECT)
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    REDIRECT al ProviderBase canónico en motor/kernel/Module/Hermes.Commands/Providers/.
    Garantiza un único punto de verdad. (MICROFASE 1 — Consolidación)
====================================================================================================
#>

Set-StrictMode -Version Latest

# Redirect to canonical implementation in Hermes.Commands module
$canonicalPath = Join-Path $PSScriptRoot '..\Module\Hermes.Commands\Providers\ProviderBase.ps1'
if (Test-Path $canonicalPath) {
    . $canonicalPath
} else {
    throw "[ProviderBase.ps1] Canonical provider not found at: $canonicalPath"
}