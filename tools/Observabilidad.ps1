function Escribir-ProgresoHermes {
    param(
        [string]$Evento,
        [string]$Paso,
        [string]$Detalle = ''
    )
    $timestamp = (Get-Date).ToString('o')
    $entry = "{0} | {1} | {2} | {3}" -f $timestamp, $Evento, $Paso, $Detalle
    $logPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'hermes.log'
    Add-Content -Path $logPath -Value $entry
    # Actualizar EstadoEjecucion.json
    $statusPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'reports/EstadoEjecucion.json'
    if (-not (Test-Path (Split-Path $statusPath))) { New-Item -ItemType Directory -Path (Split-Path $statusPath) -Force | Out-Null }
    $status = @{
        timestamp = $timestamp;
        paso = $Paso;
        evento = $Evento;
        detalle = $Detalle
    }
    $status | ConvertTo-Json | Out-File -FilePath $statusPath -Encoding utf8
}

function Start-EventBus {
    param()
    Write-Host "[INFO] EventBus iniciado"
}
