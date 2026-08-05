<#
.SYNOPSIS
    Muestra la versión del sistema Hermes.
.DESCRIPTION
    Obtiene la versión actual del módulo Hermes.Commands y componentes asociados.
    Función canónica (RC63).
.PARAMETER Detailed
    Muestra información detallada de versiones de todos los componentes.
.EXAMPLE
    Get-HermesVersion
.EXAMPLE
    Get-HermesVersion -Detailed
#>
function Get-HermesVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    $moduleInfo = Get-Module Hermes.Commands
    $version = if ($moduleInfo) { $moduleInfo.Version.ToString() } else { '63.0.0' }

    if ($Detailed) {
        return [pscustomobject]@{
            HermesCommands        = $version
            PowerShellVersion     = $PSVersionTable.PSVersion.ToString()
            ArchitectureAnalyzer  = '1.0.0'
            Bootstrap             = '1.0.0'
            ProjectManager        = '1.0.0'
            Release               = 'RC63'
            BuildDate             = (Get-Date -Format 'yyyy-MM-dd')
        }
    }

    return [pscustomobject]@{
        Version = $version
        Release = 'RC63'
    }
}