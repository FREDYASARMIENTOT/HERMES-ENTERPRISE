<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Logger.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Proporciona logging estructurado JSONL para el Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseLogger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RutaArchivoLog,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreComponente = "Kernel"
    )

    # Crear el directorio de logs de forma idempotente antes de registrar eventos.
    $RutaDirectorioLog = Split-Path -Parent $RutaArchivoLog
    if (-not (Test-Path $RutaDirectorioLog)) {
        New-Item -ItemType Directory -Path $RutaDirectorioLog | Out-Null
    }

    return [pscustomobject][ordered]@{
        NombreComponente = $NombreComponente
        RutaArchivoLog   = $RutaArchivoLog
        Formato          = "JSONL"
    }
}

function Write-HermesEnterpriseLogEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$LoggerKernel,

        [Parameter(Mandatory = $true)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Nivel,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Mensaje,

        [Parameter(Mandatory = $false)]
        [hashtable]$DatosEvento = @{},

        [Parameter(Mandatory = $false)]
        [string]$CorrelationId = ""
    )

    if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
        $CorrelationId = [guid]::NewGuid().ToString()
    }

    # Construir evento estructurado; profundidad 10 permite registrar datos anidados simples.
    $EventoLog = [ordered]@{
        Timestamp       = (Get-Date).ToString("o")
        Componente      = $LoggerKernel.NombreComponente
        Nivel           = $Nivel
        Mensaje         = $Mensaje
        CorrelationId   = $CorrelationId
        Datos           = $DatosEvento
    }

    $LineaJson = $EventoLog | ConvertTo-Json -Depth 10 -Compress
    Add-Content -Path $LoggerKernel.RutaArchivoLog -Value $LineaJson -Encoding UTF8
    return [pscustomobject]$EventoLog
}
