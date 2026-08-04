<#
.SYNOPSIS
    Crea un entorno virtual Python (venv o conda).
.DESCRIPTION
    Crea un entorno virtual en el proyecto Hermes especificado.
.PARAMETER ProjectPath
    Ruta del proyecto.
.PARAMETER TipoEntorno
    'venv' o 'conda'.
.PARAMETER PythonVersion
    Versión de Python.
.PARAMETER ProjectName
    Nombre del proyecto (telemetría).
#>
function New-HermesEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = "Path not found: '{0}'")]
        [string]$ProjectPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('venv', 'conda')]
        [string]$TipoEntorno = 'venv',

        [Parameter(Mandatory = $false)]
        [string]$PythonVersion = '3.14',

        [Parameter(Mandatory = $false)]
        [string]$ProjectName = ''
    )

    $ProjectPath = (Resolve-Path $ProjectPath).Path
    if (-not $ProjectName) { $ProjectName = Split-Path $ProjectPath -Leaf }

    if ($PSCmdlet.ShouldProcess($ProjectPath, "Create $TipoEntorno environment")) {
        if ($TipoEntorno -eq 'venv') {
            $provider = New-EnvironmentProvider -Id (New-Guid) -Name "env-$ProjectName" -Version '1.0.0' -ProviderType 'VenvEnvironment'
            $result = New-VenvEnvironment -Provider $provider -ProjectPath $ProjectPath -PythonVersion $PythonVersion -ProjectName $ProjectName
            if ($result) {
                Write-Host "[OK] venv created at $(Join-Path $ProjectPath '.venv')" -ForegroundColor Green
                return $provider
            }
        } else {
            $provider = New-EnvironmentProvider -Id (New-Guid) -Name "env-$ProjectName" -Version '1.0.0' -ProviderType 'CondaEnvironment'
            _Create-EnvYml -ProjectPath $ProjectPath -EnvironmentName $ProjectName -PythonVersion $PythonVersion
            $result = New-CondaEnvironment -Provider $provider -ProjectPath $ProjectPath -EnvironmentName $ProjectName -PythonVersion $PythonVersion -ProjectName $ProjectName
            if ($result) {
                Write-Host "[OK] Conda environment '$ProjectName' created." -ForegroundColor Green
                return $provider
            }
        }
        Write-Error "Failed to create $TipoEntorno environment."
    }
}