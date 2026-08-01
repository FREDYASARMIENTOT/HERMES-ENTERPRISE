<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : CapabilityRegistrar.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Registro de Capacidades — auto-poblar el CapabilityRegistry con las 9+ capabilities core.
    Mapea Capability → Engine → Provider → UseCase para el sistema.
====================================================================================================
#>

Set-StrictMode -Version Latest

$script:CapabilityRegistry = @{}

function Register-Capability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CapabilityId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$Mapping
    )

    $script:CapabilityRegistry[$CapabilityId] = $Mapping
}

function Resolve-CapabilityMapping {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CapabilityId
    )

    if ($script:CapabilityRegistry.ContainsKey($CapabilityId)) {
        return $script:CapabilityRegistry[$CapabilityId]
    }
    return $null
}

function Get-AllCapabilityMappings {
    [CmdletBinding()]
    param()

    return $script:CapabilityRegistry
}

function Initialize-CapabilityRegistrar {
    [CmdletBinding()]
    param()

    # 9 core capabilities mapped to Engine→Provider
    $capabilities = @{
        'capability.workspace.bootstrap' = @{
            Engine    = 'BootstrapEngine'
            Provider  = 'GitHubProvider'
            UseCaseId = 'uc-bootstrap'
        }
        'capability.workspace.discovery' = @{
            Engine    = 'DiscoveryEngine'
            Provider  = 'FileSystemProvider'
            UseCaseId = 'uc-workspace-discovery'
        }
        'capability.capability.discovery' = @{
            Engine    = 'DiscoveryEngine'
            Provider  = 'CapabilityProvider'
            UseCaseId = 'uc-capability-discovery'
        }
        'capability.configuration.load' = @{
            Engine    = 'ConfigEngine'
            Provider  = 'ConfigurationProvider'
            UseCaseId = 'uc-config-load'
        }
        'capability.configuration.validate' = @{
            Engine    = 'ConfigEngine'
            Provider  = 'ConfigurationProvider'
            UseCaseId = 'uc-config-validate'
        }
        'capability.dependency.resolve' = @{
            Engine    = 'DependencyEngine'
            Provider  = 'DependencyProvider'
            UseCaseId = 'uc-dependency-resolve'
        }
        'capability.provider.resolve' = @{
            Engine    = 'ProviderEngine'
            Provider  = 'WorkspaceProvider'
            UseCaseId = 'uc-provider-resolve'
        }
        'capability.runtime.startup' = @{
            Engine    = 'RuntimeEngine'
            Provider  = 'RuntimeProvider'
            UseCaseId = 'uc-runtime-startup'
        }
        'capability.kernel.startup' = @{
            Engine    = 'KernelEngine'
            Provider  = 'RuntimeProvider'
            UseCaseId = 'uc-kernel-startup'
        }
    }

    foreach ($kvp in $capabilities.GetEnumerator()) {
        Register-Capability -CapabilityId $kvp.Key -Mapping ([pscustomobject]$kvp.Value)
    }

    return $capabilities.Count
}

