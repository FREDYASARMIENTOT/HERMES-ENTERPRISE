# Hermes Project Factory — Unified Module
# Dot-sources all individual module files

$moduleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load all module files
Get-ChildItem "$moduleRoot/*.ps1" | ForEach-Object {
    . $_.FullName
}

# ─── Wrappers de compatibilidad (nombres antiguos → nuevos) ───

# Workspace
function Initialize-ProyectoWorkspace { Inicializar-EspacioProyecto @args }
function New-ProyectoWorkspaceFile { Crear-ArchivoEspacioTrabajo @args }

# SQLite
function Initialize-ProyectoDatabase { Inicializar-BaseDatosProyecto @args }
function Set-ProyectoInfo { Establecer-InformacionProyecto @args }
function Register-TimelineEvent { Registrar-EventoLineaTiempo @args }
function Get-ProyectoInfo { Obtener-InformacionProyecto @args }

# Git
function Initialize-ProyectoGit { Inicializar-GitProyecto @args }
function New-ProyectoGitCommit { Crear-CommitProyecto @args }
function Get-ProyectoGitStatus { Obtener-EstadoGitProyecto @args }

# GitHub
function Initialize-ProyectoGitHubRepo { Crear-RepositorioGitHubProyecto @args }
function Push-ProyectoToGitHub { Publicar-ProyectoEnGitHub @args }

# Azure
function Read-AzureConfiguration { Leer-ConfiguracionAzure @args }
function Validate-AzureInfrastructure { Validar-InfraestructuraAzure @args }
function New-ProyectoWebApp { New-ProyectoWebApp @args }
function Deploy-ProyectoZipToAzure { Deploy-ProyectoZipToAzure @args }
function Wait-ProyectoWebAppReady { Wait-ProyectoWebAppReady @args }
function Get-AzureIdentityMode { Obtener-ModoIdentidadAzure @args }
function Assert-AzureIdentityReady { Afirmar-IdentidadAzureLista @args }

# Packaging
function New-ProyectoDeployZip { Crear-ZipDespliegue @args }
function Test-DeployZipIntegrity { Validar-IntegridadZipDespliegue @args }

# Guardian
function Test-GuardianRestrictions { Probar-RestriccionesGuardian @args }
function Assert-ProyectoSafeToProceed { Afirmar-ProyectoSeguroParaContinuar @args }
function Get-GuardianSummary { Obtener-ResumenGuardian @args }

# SmokeTests
function Invoke-ProyectoSmokeTests { Ejecutar-PruebasHumoProyecto @args }
function Test-ProyectoLanding { Probar-PaginaInicioProyecto @args }

# Reporting
function New-ProyectoReportMD { New-ProyectoReportMD @args }
function New-ProyectoReportJSON { New-ProyectoReportJSON @args }
function New-ProyectoReportHTML { New-ProyectoReportHTML @args }
function New-BlankMetadata { Nuevo-MetadatosVacios @args }

# RenderEngine
function Invoke-RenderTemplate { Ejecutar-RenderizarPlantilla @args }
function Invoke-RenderTemplateFromString { Ejecutar-RenderizarPlantillaDesdeCadena @args }
function Get-TemplatePath { Obtener-RutaPlantilla @args }
function Copy-TemplateDirectory { Copiar-DirectorioPlantillas @args }
function New-ProyectoLanding { Crear-PaginaInicioProyecto @args }

# ─── Nuevas funciones exportadas ───
Export-ModuleMember -Function @(
    # Workspace
    'Inicializar-EspacioProyecto',
    'Crear-ArchivoEspacioTrabajo',
    # Wrappers compatibilidad Workspace
    'Initialize-ProyectoWorkspace',
    'New-ProyectoWorkspaceFile',
    # SQLite
    'Inicializar-BaseDatosProyecto',
    'Registrar-EventoProyecto',
    'Registrar-EventoLineaTiempo',
    'Establecer-InformacionProyecto',
    'Obtener-InformacionProyecto',
    'Registrar-ResultadoPruebaHumo',
    'Probar-ConexionSQLite',
    'Escapar-CadenaSQL',
    # Wrappers compatibilidad SQLite
    'Initialize-ProyectoDatabase',
    'Set-ProyectoInfo',
    'Register-TimelineEvent',
    'Get-ProyectoInfo',
    # Git
    'Inicializar-GitProyecto',
    'Crear-CommitProyecto',
    'Obtener-EstadoGitProyecto',
    # Wrappers compatibilidad Git
    'Initialize-ProyectoGit',
    'New-ProyectoGitCommit',
    'Get-ProyectoGitStatus',
    # GitHub
    'Crear-RepositorioGitHubProyecto',
    'Publicar-ProyectoEnGitHub',
    'Establecer-SecretosGitHubAcciones',
    # Wrappers compatibilidad GitHub
    'Initialize-ProyectoGitHubRepo',
    'Push-ProyectoToGitHub',
    # Azure
    'Leer-ConfiguracionAzure',
    'Validar-InfraestructuraAzure',
    'New-ProyectoWebApp',
    'Deploy-ProyectoZipToAzure',
    'Wait-ProyectoWebAppReady',
    'Obtener-ModoIdentidadAzure',
    'Afirmar-IdentidadAzureLista',
    # Wrappers compatibilidad Azure
    'Read-AzureConfiguration',
    'Validate-AzureInfrastructure',
    'Get-AzureIdentityMode',
    'Assert-AzureIdentityReady',
    # Packaging
    'Crear-ZipDespliegue',
    'Validar-IntegridadZipDespliegue',
    # Wrappers compatibilidad Packaging
    'New-ProyectoDeployZip',
    'Test-DeployZipIntegrity',
    # Guardian
    'Probar-RestriccionesGuardian',
    'Afirmar-ProyectoSeguroParaContinuar',
    'Obtener-ResumenGuardian',
    # Wrappers compatibilidad Guardian
    'Test-GuardianRestrictions',
    'Assert-ProyectoSafeToProceed',
    'Get-GuardianSummary',
    # SmokeTests
    'Ejecutar-PruebasHumoProyecto',
    'Probar-PaginaInicioProyecto',
    # Wrappers compatibilidad SmokeTests
    'Invoke-ProyectoSmokeTests',
    'Test-ProyectoLanding',
    # Reporting
    'New-ProyectoReportMD',
    'New-ProyectoReportJSON',
    'New-ProyectoReportHTML',
    'Nuevo-MetadatosVacios',
    # Wrappers compatibilidad Reporting
    'New-BlankMetadata',
    # RenderEngine
    'Ejecutar-RenderizarPlantilla',
    'Ejecutar-RenderizarPlantillaDesdeCadena',
    'Obtener-RutaPlantilla',
    'Copiar-DirectorioPlantillas',
    'Crear-PaginaInicioProyecto',
    # Wrappers compatibilidad RenderEngine
    'Invoke-RenderTemplate',
    'Invoke-RenderTemplateFromString',
    'Get-TemplatePath',
    'Copy-TemplateDirectory',
    'New-ProyectoLanding',
    # Registro Implementacion
    'Iniciar-RegistroImplementacion',
    'Iniciar-PasoImplementacion',
    'Finalizar-PasoImplementacion',
    'Iniciar-SubpasoImplementacion',
    'Finalizar-SubpasoImplementacion',
    'Finalizar-RegistroImplementacion',
    'Persistir-RegistroImplementacion'
)