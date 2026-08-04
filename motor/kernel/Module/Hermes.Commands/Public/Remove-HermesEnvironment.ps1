<#
.SYNOPSIS
    Elimina un entorno virtual Python (venv o conda).
.DESCRIPTION
    Elimina .venv o conda env del proyecto.
.PARAMETER ProjectPath
    Ruta del proyecto.
.PARAMETER TipoEntorno
    'venv' o 'conda'.
.PARAMETER EnvironmentName
    Nombre del entorno (para conda).
.PARAMETER ProjectName
    Nombre del proyecto (telemetría).
#>
function Remove-HermesEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$ProjectPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('venv', 'conda')]
        [string]$TipoEntorno = 'venv',

        [Parameter(Mandatory = $false)]
        [string]$EnvironmentName = '',

        [Parameter(Mandatory = $false)]
        [string]$ProjectName = ''
    )

    $ProjectPath = (Resolve-Path $ProjectPath).Path
    if (-not $ProjectName) { $ProjectName = Split-Path $ProjectPath -Leaf }

    if ($PSCmdlet.ShouldProcess($ProjectPath, "Remove $TipoEntorno environment")) {
        $provider = New-EnvironmentProvider -Id (New-Guid) -Name "env-$ProjectName" -Version '1.0.0' -ProviderType $(if ($TipoEntorno -eq 'venv') { 'VenvEnvironment' } else { 'CondaEnvironment' })

        if ($TipoEntorno -eq 'venv') {
            $result = Remove-VenvEnvironment -Provider $provider -ProjectPath $ProjectPath -ProjectName $ProjectName
        } else {
            if (-not $EnvironmentName) { $EnvironmentName = $ProjectName }
            $result = Remove-CondaEnvironment -Provider $provider -EnvironmentName $EnvironmentName -ProjectName $ProjectName
        }

        if ($result) {
            Write-Host "[OK] $TipoEntorno environment removed." -ForegroundColor Green
        }
    }
}