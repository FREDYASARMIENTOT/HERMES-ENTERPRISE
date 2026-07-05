<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : AzureFoundryTelemetry.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Telemetría del Azure Foundry Provider: CorrelationId, métricas de latencia/tokens/costo,
    logging seguro y sanitización de secretos. No registra nunca credenciales ni tokens.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioAzureFoundryTelemetry = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioAzureFoundryTelemetry "..\logging\Logger.ps1")

$SCRIPT:HermesEnterpriseAzureFoundryCostoPorMilTokens = @{
    "gpt-5-mini" = 0.0005
    "gpt-5"      = 0.005
    "gpt-5.5"    = 0.01
    "gpt-4o"     = 0.005
    "gpt-4o-mini"= 0.0006
}

function New-HermesEnterpriseAzureFoundryCorrelationId {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return [guid]::NewGuid().ToString()
}

function Protect-HermesEnterpriseAzureFoundryTelemetryData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][hashtable]$Datos
    )

    $ClavesSensibles = @("apikey", "api_key", "key", "token", "authorization", "secret", "password", "credential")
    $DatosSanitizados = @{}
    foreach ($Clave in $Datos.Keys) {
        $Valor = $Datos[$Clave]
        $ClaveNormalizada = $Clave.ToLower()
        if ($ClavesSensibles -contains $ClaveNormalizada) {
            $DatosSanitizados[$Clave] = "***REDACTED***"
        }
        elseif ($Valor -is [hashtable]) {
            $DatosSanitizados[$Clave] = Protect-HermesEnterpriseAzureFoundryTelemetryData -Datos $Valor
        }
        else {
            $DatosSanitizados[$Clave] = $Valor
        }
    }
    return $DatosSanitizados
}

function Get-HermesEnterpriseAzureFoundryEstimatedCost {
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory = $true)][string]$Modelo,
        [Parameter(Mandatory = $true)][int]$TokensEntrada,
        [Parameter(Mandatory = $true)][int]$TokensSalida
    )

    $CostoBase = 0.0
    foreach ($Patron in $SCRIPT:HermesEnterpriseAzureFoundryCostoPorMilTokens.Keys) {
        if ($Modelo -like "*$Patron*") {
            $CostoBase = $SCRIPT:HermesEnterpriseAzureFoundryCostoPorMilTokens[$Patron]
            break
        }
    }

    if ($CostoBase -eq 0.0) { return 0.0 }

    $CostoEntrada = ($TokensEntrada / 1000.0) * $CostoBase
    $CostoSalida = ($TokensSalida / 1000.0) * ($CostoBase * 2)
    return [math]::Round($CostoEntrada + $CostoSalida, 6)
}

function Write-HermesEnterpriseAzureFoundryTelemetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)][psobject]$LoggerKernel = $null,
        [Parameter(Mandatory = $true)][string]$CorrelationId,
        [Parameter(Mandatory = $true)][string]$NombreOperacion,
        [Parameter(Mandatory = $true)][datetime]$HoraInicio,
        [Parameter(Mandatory = $true)][datetime]$HoraFin,
        [Parameter(Mandatory = $false)][string]$Deployment = "",
        [Parameter(Mandatory = $false)][int]$TokensEntrada = 0,
        [Parameter(Mandatory = $false)][int]$TokensSalida = 0,
        [Parameter(Mandatory = $false)][string]$Modelo = "",
        [Parameter(Mandatory = $false)][string]$Estado = "OK",
        [Parameter(Mandatory = $false)][string]$ErrorMensaje = "",
        [Parameter(Mandatory = $false)][hashtable]$DatosAdicionales = @{}
    )

    if ($null -eq $LoggerKernel) { return $null }

    $LatenciaMilisegundos = [Math]::Max(0, [int](New-TimeSpan -Start $HoraInicio -End $HoraFin).TotalMilliseconds)
    $CostoEstimado = 0.0
    if (-not [string]::IsNullOrWhiteSpace($Modelo) -and ($TokensEntrada -gt 0 -or $TokensSalida -gt 0)) {
        $CostoEstimado = Get-HermesEnterpriseAzureFoundryEstimatedCost -Modelo $Modelo -TokensEntrada $TokensEntrada -TokensSalida $TokensSalida
    }

    $DatosEvento = @{
        TipoRegistro = "AzureFoundryTelemetry"
        CorrelationId = $CorrelationId
        NombreOperacion = $NombreOperacion
        Deployment = $Deployment
        LatenciaMilisegundos = $LatenciaMilisegundos
        TokensEntrada = $TokensEntrada
        TokensSalida = $TokensSalida
        CostoEstimadoUSD = $CostoEstimado
        Modelo = $Modelo
        Estado = $Estado
        HoraInicio = $HoraInicio.ToString("o")
        HoraFin = $HoraFin.ToString("o")
    }

    if (-not [string]::IsNullOrWhiteSpace($ErrorMensaje)) {
        $DatosEvento["Error"] = $ErrorMensaje
    }

    foreach ($Clave in $DatosAdicionales.Keys) {
        if (-not $DatosEvento.ContainsKey($Clave)) {
            $DatosEvento[$Clave] = $DatosAdicionales[$Clave]
        }
    }

    $DatosEvento = Protect-HermesEnterpriseAzureFoundryTelemetryData -Datos $DatosEvento

    $Nivel = if ($Estado -eq "Error") { "ERROR" } else { "INFO" }
    return Write-HermesEnterpriseLogEvent `
        -LoggerKernel $LoggerKernel `
        -Nivel $Nivel `
        -Mensaje "AzureFoundryProvider operacion $NombreOperacion" `
        -DatosEvento $DatosEvento `
        -CorrelationId $CorrelationId
}
