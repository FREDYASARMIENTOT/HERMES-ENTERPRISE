<#
.SYNOPSIS
    PathHelpers - Funciones auxiliares de rutas
.DESCRIPTION
    Contiene TODAS las funciones relacionadas con manipulación de rutas.
    Este archivo debe cargarse ANTES que cualquier builder.
#>

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullPath,
        
        [Parameter(Mandatory = $true)]
        [string]$BasePath
    )
    
    try {
        $relative = [System.IO.Path]::GetRelativePath($BasePath, $FullPath)
        return $relative
    } catch {
        return $FullPath
    }
}

function Normalize-Path {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    return $Path -replace '\\', '\'
}
