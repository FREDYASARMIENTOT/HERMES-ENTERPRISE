<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : BootstrapConfiguration.usecase.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Use Case: BootstrapConfiguration
    Coordina la configuración inicial del entorno de desarrollo HERMES-ENTERPRISE.
    Capacidades requeridas:
        - "bootstrap.environment"
        - "bootstrap.modules"
        - "bootstrap.configuration"
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea un scriptblock resolver para la capacidad "bootstrap.environment".
.DESCRIPTION
    Resolver que verifica y configura el entorno base (git, az, gh, dotnet, node, python).
.PARAMETER UseCaseContext
    El contexto del Use Case con los parámetros de entrada.
.PARAMETER Container
    El contenedor de dependencias del sistema.
#>
function New-BootstrapEnvironmentResolver {
    [CmdletBinding()]
    param()

    return {
        param(
            [Parameter(Mandatory = $true)]
            [ValidateNotNull()]
            [psobject]$UseCaseContext,

            [Parameter(Mandatory = $true)]
            [ValidateNotNull()]
            [psobject]$Container
        )

        Write-Verbose "[BootstrapConfiguration] Resolving capability: bootstrap.environment"

        $workspacePath = $UseCaseContext.InputParameters['WorkspacePath']
        if ([string]::IsNullOrEmpty($workspacePath)) {
            $workspacePath = (Get-Location).Path
        }

        # Verificar herramientas requeridas
        $tools = @('git', 'gh', 'az', 'dotnet', 'node', 'python')
        $results = [System.Collections.ArrayList]@()

        foreach ($tool in $tools) {
            try {
                $toolPath = (Get-Command $tool -ErrorAction Stop).Source
                $null = $results.Add([pscustomobject]@{
                    Tool     = $tool
                    Found    = $true
                    Path     = $toolPath
                })
            }
            catch {
                $null = $results.Add([pscustomobject]@{
                    Tool     = $tool
                    Found    = $false
                    Path     = $null
                })
            }
        }

        # Verificar estructura de directorios
        $requiredDirs = @('motor', 'scripts', 'tools', 'pruebas', 'docs')
        $dirStatus = [System.Collections.ArrayList]@()
        foreach ($dir in $requiredDirs) {
            $dirPath = Join-Path -Path $workspacePath -ChildPath $dir
            $exists = Test-Path -Path $dirPath -PathType Container
            $null = $dirStatus.Add([pscustomobject]@{
                Directory = $dir
                Exists    = $exists
                Path      = $dirPath
            })
        }

        return [pscustomobject][ordered]@{
            Capability = 'bootstrap.environment'
            Status     = 'Completed'
            Output     = @{
                WorkspacePath  = $workspacePath
                ToolsChecked   = @($results)
                Directories    = @($dirStatus)
                AllToolsFound  = ($results | Where-Object { -not $_.Found }).Count -eq 0
                AllDirsExist   = ($dirStatus | Where-Object { -not $_.Exists }).Count -eq 0
            }
        }
    }
}

<#
.SYNOPSIS
    Crea un scriptblock resolver para la capacidad "bootstrap.modules".
.DESCRIPTION
    Verifica que los módulos requeridos del Kernel estén presentes y cargados correctamente.
.PARAMETER UseCaseContext
    El contexto del Use Case con los parámetros de entrada.
.PARAMETER Container
    El contenedor de dependencias del sistema.
#>
function New-BootstrapModulesResolver {
    [CmdletBinding()]
    param()

    return {
        param(
            [Parameter(Mandatory = $true)]
            [ValidateNotNull()]
            [psobject]$UseCaseContext,

            [Parameter(Mandatory = $true)]
            [ValidateNotNull()]
            [psobject]$Container
        )

        Write-Verbose "[BootstrapConfiguration] Resolving capability: bootstrap.modules"

        $workspacePath = $UseCaseContext.InputParameters['WorkspacePath']
        if ([string]::IsNullOrEmpty($workspacePath)) {
            $workspacePath = (Get-Location).Path
        }

        # Módulos Kernel requeridos
        $requiredModules = @(
            'motor/kernel/Kernel.ps1',
            'motor/registro/ModuleRegistry.ps1',
            'motor/dependencias/DependencyInjection.ps1',
            'motor/runtime/Runtime.ps1',
            'motor/eventos/EventBus.ps1',
            'motor/config/Configuration.psm1',
            'motor/plugins/PluginManager.ps1'
        )

        $moduleStatus = [System.Collections.ArrayList]@()
        $allFound = $true

        foreach ($modulePath in $requiredModules) {
            $fullPath = Join-Path -Path $workspacePath -ChildPath $modulePath
            $exists = Test-Path -Path $fullPath -PathType Leaf
            if (-not $exists) {
                $allFound = $false
            }
            $null = $moduleStatus.Add([pscustomobject]@{
                Module   = $modulePath
                Exists   = $exists
                FullPath = $fullPath
            })
        }

        return [pscustomobject][ordered]@{
            Capability = 'bootstrap.modules'
            Status     = 'Completed'
            Output     = @{
                WorkspacePath      = $workspacePath
                ModulesChecked     = @($moduleStatus)
                AllModulesFound    = $allFound
                RequiredModuleCount = $requiredModules.Count
            }
        }
    }
}

