<#
.SYNOPSIS
    Funciones internas para gestión de configuración canónica de Azure.
.DESCRIPTION
    Proporciona Get-HermesAzureConfiguration, Set-HermesAzureConfiguration
    y Resolve-HermesAppServicePlanId como funciones privadas no exportadas.
    Usadas internamente por Crear-HermesProyecto y Bootstrap.
.NOTES
    Proyecto  : HERMES-ENTERPRISE — RC69
    Principio : Hermes NO descubre recursos Azure.
                Hermes únicamente LEE configuración canónica.
#>

Set-StrictMode -Version Latest

# ─────────────────────────────────────────────────────────────────
# CONSTANTES
# ─────────────────────────────────────────────────────────────────
$script:AZURE_CONFIG_PATH = 'config/Hermes.Azure.json'

# ─────────────────────────────────────────────────────────────────
# FUNCIONES INTERNAS
# ─────────────────────────────────────────────────────────────────

function _Get-AzureConfigPath {
    <#
    .SYNOPSIS
        Obtiene la ruta absoluta al archivo Hermes.Azure.json.
    .DESCRIPTION
        Resuelve la ruta relativa config/Hermes.Azure.json contra la raíz
        del proyecto Hermes Enterprise.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $root = _Get-HermesRoot
    return Join-Path $root $script:AZURE_CONFIG_PATH
}

function _Read-AzureConfiguration {
    <#
    .SYNOPSIS
        Lee y valida Hermes.Azure.json.
    .DESCRIPTION
        Retorna un PSCustomObject con la configuración Azure.
        Si el archivo no existe o es inválido, retorna $null.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $configPath = _Get-AzureConfigPath
    if (-not (Test-Path $configPath)) {
        Write-Warning "[Hermes] Azure configuration not found at '$configPath'"
        return $null
    }

    try {
        $raw = Get-Content -Path $configPath -Raw -ErrorAction Stop
        $parsed = $raw | ConvertFrom-Json -ErrorAction Stop

        # Validate required fields
        $azure = $parsed.Azure
        if (-not $azure) {
            Write-Warning "[Hermes] Hermes.Azure.json missing 'Azure' root key"
            return $null
        }

        $required = @('Location', 'ResourceGroupAplicaciones', 'ResourceGroupPlan', 'AppServicePlan', 'UseSharedInfrastructure')
        foreach ($key in $required) {
            if (-not ($azure.PSObject.Properties.Name -contains $key)) {
                Write-Warning "[Hermes] Azure configuration missing required field: '$key'"
                return $null
            }
        }

        # Return with defaults for optional fields
        return [PSCustomObject]@{
            PSTypeName                = 'Hermes.AzureConfiguration'
            Location                  = $azure.Location
            ResourceGroupAplicaciones = $azure.ResourceGroupAplicaciones
            ResourceGroupPlan         = $azure.ResourceGroupPlan
            AppServicePlan            = $azure.AppServicePlan
            StorageAccount            = if ($azure.PSObject.Properties.Name -contains 'StorageAccount') { $azure.StorageAccount } else { '' }
            UseSharedInfrastructure   = [bool]$azure.UseSharedInfrastructure
        }
    }
    catch {
        Write-Warning "[Hermes] Failed to parse Azure configuration: $_"
        return $null
    }
}

function _Save-AzureConfiguration {
    <#
    .SYNOPSIS
        Escribe la configuración Azure a Hermes.Azure.json.
    .DESCRIPTION
        Recibe un hashtable o PSCustomObject con los valores y lo persiste.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Configuration
    )

    $configPath = _Get-AzureConfigPath
    $configDir = Split-Path $configPath -Parent

    # Ensure config directory exists
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }

    $content = @{
        Azure = @{
            Location                  = $Configuration.Location
            ResourceGroupAplicaciones = $Configuration.ResourceGroupAplicaciones
            ResourceGroupPlan         = $Configuration.ResourceGroupPlan
            AppServicePlan            = $Configuration.AppServicePlan
            StorageAccount            = if ($Configuration.PSObject.Properties.Name -contains 'StorageAccount') { $Configuration.StorageAccount } else { '' }
            UseSharedInfrastructure   = [bool]$Configuration.UseSharedInfrastructure
        }
    }

    $content | ConvertTo-Json -Depth 3 | Out-File -FilePath $configPath -Encoding utf8 -Force
    Write-Verbose "[Hermes] Azure configuration saved to '$configPath'"
}

