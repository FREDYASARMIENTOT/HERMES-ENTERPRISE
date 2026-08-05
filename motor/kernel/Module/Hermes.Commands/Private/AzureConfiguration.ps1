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
# FUNCIONES PÚBLICAS DEL MÓDULO (se exportan vía module manifest)
# ─────────────────────────────────────────────────────────────────

function Get-HermesAzureConfiguration {
    <#
    .SYNOPSIS
        Obtiene la configuración canónica de infraestructura Azure compartida.
    .DESCRIPTION
        Lee Hermes.Azure.json y retorna un objeto con todos los parámetros
        de infraestructura Azure compartida.

        Hermes NO descubre recursos Azure. Únicamente lee configuración.
    .PARAMETER Path
        Ruta opcional al archivo Hermes.Azure.json. Si no se especifica,
        se lee desde <ProjectRoot>/config/Hermes.Azure.json.
    .EXAMPLE
        Get-HermesAzureConfiguration

        Lee la configuración Azure desde la ruta por defecto.
    .EXAMPLE
        Get-HermesAzureConfiguration -Path "C:\Projects\MiProyecto\config\Hermes.Azure.json"

        Lee la configuración Azure desde una ruta específica.
    .OUTPUTS
        PSCustomObject. Retorna un objeto con las propiedades:
        Location, ResourceGroupAplicaciones, ResourceGroupPlan,
        AppServicePlan, StorageAccount, UseSharedInfrastructure.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path
    )

    if ($Path) {
        if (-not (Test-Path $Path)) {
            Write-Error "Azure configuration file not found: $Path"
            return $null
        }
        try {
            $raw = Get-Content -Path $Path -Raw -ErrorAction Stop
            $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
            $azure = $parsed.Azure
            if (-not $azure) {
                Write-Error "Invalid Azure configuration: missing 'Azure' root key"
                return $null
            }
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
            Write-Error "Failed to parse Azure configuration: $_"
            return $null
        }
    }

    return _Read-AzureConfiguration
}

function Set-HermesAzureConfiguration {
    <#
    .SYNOPSIS
        Establece la configuración canónica de infraestructura Azure compartida.
    .DESCRIPTION
        Escribe o sobrescribe Hermes.Azure.json con los valores especificados.
        Todos los parámetros tienen valores por defecto.

        Si no se especifica un parámetro, se conserva el valor actual si existe,
        o se usa el valor por defecto.
    .PARAMETER Location
        Región Azure (default: eastus).
    .PARAMETER ResourceGroupAplicaciones
        Resource Group para Web Apps (default: RG-Hermes-Proyectos).
    .PARAMETER ResourceGroupPlan
        Resource Group del App Service Plan (default: RG-Datamining-SII2.0-Dev).
    .PARAMETER AppServicePlan
        Nombre del App Service Plan (default: ASP-IAUR).
    .PARAMETER StorageAccount
        Cuenta de almacenamiento (default: saurhermesproyectos).
    .PARAMETER UseSharedInfrastructure
        Usar infraestructura compartida (default: true).
    .PARAMETER PassThru
        Retorna el objeto de configuración después de guardar.
    .PARAMETER WhatIf
        Muestra qué pasaría si se ejecuta el comando.
    .PARAMETER Confirm
        Solicita confirmación antes de ejecutar.
    .EXAMPLE
        Set-HermesAzureConfiguration -Location "westus" -PassThru

        Cambia la región a westus y retorna la configuración.
    .EXAMPLE
        Set-HermesAzureConfiguration -AppServicePlan "ASP-MiPlan" -ResourceGroupPlan "RG-MiGrupo"

        Cambia el plan y el resource group del plan.
    .OUTPUTS
        PSCustomObject. Si se usa -PassThru, retorna la configuración actualizada.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Location,

        [Parameter(Mandatory = $false)]
        [string]$ResourceGroupAplicaciones,

        [Parameter(Mandatory = $false)]
        [string]$ResourceGroupPlan,

        [Parameter(Mandatory = $false)]
        [string]$AppServicePlan,

        [Parameter(Mandatory = $false)]
        [string]$StorageAccount,

        [Parameter(Mandatory = $false)]
        [bool]$UseSharedInfrastructure,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # Read current config or use defaults
    $current = _Read-AzureConfiguration
    if (-not $current) {
        $current = [PSCustomObject]@{
            Location                  = 'eastus'
            ResourceGroupAplicaciones = 'RG-Hermes-Proyectos'
            ResourceGroupPlan         = 'RG-Datamining-SII2.0-Dev'
            AppServicePlan            = 'ASP-IAUR'
            StorageAccount            = 'saurhermesproyectos'
            UseSharedInfrastructure   = $true
        }
    }

    # Apply overrides
    if ($PSBoundParameters.ContainsKey('Location')) { $current.Location = $Location }
    if ($PSBoundParameters.ContainsKey('ResourceGroupAplicaciones')) { $current.ResourceGroupAplicaciones = $ResourceGroupAplicaciones }
    if ($PSBoundParameters.ContainsKey('ResourceGroupPlan')) { $current.ResourceGroupPlan = $ResourceGroupPlan }
    if ($PSBoundParameters.ContainsKey('AppServicePlan')) { $current.AppServicePlan = $AppServicePlan }
    if ($PSBoundParameters.ContainsKey('StorageAccount')) { $current.StorageAccount = $StorageAccount }
    if ($PSBoundParameters.ContainsKey('UseSharedInfrastructure')) { $current.UseSharedInfrastructure = $UseSharedInfrastructure }

    if ($PSCmdlet.ShouldProcess("Azure configuration", "Set configuration values")) {
        _Save-AzureConfiguration -Configuration $current
        Write-Verbose "[Hermes] Azure configuration updated"

        if ($PassThru) {
            return $current
        }
    }
}

