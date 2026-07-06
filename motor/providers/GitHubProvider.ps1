<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : GitHubProvider.ps1
Propósito:
    Provider GitHub en modo MOCK. Implementa el contrato Enterprise y expone operaciones de
    repositorios como stubs, sin llamadas REST, tokens ni CLI.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioGitHubProvider = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioGitHubProvider "ProviderAdapter.ps1")
. (Join-Path $RutaDirectorioGitHubProvider "ProviderCapabilityDescriptor.ps1")
. (Join-Path $RutaDirectorioGitHubProvider "ProviderConfigurationManager.ps1")
. (Join-Path $RutaDirectorioGitHubProvider "ProviderDiagnostics.ps1")

$SCRIPT:HermesEnterpriseGitHubProviderNombre = "GitHubProvider"
$SCRIPT:HermesEnterpriseGitHubProviderVersion = "0.5.0"

function New-HermesEnterpriseGitHubProvider {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$false)][psobject]$LoggerKernel=$null)
    $AdministradorConfiguracion = New-HermesEnterpriseProviderConfigurationManager
    Register-HermesEnterpriseProviderConfigurationSchema -AdministradorConfiguracionProviders $AdministradorConfiguracion -EsquemaConfiguracionProvider ([pscustomobject][ordered]@{ NombreProvider = $SCRIPT:HermesEnterpriseGitHubProviderNombre; VersionEsquema = $SCRIPT:HermesEnterpriseGitHubProviderVersion; ClavesRequeridas = @("UsuarioGitHub"); ClavesPermitidas = @("UsuarioGitHub", "Organizacion", "TimeoutSegundos"); ValoresPorDefecto = @{ TimeoutSegundos = 60 } }) | Out-Null
    $Adapter = New-HermesEnterpriseProviderAdapter -NombreProvider $SCRIPT:HermesEnterpriseGitHubProviderNombre -VersionProvider $SCRIPT:HermesEnterpriseGitHubProviderVersion
    $Adapter.LimitesIncluidos.ProviderReal = $false
    $Adapter.LimitesIncluidos.HTTP = $false
    $Adapter.LimitesIncluidos.CredencialesReales = $false
    return [pscustomobject][ordered]@{ NombreProvider = $SCRIPT:HermesEnterpriseGitHubProviderNombre; VersionProvider = $SCRIPT:HermesEnterpriseGitHubProviderVersion; Autor = "HERMES-ENTERPRISE"; Adapter = $Adapter; ConfigurationManager = $AdministradorConfiguracion; ConfiguracionProvider = @{}; Capabilities = (New-HermesEnterpriseProviderCapabilityDescriptor -NombreProvider $SCRIPT:HermesEnterpriseGitHubProviderNombre -VersionProvider $SCRIPT:HermesEnterpriseGitHubProviderVersion -CapacidadesSoportadas @("RepositoryManagement") -CapacidadesExperimentales @() -MetadatosCapacidades @{ Repositorios = $true; PullRequests = $false; Actions = $false }); Health = ([pscustomobject][ordered]@{ Estado = "Unknown"; Mensaje = "Health no evaluado."; UltimaVerificacion = $null }); HoraInicioInicializacion = $null; HoraFinInicializacion = $null; UltimaConfiguracion = $null; Logger = $LoggerKernel }
}

function ValidateConfiguration-GitHubProvider {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][psobject]$ContextoProvider)
    $ConfiguracionSolicitada = if ($null -eq $ContextoProvider.ConfiguracionProvider) { @{} } else { $ContextoProvider.ConfiguracionProvider }
    $ContextoProvider.UltimaConfiguracion = Resolve-HermesEnterpriseProviderConfiguration -AdministradorConfiguracionProviders $ContextoProvider.ConfigurationManager -NombreProvider $ContextoProvider.NombreProvider -ConfiguracionSolicitada $ConfiguracionSolicitada
    $Resultado = Test-HermesEnterpriseProviderConfiguration -AdministradorConfiguracionProviders $ContextoProvider.ConfigurationManager -NombreProvider $ContextoProvider.NombreProvider -ConfiguracionSolicitada $ContextoProvider.UltimaConfiguracion
    if ($Resultado.EsValida -and $ContextoProvider.Adapter.EstadoActual -eq "Created") { Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Configured" | Out-Null }
    if ($Resultado.EsValida -and $ContextoProvider.Adapter.EstadoActual -eq "Configured") { Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Validated" | Out-Null }
    return $Resultado
}

function Initialize-GitHubProvider {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][psobject]$ContextoProvider)
    $ContextoProvider.HoraInicioInicializacion = Get-Date
    Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Initialized" | Out-Null
    $ContextoProvider.HoraFinInicializacion = Get-Date
    return $ContextoProvider
}

function Connect-GitHubProvider {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][psobject]$ContextoProvider,[Parameter(Mandatory=$false)][hashtable]$ConfiguracionProvider = @{})
    if ($ConfiguracionProvider.Count -gt 0) { $ContextoProvider.ConfiguracionProvider = $ConfiguracionProvider }
    if ($ContextoProvider.ConfiguracionProvider.Count -eq 0) { $ContextoProvider.ConfiguracionProvider = @{ UsuarioGitHub = $env:GITHUB_USER } }
    ValidateConfiguration-GitHubProvider -ContextoProvider $ContextoProvider | Out-Null
    if ($ContextoProvider.Adapter.EstadoActual -eq "Validated") { Initialize-GitHubProvider -ContextoProvider $ContextoProvider | Out-Null }
    $ContextoProvider.Health = [pscustomobject][ordered]@{ Estado = "Healthy"; Mensaje = "GitHubProvider Healthy (modo simulado)."; UltimaVerificacion = (Get-Date).ToString("o") }
    Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Ready" | Out-Null
    return $ContextoProvider
}

