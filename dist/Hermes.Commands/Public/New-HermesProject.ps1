<#
.SYNOPSIS
    Crea un nuevo proyecto Hermes Enterprise.
.DESCRIPTION
    Crea la estructura de carpetas, registra el proyecto en la base de datos,
    y opcionalmente inicializa Git, abre VSCode y publica en GitHub.
.PARAMETER Name
    Ruta donde crear el proyecto.
.PARAMETER ProjectName
    Nombre del proyecto (por defecto: nombre de la carpeta).
.PARAMETER TipoEntorno
    Tipo de entorno virtual: 'venv' o 'conda'.
.PARAMETER InicializarGit
    Inicializa repositorio Git.
.PARAMETER CrearRepositorioGitHub
    Crea repositorio en GitHub.
.PARAMETER AbrirVSCode
    Abre VSCode al finalizar.
.PARAMETER NoPush
    No realiza push inicial a GitHub.
.PARAMETER PythonVersion
    Versión de Python para el entorno virtual.
#>
function New-HermesProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ -not (Test-Path $_) }, ErrorMessage = "Path already exists: '{0}'")]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$ProjectName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('venv', 'conda')]
        [string]$TipoEntorno = 'venv',

        [Parameter(Mandatory = $false)]
        [switch]$InicializarGit,

        [Parameter(Mandatory = $false)]
        [switch]$CrearRepositorioGitHub,

        [Parameter(Mandatory = $false)]
        [switch]$AbrirVSCode,

        [Parameter(Mandatory = $false)]
        [switch]$NoPush,

        [Parameter(Mandatory = $false)]
        [string]$PythonVersion = '3.14'
    )

    if (-not $PSBoundParameters.ContainsKey('ProjectName')) {
        $ProjectName = Split-Path $Name -Leaf
    }

    if ($PSCmdlet.ShouldProcess($Name, "Create Hermes project '$ProjectName'")) {
        Write-Host "[..] Creating project '$ProjectName' at $Name ..." -ForegroundColor Yellow

        $result = _New-ProjectFromFactory -Name $Name -ProjectName $ProjectName `
            -TipoEntorno $TipoEntorno -InicializarGit:$InicializarGit `
            -CrearRepositorioGitHub:$CrearRepositorioGitHub -AbrirVSCode:$AbrirVSCode -NoPush:$NoPush

        if ($result) {
            Write-Host "[OK] Project '$ProjectName' created successfully." -ForegroundColor Green

            # Create venv if requested
            if ($TipoEntorno -eq 'venv') {
                $provider = New-EnvironmentProvider -Id (New-Guid) -Name "env-$ProjectName" -Version '1.0.0' -ProviderType 'VenvEnvironment'
                $venvResult = New-VenvEnvironment -Provider $provider -Name $Name -PythonVersion $PythonVersion -ProjectName $ProjectName
                if ($venvResult) {
                    Write-Host "[OK] Virtual environment created at $(Join-Path $Name '.venv')" -ForegroundColor Green
                }
            }

            # Create environment.yml for conda
            if ($TipoEntorno -eq 'conda') {
                _Create-EnvYml -Name $Name -EnvironmentName $ProjectName -PythonVersion $PythonVersion
                Write-Host "[OK] environment.yml created for conda environment '$ProjectName'" -ForegroundColor Green
            }

            # Create basic requirements.txt
            _Create-RequirementsTxt -Name $Name

            return [pscustomobject]@{
                ProjectName = $ProjectName
                Name = $Name
                TipoEntorno = $TipoEntorno
                Status      = 'Created'
            }
        } else {
            Write-Error "Failed to create project '$ProjectName'."
        }
    }
}