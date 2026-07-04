<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : DependencyResolver.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Ordena plugins según dependencias declaradas en sus manifiestos.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Resolve-HermesEnterprisePluginLoadOrder {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][object[]]$PluginsDescubiertos)

    $PluginsPorNombre = @{}
    foreach ($Plugin in $PluginsDescubiertos) { $PluginsPorNombre[$Plugin.Manifest.Nombre] = $Plugin }

    $NombresVisitados = @{}
    $NombresEnProceso = @{}
    $PluginsOrdenados = New-Object System.Collections.Generic.List[object]

    function Visit-HermesEnterprisePluginDependencyNode {
        param([string]$NombrePlugin)

        if ($NombresVisitados.ContainsKey($NombrePlugin)) { return }
        if ($NombresEnProceso.ContainsKey($NombrePlugin)) { throw "Dependencia circular detectada en plugin: $NombrePlugin" }
        if (-not $PluginsPorNombre.ContainsKey($NombrePlugin)) { throw "Dependencia no encontrada: $NombrePlugin" }

        $NombresEnProceso[$NombrePlugin] = $true
        $PluginActual = $PluginsPorNombre[$NombrePlugin]
        $Dependencias = @($PluginActual.Manifest.Dependencias)

        foreach ($NombreDependencia in $Dependencias) {
            if (-not [string]::IsNullOrWhiteSpace($NombreDependencia)) {
                Visit-HermesEnterprisePluginDependencyNode -NombrePlugin $NombreDependencia
            }
        }

        $NombresEnProceso.Remove($NombrePlugin)
        $NombresVisitados[$NombrePlugin] = $true
        $PluginsOrdenados.Add($PluginActual)
    }

    foreach ($Plugin in $PluginsDescubiertos) {
        Visit-HermesEnterprisePluginDependencyNode -NombrePlugin $Plugin.Manifest.Nombre
    }

    return $PluginsOrdenados.ToArray()
}
