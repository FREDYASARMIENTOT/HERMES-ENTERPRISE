<#
.SYNOPSIS
    ContextHelpers - Cargador central de todos los helpers
.DESCRIPTION
    Carga automática de todos los archivos de helpers centralizados.
    Los builders DEBEN cargar este archivo al inicio.
#>

$HelpersPath = $PSScriptRoot

# Cargar todos los helpers en orden
. "$HelpersPath\GitHelpers.ps1"
. "$HelpersPath\TokenHelpers.ps1"
. "$HelpersPath\PathHelpers.ps1"
. "$HelpersPath\ParseHelpers.ps1"
. "$HelpersPath\DurationHelpers.ps1"
. "$HelpersPath\ProjectHelpers.ps1"

Write-Verbose "Helpers centralizados cargados desde: $HelpersPath"
