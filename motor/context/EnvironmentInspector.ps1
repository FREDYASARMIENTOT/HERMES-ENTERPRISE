<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : EnvironmentInspector.ps1
Propósito:
    Descubre variables de entorno y preferencias locales sin exponer secretos. Solo lectura.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Get-HermesEnterpriseEnvironmentInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $ClavesPermitidas = @("PATH", "USERNAME", "USERPROFILE", "HERMES_HOME", "GITHUB_USER", "VSCODE_CWD")
    $VariablesEntorno = @{}
    foreach ($Clave in $ClavesPermitidas) {
        $VariablesEntorno[$Clave] = [Environment]::GetEnvironmentVariable($Clave)
    }

    $IdiomaPreferido = if ([Environment]::GetEnvironmentVariable("HERMES_LANG")) {
        [Environment]::GetEnvironmentVariable("HERMES_LANG")
    } else {
        "es"
    }

    return [pscustomobject][ordered]@{
        VariablesEntorno = $VariablesEntorno
        IdiomaPreferido  = $IdiomaPreferido
        Region           = [System.Globalization.CultureInfo]::CurrentCulture.Name
        Usuario          = $env:USERNAME
    }
}
