<#
.SYNOPSIS
    Activa un entorno virtual Hermes.
.DESCRIPTION
    Retorna el comando para activar .venv o conda env.
.PARAMETER ProjectPath
    Ruta del proyecto.
.PARAMETER TipoEntorno
    'venv' o 'conda'.
.PARAMETER EnvironmentName
    Nombre del entorno (para conda).
#>
function Enter-HermesEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$ProjectPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('venv', 'conda')]
        [string]$TipoEntorno = 'venv',

        [Parameter(Mandatory = $false)]
        [string]$EnvironmentName = ''
    )

    $ProjectPath = (Resolve-Path $ProjectPath).Path
    $provider = New-EnvironmentProvider -Id (New-Guid) -Name 'env-activate' -Version '1.0.0' -ProviderType $(if ($TipoEntorno -eq 'venv') { 'VenvEnvironment' } else { 'CondaEnvironment' })

    if ($TipoEntorno -eq 'venv') {
        return Enter-VenvEnvironment -Provider $provider -ProjectPath $ProjectPath
    } else {
        if (-not $EnvironmentName) { $EnvironmentName = Split-Path $ProjectPath -Leaf }
        return Enter-CondaEnvironment -Provider $provider -EnvironmentName $EnvironmentName
    }
}