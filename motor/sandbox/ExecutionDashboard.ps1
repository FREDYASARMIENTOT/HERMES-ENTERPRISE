<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ExecutionDashboard.ps1
Propósito:
    Muestra dashboard en consola con progreso, estado, tiempo transcurrido y errores.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Show-HermesEnterpriseExecutionDashboard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$RutaSandbox,
        [Parameter(Mandatory = $false)][string]$Escenario = "",
        [Parameter(Mandatory = $false)][string]$Estado = "Unknown",
        [Parameter(Mandatory = $false)][int]$Porcentaje = 0,
        [Parameter(Mandatory = $false)][int]$TiempoTranscurridoSegundos = 0,
        [Parameter(Mandatory = $false)][string]$PasoActual = "",
        [Parameter(Mandatory = $false)][array]$Errores = @(),
        [Parameter(Mandatory = $false)][array]$Warnings = @(),
        [Parameter(Mandatory = $false)][switch]$Quiet
    )

    $BarraLongitud = 30
    $Completados = [math]::Floor(($Porcentaje / 100) * $BarraLongitud)
    $Restantes = $BarraLongitud - $Completados
    $Barra = "[" + ("#" * $Completados) + ("-" * $Restantes) + "]"

    $Minutos = [int][math]::Floor($TiempoTranscurridoSegundos / 60)
    $Segundos = [int]($TiempoTranscurridoSegundos % 60)
    $TiempoFormateado = "$($Minutos.ToString('D2')):$($Segundos.ToString('D2'))"

    $OutputLines = [System.Collections.ArrayList]::new()
    $OutputLines.Add("====================================================================================================") | Out-Null
    $OutputLines.Add("  HERMES ENTERPRISE - EXECUTION DASHBOARD") | Out-Null
    $OutputLines.Add("====================================================================================================") | Out-Null
    $OutputLines.Add("") | Out-Null
    $OutputLines.Add("Sandbox:        $RutaSandbox") | Out-Null

    if (-not [string]::IsNullOrWhiteSpace($Escenario)) {
        $OutputLines.Add("Escenario:      $Escenario") | Out-Null
    }

    $OutputLines.Add("Estado:         $Estado") | Out-Null
    $OutputLines.Add("Tiempo:         $TiempoFormateado") | Out-Null
    $OutputLines.Add("") | Out-Null
    $OutputLines.Add("Progreso:       $Barra $Porcentaje%") | Out-Null

    if (-not [string]::IsNullOrWhiteSpace($PasoActual)) {
        $OutputLines.Add("Paso actual:    $PasoActual") | Out-Null
    }

    if ($Warnings.Count -gt 0) {
        $OutputLines.Add("") | Out-Null
        $OutputLines.Add("Warnings ($($Warnings.Count)):") | Out-Null
        foreach ($W in $Warnings | Select-Object -First 5) { $OutputLines.Add("  - $W") | Out-Null }
    }

    if ($Errores.Count -gt 0) {
        $OutputLines.Add("") | Out-Null
        $OutputLines.Add("Errores ($($Errores.Count)):") | Out-Null
        foreach ($E in $Errores | Select-Object -First 5) { $OutputLines.Add("  - $E") | Out-Null }
    }

    $OutputLines.Add("") | Out-Null
    $OutputLines.Add("====================================================================================================") | Out-Null

    $OutputText = $OutputLines -join "`n"

    if (-not $Quiet) {
        try { Clear-Host } catch {}
        foreach ($Linea in $OutputLines) {
            Write-Host $Linea
        }
    }

    return $OutputText
}

function Show-HermesEnterpriseExecutionProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][int]$Porcentaje,
        [Parameter(Mandatory = $false)][string]$Mensaje = "",
        [Parameter(Mandatory = $false)][switch]$Quiet
    )

    $BarraLongitud = 40
    $Completados = [math]::Floor(($Porcentaje / 100) * $BarraLongitud)
    $Restantes = $BarraLongitud - $Completados

    $Barra = "[" + ("#" * $Completados) + ("-" * $Restantes) + "]"
    $Linea = "$Barra $Porcentaje%"

    if (-not [string]::IsNullOrWhiteSpace($Mensaje)) {
        $Linea += " - $Mensaje"
    }

    if (-not $Quiet) {
        Write-Host $Linea
    }

    return $Linea
}
