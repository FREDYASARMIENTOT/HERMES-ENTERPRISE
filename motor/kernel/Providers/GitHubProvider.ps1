<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : GitHubProvider.ps1  (REDIRECT)
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    REDIRECT al GitHubProvider canónico en motor/kernel/Module/Hermes.Commands/Providers/.
    Garantiza un único punto de verdad. (MICROFASE 1 — Consolidación)
====================================================================================================
#>

Set-StrictMode -Version Latest

# Redirect to canonical implementation in Hermes.Commands module
$canonicalPath = Join-Path $PSScriptRoot '..\Module\Hermes.Commands\Providers\GitHubProvider.ps1'
if (Test-Path $canonicalPath) {
    . $canonicalPath
} else {
    throw "[GitHubProvider.ps1] Canonical provider not found at: $canonicalPath"
}