function Disconnect-GitHubProvider {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][psobject]$ContextoProvider)
    Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Disposed" | Out-Null
    $ContextoProvider.Health = [pscustomobject][ordered]@{ Estado = "Disposed"; Mensaje = "GitHubProvider dispuesto."; UltimaVerificacion = (Get-Date).ToString("o") }
    return $ContextoProvider
}

function Get-GitHubProviderHealth {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][psobject]$ContextoProvider)
    return $ContextoProvider.Health
}

function GetProviderInformation-GitHubProvider {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][psobject]$ContextoProvider)
    return Get-GitHubProviderSummary -ContextoProvider $ContextoProvider
}

function Get-GitHubProviderSummary {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][psobject]$ContextoProvider)
    $Diagnostics = Invoke-HermesEnterpriseProviderDiagnostics -NombreProvider $ContextoProvider.NombreProvider -AdministradorConfiguracionProviders $ContextoProvider.ConfigurationManager -ConfiguracionProvider ($ContextoProvider.UltimaConfiguracion) -DescriptorCapacidadesProvider $ContextoProvider.Capabilities -CapacidadesRequeridas @("RepositoryManagement") -HealthProvider $ContextoProvider.Health
    return [pscustomobject][ordered]@{ NombreProvider = $ContextoProvider.NombreProvider; EstadoActual = $ContextoProvider.Adapter.EstadoActual; Modo = "Simulado"; DiagnosticsListoLocalmente = $Diagnostics.EsListoLocalmente; Capacidades = $ContextoProvider.Capabilities.CapacidadesSoportadas; LimitesIncluidos = [pscustomobject][ordered]@{ HTTP = $false; GitHubApi = $false; GitHubCLI = $false; CredencialesReales = $false; ProviderReal = $false } }
}

function Invoke-HermesEnterpriseGitHubRepositoryOperation {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][ValidateSet("CreateRepository","OpenRepository","CloneRepository","DeleteRepository","ArchiveRepository","ListRepositories","ForkRepository","RenameRepository")][string]$Operacion,[Parameter(Mandatory=$false)][string]$Nombre = "",[Parameter(Mandatory=$false)][string]$NuevoNombre = "",[Parameter(Mandatory=$false)][string]$Organizacion = "",[Parameter(Mandatory=$false)][string]$RutaLocal = "")
    return [pscustomobject][ordered]@{ Operacion = $Operacion; Nombre = $Nombre; NuevoNombre = $NuevoNombre; Organizacion = $Organizacion; RutaLocal = $RutaLocal; Estado = "MOCK-$Operacion" }
}

function New-HermesEnterpriseGitHubRepository { [CmdletBinding()]param([Parameter(Mandatory=$true)][string]$Nombre) Invoke-HermesEnterpriseGitHubRepositoryOperation -Operacion CreateRepository -Nombre $Nombre }
function Open-HermesEnterpriseGitHubRepository { [CmdletBinding()]param([Parameter(Mandatory=$true)][string]$Nombre) Invoke-HermesEnterpriseGitHubRepositoryOperation -Operacion OpenRepository -Nombre $Nombre }
function Clone-HermesEnterpriseGitHubRepository { [CmdletBinding()]param([Parameter(Mandatory=$true)][string]$Nombre,[Parameter(Mandatory=$true)][string]$RutaLocal) Invoke-HermesEnterpriseGitHubRepositoryOperation -Operacion CloneRepository -Nombre $Nombre -RutaLocal $RutaLocal }
function Remove-HermesEnterpriseGitHubRepository { [CmdletBinding()]param([Parameter(Mandatory=$true)][string]$Nombre) Invoke-HermesEnterpriseGitHubRepositoryOperation -Operacion DeleteRepository -Nombre $Nombre }
function Archive-HermesEnterpriseGitHubRepository { [CmdletBinding()]param([Parameter(Mandatory=$true)][string]$Nombre) Invoke-HermesEnterpriseGitHubRepositoryOperation -Operacion ArchiveRepository -Nombre $Nombre }
function Get-HermesEnterpriseGitHubRepositoryList { [CmdletBinding()]param() Invoke-HermesEnterpriseGitHubRepositoryOperation -Operacion ListRepositories }
function Fork-HermesEnterpriseGitHubRepository { [CmdletBinding()]param([Parameter(Mandatory=$true)][string]$Nombre,[Parameter(Mandatory=$true)][string]$Organizacion) Invoke-HermesEnterpriseGitHubRepositoryOperation -Operacion ForkRepository -Nombre $Nombre -Organizacion $Organizacion }
function Rename-HermesEnterpriseGitHubRepository { [CmdletBinding()]param([Parameter(Mandatory=$true)][string]$Nombre,[Parameter(Mandatory=$true)][string]$NuevoNombre) Invoke-HermesEnterpriseGitHubRepositoryOperation -Operacion RenameRepository -Nombre $Nombre -NuevoNombre $NuevoNombre }
