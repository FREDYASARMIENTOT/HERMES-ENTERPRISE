<#
.SYNOPSIS
    Crea un entorno virtual para un proyecto Hermes.
.DESCRIPTION
    Crea un entorno virtual (venv) en la ruta del proyecto especificado.
    RC70-D: Conda eliminado. Usa exclusivamente el Runtime Hermes Enterprise.
.PARAMETER ProjectPath
    Ruta del proyecto donde crear el entorno.
.PARAMETER PythonVersion
    Versión de Python para el entorno (default: 3.14).
.EXAMPLE
    New-HermesEnvironment -ProjectPath "C:\Projects\MiProyecto"
#>
function New-HermesEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$PythonVersion = '3.14'
    )

    if ($PSCmdlet.ShouldProcess($Name, "Create venv environment")) {
        Write-Host "[..] Creating venv environment at '$Name' ..." -ForegroundColor Yellow

        $resolvedPath = Resolve-Path $Name -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Error "Project path not found: $Name"
            return
        }

        # RC70-D: Usar el Runtime Hermes Enterprise desde Hermes.Python.json
        $pythonConfigPath = Join-Path $PSScriptRoot "..\..\..\..\config\Hermes.Python.json"
        $pythonExe = "python" # fallback
        if (Test-Path $pythonConfigPath) {
            $pythonConfig = Get-Content $pythonConfigPath -Raw | ConvertFrom-Json
            if ($pythonConfig.RutaPython -and (Test-Path $pythonConfig.RutaPython)) {
                $pythonExe = $pythonConfig.RutaPython
            }
        }

        $provider = New-EnvironmentProvider -Id (New-Guid) -Name "env-$(Split-Path $resolvedPath.Path -Leaf)" -Version '1.0.0' -ProviderType 'VenvEnvironment'
        $venvResult = New-VenvEnvironment -Provider $provider -ProjectPath $resolvedPath.Path -PythonVersion $PythonVersion -PythonExe $pythonExe
        if ($venvResult) {
            Write-Host "[OK] Virtual environment created at $(Join-Path $resolvedPath.Path '.venv')" -ForegroundColor Green
        }
    }
}
