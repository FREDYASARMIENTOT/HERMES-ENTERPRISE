<#
.SYNOPSIS
    Crea un entorno virtual para un proyecto Hermes.
.DESCRIPTION
    Crea un entorno virtual (venv o conda) en la ruta del proyecto especificado.
    Función canónica (RC63).
.PARAMETER ProjectPath
    Ruta del proyecto donde crear el entorno.
.PARAMETER Type
    Tipo de entorno: 'venv' (default) o 'conda'.
.PARAMETER PythonVersion
    Versión de Python para el entorno (default: 3.10).
.EXAMPLE
    New-HermesEnvironment -ProjectPath "C:\Projects\MiProyecto" -Type venv
#>
function New-HermesEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('venv', 'conda')]
        [string]$Type = 'venv',

        [Parameter(Mandatory = $false)]
        [string]$PythonVersion = '3.10'
    )

    if ($PSCmdlet.ShouldProcess($Name, "Create $Type environment")) {
        Write-Host "[..] Creating $Type environment at '$Name' ..." -ForegroundColor Yellow

        $resolvedPath = Resolve-Path $Name -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Error "Project path not found: $Name"
            return
        }

        if ($Type -eq 'venv') {
            $provider = New-EnvironmentProvider -Id (New-Guid) -Name "env-$(Split-Path $resolvedPath.Path -Leaf)" -Version '1.0.0' -ProviderType 'VenvEnvironment'
            $venvResult = New-VenvEnvironment -Provider $provider -ProjectPath $resolvedPath.Path -PythonVersion $PythonVersion
            if ($venvResult) {
                Write-Host "[OK] Virtual environment created at $(Join-Path $resolvedPath.Path '.venv')" -ForegroundColor Green
            }
        } elseif ($Type -eq 'conda') {
            $envName = Split-Path $resolvedPath.Path -Leaf
            _Create-EnvYml -ProjectPath $resolvedPath.Path -EnvironmentName $envName -PythonVersion $PythonVersion
            Write-Host "[OK] environment.yml created for conda environment '$envName'" -ForegroundColor Green
        }
    }
}