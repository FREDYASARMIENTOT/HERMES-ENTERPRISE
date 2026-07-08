<#
.SYNOPSIS
    TokenHelpers - Funciones auxiliares de estimación de tokens
.DESCRIPTION
    Contiene TODAS las funciones relacionadas con conteo de tokens.
    Este archivo debe cargarse ANTES que cualquier builder.
#>

function Estimate-Tokens {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    if ([string]::IsNullOrWhiteSpace($Content)) {
        return 0
    }
    
    # Estimación simple: 4 caracteres ~ 1 token
    # Basado en promedio de palabras de 4-5 caracteres + espacios
    return [math]::Ceiling($Content.Length / 4)
}
