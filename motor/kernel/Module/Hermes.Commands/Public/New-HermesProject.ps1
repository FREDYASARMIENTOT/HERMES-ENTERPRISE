<#
.SYNOPSIS
    Crea un nuevo proyecto Hermes Enterprise.
.DESCRIPTION
    Crea la estructura de carpetas, registra el proyecto en la base de datos,
    y opcionalmente inicializa Git, abre VSCode y publica en GitHub.

    Incorpora parámetros opcionales de infraestructura Azure compartida (RC69).
    Los valores Azure se leen de la configuración canónica config/Hermes.Azure.json
    si no se especifican explícitamente.

    Hermes NO descubre recursos Azure. Únicamente LEE configuración.
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
    Versión de Python para el entorno virtual (default: '3.14').

    === PARÁMETROS AZURE (RC69) ===
.PARAMETER UseAzure
    Si se especifica, registra la configuración Azure en el historial SQLite.
.PARAMETER AzureLocation
    Región Azure (override de config/Hermes.Azure.json).
.PARAMETER AzureResourceGroupAplicaciones
    Resource Group para Web Apps (override).
.PARAMETER AzureResourceGroupPlan
    Resource Group del App Service Plan (override).
.PARAMETER AzureAppServicePlan
    Nombre del App Service Plan (override).
.PARAMETER AzureStorageAccount
    Cuenta de almacenamiento (override).
.PARAMETER AzureUseSharedInfrastructure
    Usar infraestructura compartida (override, default: true).
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
        [string]$PythonVersion = '3.14',

        # --- Azure shared infrastructure parameters (RC69) ---
        [Parameter(Mandatory = $false)]
        [switch]$UseAzure,

        [Parameter(Mandatory = $false)]
        [string]$AzureLocation,

        [Parameter(Mandatory = $false)]
        [string]$AzureResourceGroupAplicaciones,

        [Parameter(Mandatory = $false)]
        [string]$AzureResourceGroupPlan,

        [Parameter(Mandatory = $false)]
        [string]$AzureAppServicePlan,

        [Parameter(Mandatory = $false)]
        [string]$AzureStorageAccount,

        [Parameter(Mandatory = $false)]
        [bool]$AzureUseSharedInfrastructure
    )

    if (-not $PSBoundParameters.ContainsKey('ProjectName')) {
        $ProjectName = Split-Path $Name -Leaf
    }

    if ($PSCmdlet.ShouldProcess($Name, "Create Hermes project '$ProjectName'")) {
        Write-Host "[..] Creating project '$ProjectName' at $Name ..." -ForegroundColor Yellow

        # --- RC69: Read canonical Azure configuration ---
        $azureConfig = $null
        if ($UseAzure) {
            $azureConfig = _Read-AzureConfiguration

            # Apply overrides
            if ($PSBoundParameters.ContainsKey('AzureLocation')) {
                if (-not $azureConfig) { $azureConfig = [PSCustomObject]@{} }
                $azureConfig | Add-Member -NotePropertyName 'Location' -NotePropertyValue $AzureLocation -Force
            }
            if ($PSBoundParameters.ContainsKey('AzureResourceGroupAplicaciones')) {
                if (-not $azureConfig) { $azureConfig = [PSCustomObject]@{} }
                $azureConfig | Add-Member -NotePropertyName 'ResourceGroupAplicaciones' -NotePropertyValue $AzureResourceGroupAplicaciones -Force
            }
            if ($PSBoundParameters.ContainsKey('AzureResourceGroupPlan')) {
                if (-not $azureConfig) { $azureConfig = [PSCustomObject]@{} }
                $azureConfig | Add-Member -NotePropertyName 'ResourceGroupPlan' -NotePropertyValue $AzureResourceGroupPlan -Force
            }
            if ($PSBoundParameters.ContainsKey('AzureAppServicePlan')) {
                if (-not $azureConfig) { $azureConfig = [PSCustomObject]@{} }
                $azureConfig | Add-Member -NotePropertyName 'AppServicePlan' -NotePropertyValue $AzureAppServicePlan -Force
            }
            if ($PSBoundParameters.ContainsKey('AzureStorageAccount')) {
                if (-not $azureConfig) { $azureConfig = [PSCustomObject]@{} }
                $azureConfig | Add-Member -NotePropertyName 'StorageAccount' -NotePropertyValue $AzureStorageAccount -Force
            }
            if ($PSBoundParameters.ContainsKey('AzureUseSharedInfrastructure')) {
                if (-not $azureConfig) { $azureConfig = [PSCustomObject]@{} }
                $azureConfig | Add-Member -NotePropertyName 'UseSharedInfrastructure' -NotePropertyValue $AzureUseSharedInfrastructure -Force
            }

            if ($azureConfig) {
                Write-Host "[..] Azure configuration loaded from canonical source" -ForegroundColor Cyan
                Write-Host "      Location               : $($azureConfig.Location)" -ForegroundColor Gray
                Write-Host "      ResourceGroupAplicaciones: $($azureConfig.ResourceGroupAplicaciones)" -ForegroundColor Gray
                Write-Host "      ResourceGroupPlan      : $($azureConfig.ResourceGroupPlan)" -ForegroundColor Gray
                Write-Host "      AppServicePlan         : $($azureConfig.AppServicePlan)" -ForegroundColor Gray

                # Write history to SQLite
                $subscription = $null
                try {
                    $subResult = & az account show --query id --output tsv 2>$null
                    if ($LASTEXITCODE -eq 0 -and $subResult) { $subscription = $subResult.Trim() }
                } catch { $subscription = 'unknown' }

                _Write-AzureHistory -Action 'ProjectCreate' `
                    -Subscription ($subscription ?? 'unknown') `
                    -Location $azureConfig.Location `
                    -ResourceGroupAplicaciones $azureConfig.ResourceGroupAplicaciones `
                    -ResourceGroupPlan $azureConfig.ResourceGroupPlan `
                    -AppServicePlan $azureConfig.AppServicePlan `
                    -ResourceId "AppServicePlan/$($azureConfig.AppServicePlan)" `
                    -Proyecto $ProjectName `
                    -Resultado 'Created'
            } else {
                Write-Warning "[Hermes] -UseAzure specified but no canonical config found at config/Hermes.Azure.json"
            }
        }

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
                ProjectName            = $ProjectName
                Name                   = $Name
                TipoEntorno            = $TipoEntorno
                Status                 = 'Created'
                UseAzure               = $UseAzure.IsPresent
                AzureConfigLoaded      = ($null -ne $azureConfig)
            }
        } else {
            Write-Error "Failed to create project '$ProjectName'."
        }
    }
}