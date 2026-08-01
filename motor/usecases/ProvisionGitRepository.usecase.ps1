<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ProvisionGitRepository.usecase.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Use Case: ProvisionGitRepository
    Provee la capacidad de provisionar un repositorio Git remoto (GitHub) con configuración inicial.
    Capacidades requeridas:
        - "provision.git.repository"
        - "provision.github.repository"
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Crea un scriptblock resolver para la capacidad "provision.git.repository".
.DESCRIPTION
    Este resolver será invocado por el PipelineOrchestrator cuando un UseCase requiera
    la capacidad de provisionar un repositorio Git.
.PARAMETER UseCaseContext
    El contexto del Use Case (UseCaseContext) con los parámetros de entrada.
.PARAMETER Container
    El contenedor de dependencias del sistema.
#>
function New-GitRepositoryProvisionResolver {
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

        Write-Verbose "[ProvisionGitRepository] Resolving capability: provision.git.repository"

        $repoName = $UseCaseContext.InputParameters['RepositoryName']
        $repoPath = $UseCaseContext.InputParameters['RepositoryPath']
        $remoteUrl = $UseCaseContext.InputParameters['RemoteUrl']

        if ([string]::IsNullOrEmpty($repoName)) {
            throw "ProvisionGitRepository: RepositoryName is required in InputParameters"
        }

        # Resolver provedor Git desde el contenedor
        $gitProvider = Resolve-HermesEnterpriseService -ContenedorDependencias $Container -NombreServicio "Provider.GitProvider"
        if ($null -eq $gitProvider) {
            throw "ProvisionGitRepository: GitProvider not found in dependency container"
        }

        # Configurar repositorio
        $initResult = Initialize-GitRepository -Nombre $repoName -Ruta $repoPath -OrigenRemoto $remoteUrl

        return [pscustomobject][ordered]@{
            Capability = 'provision.git.repository'
            Status     = 'Completed'
            Output     = @{
                RepositoryName = $repoName
                RepositoryPath = $repoPath
                Initialized    = $true
                RemoteUrl      = $remoteUrl
                Commits        = $initResult
            }
        }
    }
}

<#
.SYNOPSIS
    Crea un scriptblock resolver para la capacidad "provision.github.repository".
.DESCRIPTION
    Este resolver crea un repositorio en GitHub vía API GraphQL / REST.
.PARAMETER UseCaseContext
    El contexto del Use Case con los parámetros de entrada.
.PARAMETER Container
    El contenedor de dependencias del sistema.
#>
function New-GitHubRepositoryProvisionResolver {
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

        Write-Verbose "[ProvisionGitRepository] Resolving capability: provision.github.repository"

        $repoName = $UseCaseContext.InputParameters['RepositoryName']
        $description = $UseCaseContext.InputParameters['Description']
        $visibility = $UseCaseContext.InputParameters['Visibility']
        $organization = $UseCaseContext.InputParameters['Organization']

        if ([string]::IsNullOrEmpty($repoName)) {
            throw "ProvisionGitRepository: RepositoryName is required for GitHub provision"
        }

        if ([string]::IsNullOrEmpty($visibility)) {
            $visibility = 'private'
        }

        # Resolver GitHub provisioner desde el contenedor
        $githubProvisioner = Resolve-HermesEnterpriseService -ContenedorDependencias $Container -NombreServicio "Provider.GitHubProvisioner"
        if ($null -eq $githubProvisioner) {
            throw "ProvisionGitRepository: GitHubProvisioner not found in dependency container"
        }

        # Crear repositorio en GitHub
        $createResult = New-GitHubRepository -Nombre $repoName `
                                             -Descripcion $description `
                                             -Visibilidad $visibility `
                                             -Organizacion $organization

        return [pscustomobject][ordered]@{
            Capability = 'provision.github.repository'
            Status     = 'Completed'
            Output     = @{
                RepositoryName = $repoName
                RemoteUrl      = $createResult.CloneUrl
                HtmlUrl        = $createResult.HtmlUrl
                Organization   = $organization
                Visibility     = $visibility
            }
        }
    }
}

<#
.SYNOPSIS
    Obtiene los resolvers registrados para ambas capacidades de provisionamiento.
.DESCRIPTION
    Helper para registrar todas las capacidades de este Use Case en un solo paso.
#>
function Register-ProvisionGitRepositoryCapabilities {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$CapabilityRegistry
    )

    $gitResolver = New-GitRepositoryProvisionResolver
    $githubResolver = New-GitHubRepositoryProvisionResolver

    $null = Register-Capability -CapabilityRegistry $CapabilityRegistry `
                                -CapabilityName 'provision.git.repository' `
                                -EngineResolver $gitResolver

    $null = Register-Capability -CapabilityRegistry $CapabilityRegistry `
                                -CapabilityName 'provision.github.repository' `
                                -EngineResolver $githubResolver

    return @('provision.git.repository', 'provision.github.repository')
}

Export-ModuleMember -Function New-GitRepositoryProvisionResolver, New-GitHubRepositoryProvisionResolver, Register-ProvisionGitRepositoryCapabilities