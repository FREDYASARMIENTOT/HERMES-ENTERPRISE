<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : EnvironmentInspector.ps1
Propósito:
    Descubre variables de entorno y preferencias locales sin exponer secretos. Solo lectura.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Get-HermesEnterpriseInstalledTools {
    [CmdletBinding()][OutputType([pscustomobject])]
    param()
    function Test-Command { param([string]$Name) return ($null -ne (Get-Command $Name -ErrorAction SilentlyContinue)) }
    return [pscustomobject][ordered]@{
        PowerShell = $true
        Git        = Test-Command -Name "git"
        VSCode     = Test-Command -Name "code"
        AzureCLI   = Test-Command -Name "az"
        GitHubCLI  = Test-Command -Name "gh"
        Python     = Test-Command -Name "python"
        Docker     = Test-Command -Name "docker"
        Node       = Test-Command -Name "node"
    }
}

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
