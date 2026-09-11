function Probar-RestriccionesGuardian {
    <#
    .SYNOPSIS
        Valida que las restricciones del Guardian (protección de infraestructura) se cumplan.
        Este módulo lee las reglas de protección RC73 y las aplica.
    .PARAMETER ConfigPath
        Ruta a Hermes.InfrastructureProtection.json.
    .OUTPUTS
        Hashtable con el estado de validación del Guardian.
    #>
    param(
        [Parameter(Mandatory)] [string] $ConfigPath
    )

    Write-Host "[Guardian] Validando reglas de protección de infraestructura..."

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "[Guardian] ADVERTENCIA: Archivo de protección no encontrado en: $ConfigPath"
        return @{
            ConfigFound = $false
            RulesValidated = 0
            Allowed = $true
        }
    }

    $configuracion = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

    $operacionesBloqueadas = @()
    $operacionesPermitidas = @()

    if ($configuracion.PSObject.Properties.Name -contains "BlockedOperations") {
        $operacionesBloqueadas = $configuracion.BlockedOperations
    } elseif ($configuracion.PSObject.Properties.Name -contains "blockedOperations") {
        $operacionesBloqueadas = $configuracion.blockedOperations
    }

    if ($configuracion.PSObject.Properties.Name -contains "AllowedOperations") {
        $operacionesPermitidas = $configuracion.AllowedOperations
    } elseif ($configuracion.PSObject.Properties.Name -contains "allowedOperations") {
        $operacionesPermitidas = $configuracion.allowedOperations
    }

    $reglasProteccion = @{
        BlockedOperations = $operacionesBloqueadas
        AllowedOperations = $operacionesPermitidas
        ConfigVersion = if ($configuracion.PSObject.Properties.Name -contains "Version") { $configuracion.Version } else { $configuracion.version }
    }

    Write-Host "[Guardian] Reglas de protección cargadas: $($operacionesBloqueadas.Count) bloqueadas, $($operacionesPermitidas.Count) permitidas"

    return @{
        ConfigFound = $true
        RulesValidated = $operacionesBloqueadas.Count + $operacionesPermitidas.Count
        ProtectionRules = $reglasProteccion
        Allowed = $true
    }
}

function Afirmar-ProyectoSeguroParaContinuar {
    <#
    .SYNOPSIS
        Verifica que una operación está permitida por las reglas del Guardian.
    .PARAMETER Operation
        La operación a verificar (ej: "CreateWebApp", "CreateResourceGroup").
    .PARAMETER GuardianState
        El estado actual del Guardian desde Probar-RestriccionesGuardian.
    .OUTPUTS
        Booleano indicando si la operación está permitida.
    #>
    param(
        [Parameter(Mandatory)] [string] $Operation,
        [Parameter(Mandatory)] [hashtable] $GuardianState
    )

    if (-not $GuardianState.Allowed) {
        throw "[Guardian] El Guardian ha bloqueado todas las operaciones. No se puede continuar."
    }

    $bloqueadas = $GuardianState.ProtectionRules.BlockedOperations
    if ($Operation -in $bloqueadas) {
        throw "[Guardian] Operación BLOQUEADA por las reglas del Guardian: $Operation"
    }

    Write-Host "[Guardian] Operación permitida: $Operation"
    return $true
}

function Obtener-ResumenGuardian {
    <#
    .SYNOPSIS
        Retorna un resumen del estado actual del Guardian.
    .PARAMETER GuardianState
        El estado actual del Guardian.
    .OUTPUTS
        Hashtable con el resumen.
    #>
    param(
        [Parameter(Mandatory)] [hashtable] $GuardianState
    )

    return @{
        Active = $GuardianState.Allowed
        ConfigFound = $GuardianState.ConfigFound
        RulesValidated = $GuardianState.RulesValidated
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
}

Export-ModuleMember -Function Probar-RestriccionesGuardian, Afirmar-ProyectoSeguroParaContinuar, Obtener-ResumenGuardian