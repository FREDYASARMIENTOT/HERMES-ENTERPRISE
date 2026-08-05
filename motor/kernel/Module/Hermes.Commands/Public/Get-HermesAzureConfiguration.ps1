<#
.SYNOPSIS
    Obtiene la configuración canónica de infraestructura Azure compartida.
.DESCRIPTION
    Lee Hermes.Azure.json y retorna un objeto con todos los parámetros
    de infraestructura Azure compartida.

    Hermes NO descubre recursos Azure. Únicamente lee configuración.
.PARAMETER Path
    Ruta opcional al archivo Hermes.Azure.json. Si no se especifica,
    se lee desde <ProjectRoot>/config/Hermes.Azure.json.
.EXAMPLE
    Get-HermesAzureConfiguration
.EXAMPLE
    Get-HermesAzureConfiguration -Path "C:\config\Hermes.Azure.json"
.OUTPUTS
    PSCustomObject
.NOTES
    Definida en Private/AzureConfiguration.ps1
#>
# La implementación real está en Private/AzureConfiguration.ps1
# Este archivo existe para que el módulo exporte la función automáticamente.