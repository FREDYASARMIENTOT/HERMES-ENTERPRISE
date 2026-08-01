<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : UseCaseRegistry.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Registro Central de Use Cases — auto-registro de los 9 casos de uso core.
    Expone funciones para registrar, resolver y listar todos los use cases.
====================================================================================================
#>

Set-StrictMode -Version Latest

$script:UseCaseRegistry = @{}

function Register-UseCase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCase
    )

    if (-not (Test-UseCaseContractValid $UseCase)) {
        throw "UseCase '$($UseCase.Name)' does not satisfy IUseCase contract"
    }

    if ([string]::IsNullOrEmpty($UseCase.Id)) {
        $id = $UseCase.Name
    } else {
        $id = $UseCase.Id
    }
    $script:UseCaseRegistry[$id] = $UseCase
}

function Resolve-UseCase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UseCaseIdOrName
    )

    if ($script:UseCaseRegistry.ContainsKey($UseCaseIdOrName)) {
        return $script:UseCaseRegistry[$UseCaseIdOrName]
    }

    foreach ($key in $script:UseCaseRegistry.Keys) {
        $uc = $script:UseCaseRegistry[$key]
        if ($uc.Name -eq $UseCaseIdOrName -or $uc.Id -eq $UseCaseIdOrName) {
            return $uc
        }
    }

    return $null
}

function Get-AllUseCases {
    [CmdletBinding()]
    param()

    return $script:UseCaseRegistry.Values
}

function Clear-UseCaseRegistry {
    [CmdletBinding()]
    param()

    $script:UseCaseRegistry.Clear()
}

function Test-UseCaseContractValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$UseCase
    )

    return $UseCase.PSObject.Properties.Name -contains 'Id' -and
           $UseCase.PSObject.Properties.Name -contains 'Name' -and
           $UseCase.PSObject.Properties.Name -contains 'Capability' -and
           $UseCase.PSObject.Properties.Name -contains 'EngineType' -and
           $UseCase.PSObject.Properties.Name -contains 'ProviderType' -and
           $UseCase.PSObject.Properties.Name -contains 'Status'
}

# Auto-register all 9 use cases from UseCaseLibrary
function Initialize-UseCaseRegistry {
    [CmdletBinding()]
    param()

    $useCases = @(
        (New-BootstrapUseCase -Id "uc-bootstrap" -Name "BootstrapUseCase"),
        (New-WorkspaceDiscoveryUseCase -Id "uc-workspace-discovery" -Name "WorkspaceDiscoveryUseCase"),
        (New-CapabilityDiscoveryUseCase -Id "uc-capability-discovery" -Name "CapabilityDiscoveryUseCase"),
        (New-ConfigurationLoadUseCase -Id "uc-config-load" -Name "ConfigurationLoadUseCase"),
        (New-ConfigurationValidateUseCase -Id "uc-config-validate" -Name "ConfigurationValidateUseCase"),
        (New-DependencyResolveUseCase -Id "uc-dependency-resolve" -Name "DependencyResolveUseCase"),
        (New-ProviderResolveUseCase -Id "uc-provider-resolve" -Name "ProviderResolveUseCase"),
        (New-RuntimeStartupUseCase -Id "uc-runtime-startup" -Name "RuntimeStartupUseCase"),
        (New-KernelStartupUseCase -Id "uc-kernel-startup" -Name "KernelStartupUseCase")
    )

    foreach ($uc in $useCases) {
        Register-UseCase -UseCase $uc
    }

    return $useCases.Count
}

# Note: Export-ModuleMember omitted because this file is dot-sourced,
# not imported as a module. All functions are available in the calling scope.