function _Write-AzureHistory {
    <#
    .SYNOPSIS
        Registra en SQLite el historial de operaciones Azure.
    .DESCRIPTION
        Inserta un registro en AzureConfigurationHistory con los detalles
        de la configuración utilizada y el resultado de la operación.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [string]$Subscription,

        [Parameter(Mandatory = $true)]
        [string]$Location,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupAplicaciones,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupPlan,

        [Parameter(Mandatory = $true)]
        [string]$AppServicePlan,

        [Parameter(Mandatory = $true)]
        [string]$ResourceId,

        [Parameter(Mandatory = $true)]
        [string]$Proyecto,

        [Parameter(Mandatory = $true)]
        [string]$Resultado
    )

    $db = _Get-HermesDb
    if (-not (Test-Path $db)) { return }

    # Ensure table exists
    & sqlite3.exe "`"$db`"" @"
CREATE TABLE IF NOT EXISTS AzureConfigurationHistory (
    Id                      TEXT PRIMARY KEY,
    Fecha                   TEXT NOT NULL,
    Usuario                 TEXT NOT NULL,
    Subscription            TEXT NOT NULL,
    Location                TEXT NOT NULL,
    ResourceGroupAplicaciones TEXT NOT NULL,
    ResourceGroupPlan       TEXT NOT NULL,
    AppServicePlan          TEXT NOT NULL,
    AppServicePlanId        TEXT NOT NULL,
    Proyecto                TEXT NOT NULL,
    Resultado               TEXT NOT NULL,
    CreatedAt               TEXT DEFAULT (datetime('now'))
);
"@ 2>$null | Out-Null

    $id = _New-GuidH
    $user = $env:USERNAME
    $fecha = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    # Escape single quotes
    $sub = $Subscription.Replace("'", "''")
    $loc = $Location.Replace("'", "''")
    $rga = $ResourceGroupAplicaciones.Replace("'", "''")
    $rgp = $ResourceGroupPlan.Replace("'", "''")
    $asp = $AppServicePlan.Replace("'", "''")
    $rid = $ResourceId.Replace("'", "''")
    $proj = $Proyecto.Replace("'", "''")
    $res = $Resultado.Replace("'", "''")

    $sql = "INSERT INTO AzureConfigurationHistory (Id, Fecha, Usuario, Subscription, Location, ResourceGroupAplicaciones, ResourceGroupPlan, AppServicePlan, AppServicePlanId, Proyecto, Resultado) VALUES ('$id', '$fecha', '$user', '$sub', '$loc', '$rga', '$rgp', '$asp', '$rid', '$proj', '$res')"

    & sqlite3.exe "`"$db`"" $sql 2>$null | Out-Null
    Write-Verbose "[Hermes] Azure history written: $Action / $Proyecto / $Resultado"
}

# ─────────────────────────────────────────────────────────────────
# FUNCIONES PÚBLICAS — Movidas a Public/ para exportación automática
# ─────────────────────────────────────────────────────────────────
# RC70-D: Get-HermesAzureConfiguration, Set-HermesAzureConfiguration,
# y Resolve-HermesAppServicePlanId fueron migrados a sus respectivos
# archivos en Public/ para que el AST del módulo las detecte y exporte.
# Las implementaciones originales estaban aquí pero causaban que no se
# exportaran porque el parser del módulo sólo escanea Public/*.ps1.
