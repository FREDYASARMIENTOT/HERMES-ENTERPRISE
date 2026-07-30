<#
Configuration Stub
Objetivo: Contrato mínimo de configuración usado por resolver/config loaders.
#>

function Get-HermesConfiguration {
    param([string]$ConfigPath)
    if (-not (Test-Path $ConfigPath)) { throw "Config not found: $ConfigPath" }
    return Get-Content $ConfigPath -Raw | ConvertFrom-Json
}

Export-ModuleMember -Function Get-HermesConfiguration