function Resolve-HermesAppServicePlanId {
    <#
    .SYNOPSIS
        Resuelve el ResourceId de un App Service Plan existente en Azure.
    .DESCRIPTION
        Ejecuta 'az appservice plan show' para obtener el ResourceId del
        App Service Plan. Usa exclusivamente los valores de ResourceGroupPlan
        y AppServicePlan de la configuración.

        Hermes NO descubre planes. NO lista recursos. NO explora Azure.

        Requiere Azure CLI autenticado (az login).
    .PARAMETER ResourceGroupPlan
        Nombre del Resource Group donde reside el App Service Plan.
    .PARAMETER AppServicePlan
        Nombre del App Service Plan.
    .EXAMPLE
        Resolve-HermesAppServicePlanId -ResourceGroupPlan "RG-Datamining-SII2.0-Dev" -AppServicePlan "ASP-IAUR"

        Retorna el ResourceId del App Service Plan.
    .OUTPUTS
        string. Retorna el ResourceId del App Service Plan, o $null si falla.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupPlan,

        [Parameter(Mandatory = $true)]
        [string]$AppServicePlan
    )

    Write-Host "[..] Resolving App Service Plan ResourceId..." -ForegroundColor Yellow
    Write-Host "     Resource Group: $ResourceGroupPlan" -ForegroundColor Gray
    Write-Host "     Plan Name     : $AppServicePlan" -ForegroundColor Gray

    try {
        $result = & az appservice plan show `
            --resource-group $ResourceGroupPlan `
            --name $AppServicePlan `
            --query id `
            --output tsv 2>&1

        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($result)) {
            Write-Error "Failed to resolve App Service Plan '$AppServicePlan' in resource group '$ResourceGroupPlan'. Verify the plan exists and you have permission to access it."
            Write-Host "     az exit code: $LASTEXITCODE" -ForegroundColor Red
            Write-Host "     az output   : $result" -ForegroundColor Red
            return $null
        }

        $resourceId = $result.Trim()
        Write-Host "[OK] ResourceId: $resourceId" -ForegroundColor Green
        return $resourceId
    }
    catch {
        Write-Error "Failed to resolve App Service Plan ResourceId: $_"
        return $null
    }
}