<#
.SYNOPSIS
    Crea un scriptblock resolver para la capacidad "bootstrap.configuration".
.DESCRIPTION
    Verifica la configuración del sistema (hermes.config.json, bootstrap.json, etc.).
.PARAMETER UseCaseContext
    El contexto del Use Case con los parámetros de entrada.
.PARAMETER Container
    El contenedor de dependencias del sistema.
#>
function New-BootstrapConfigurationResolver {
    [CmdletBinding()]
    param()

    return {
        param(
            [Parameter(Mandatory = $true)]
            [ValidateNotNull()]
            [psobject]$UseCaseContext,

            [Parameter(Mandatory = $true)]
            [ValidateNotNull()]
            [psobject]$Container
        )

        Write-Verbose "[BootstrapConfiguration] Resolving capability: bootstrap.configuration"

        $workspacePath = $UseCaseContext.InputParameters['WorkspacePath']
        if ([string]::IsNullOrEmpty($workspacePath)) {
            $workspacePath = (Get-Location).Path
        }

        $configFiles = @(
            'Hermes.config.json',
            'bootstrap.json',
            'bootstrap.yaml'
        )

        $configStatus = [System.Collections.ArrayList]@()
        $allFound = $true

        foreach ($configFile in $configFiles) {
            $fullPath = Join-Path -Path $workspacePath -ChildPath $configFile
            $exists = Test-Path -Path $fullPath -PathType Leaf
            if (-not $exists) {
                $allFound = $false
            }
            $null = $configStatus.Add([pscustomobject]@{
                ConfigFile = $configFile
                Exists     = $exists
                FullPath   = $fullPath
            })
        }

        # Intentar cargar configuración desde el contenedor
        $configManager = Resolve-HermesEnterpriseService -ContenedorDependencias $Container -NombreServicio "ConfigurationManager"
        $configLoaded = $null -ne $configManager

        return [pscustomobject][ordered]@{
            Capability = 'bootstrap.configuration'
            Status     = 'Completed'
            Output     = @{
                WorkspacePath           = $workspacePath
                ConfigFilesChecked      = @($configStatus)
                AllConfigFilesFound     = $allFound
                ConfigurationManagerLoaded = $configLoaded
            }
        }
    }
}

<#
.SYNOPSIS
    Registra todas las capacidades de BootstrapConfiguration en el CapabilityRegistry.
#>
function Register-BootstrapConfigurationCapabilities {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$CapabilityRegistry
    )

    $envResolver = New-BootstrapEnvironmentResolver
    $modResolver = New-BootstrapModulesResolver
    $cfgResolver = New-BootstrapConfigurationResolver

    $null = Register-Capability -CapabilityRegistry $CapabilityRegistry `
                                -CapabilityName 'bootstrap.environment' `
                                -EngineResolver $envResolver

    $null = Register-Capability -CapabilityRegistry $CapabilityRegistry `
                                -CapabilityName 'bootstrap.modules' `
                                -EngineResolver $modResolver

    $null = Register-Capability -CapabilityRegistry $CapabilityRegistry `
                                -CapabilityName 'bootstrap.configuration' `
                                -EngineResolver $cfgResolver

    return @('bootstrap.environment', 'bootstrap.modules', 'bootstrap.configuration')
}

Export-ModuleMember -Function New-BootstrapEnvironmentResolver, New-BootstrapModulesResolver, New-BootstrapConfigurationResolver, Register-BootstrapConfigurationCapabilities