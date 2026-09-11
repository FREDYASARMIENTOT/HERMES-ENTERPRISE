function Leer-ConfiguracionAzure {
    <#
    .SYNOPSIS
        Lee la configuración de infraestructura Azure desde Hermes.Azure.json.
    .PARAMETER ConfigPath
        Ruta a Hermes.Azure.json.
    .OUTPUTS
        Hashtable con detalles de infraestructura Azure.
    #>
    param(
        [Parameter(Mandatory)] [string] $ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Configuración de Azure no encontrada: $ConfigPath"
    }

    $configuracion = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

    $requeridos = @("ResourceGroupAplicaciones")
    $faltantes = @()
    $azure = @{}

    # Soporte para ambos formatos: plano y anidado
    $cfg = $configuracion
    if ($configuracion.PSObject.Properties.Name -contains "Azure") {
        $cfg = $configuracion.Azure
    }

    $azure["resourceGroup"] = $cfg.ResourceGroupAplicaciones
    $azure["resourceGroupPlan"] = if ($cfg.PSObject.Properties.Name -contains "ResourceGroupPlan") { $cfg.ResourceGroupPlan } else { $cfg.ResourceGroupAplicaciones }

    # AppServicePlan es ahora por proyecto (asp-{projectName}); usar config si existe, sino vacío
    if ($cfg.PSObject.Properties.Name -contains "AppServicePlan" -and $cfg.AppServicePlan -and $cfg.AppServicePlan -ne "") {
        $azure["appServicePlan"] = $cfg.AppServicePlan
    } else {
        $azure["appServicePlan"] = ""  # Dinámico por proyecto (asp-{projectName})
        Write-Host "[Azure] No hay AppServicePlan estático configurado. Usando nomenclatura por proyecto (asp-{projectName})."
    }

    $azure["storageAccount"] = if ($cfg.PSObject.Properties.Name -contains "StorageAccount") { $cfg.StorageAccount } else { "" }
    $azure["keyVault"] = ""

    if ($cfg.PSObject.Properties.Name -contains "KeyVault") {
        $azure["keyVault"] = $cfg.KeyVault
    }

    foreach ($propiedad in @("ResourceGroupAplicaciones")) {
        if ([string]::IsNullOrEmpty($cfg.$propiedad) -or $cfg.$propiedad -eq "") {
            $faltantes += $propiedad
        }
    }


    if ($faltantes.Count -gt 0) {
        throw "Faltan recursos requeridos de Azure en config: $($faltantes -join ', '). No se puede continuar."
    }

    if ($cfg.PSObject.Properties.Name -contains "Location") {
        $azure.Location = $cfg.Location
    }
    if ($cfg.PSObject.Properties.Name -contains "subscriptionId") {
        $azure.SubscriptionId = $cfg.subscriptionId
    }

    Write-Host "[Azure] Configuración cargada desde: $ConfigPath"
    Write-Host "[Azure] ResourceGroup: $($azure.resourceGroup)"
    Write-Host "[Azure] AppServicePlan: $($azure.appServicePlan)"

    return $azure
}

function Validar-InfraestructuraAzure {
    <#
    .SYNOPSIS
        Valida que la infraestructura Azure requerida exista (NO se permite creación).
    .PARAMETER AzureConfig
        Hashtable con configuración de Azure.
    .OUTPUTS
        Hashtable con resultados de validación.
    #>
    param(
        [Parameter(Mandatory)] [hashtable] $AzureConfig
    )

    Write-Host "[Azure] Validando infraestructura existente..."

    $errores = @()
    $resultados = @{
        ResourceGroup = $false
        AppServicePlan = $false
        StorageAccount = $false
        KeyVault = $false
    }

    $salidaRg = az group exists --name $AzureConfig.resourceGroup 2>&1
    $resultados.ResourceGroup = ([string]$salidaRg).Trim() -eq "true"
    Write-Host "[Azure] Resource Group '$($AzureConfig.resourceGroup)' existe: $($resultados.ResourceGroup)"
    if (-not $resultados.ResourceGroup) { $errores += "ResourceGroup" }

    $rgPlan = if ($AzureConfig.ContainsKey("resourceGroupPlan") -and $AzureConfig.resourceGroupPlan) { $AzureConfig.resourceGroupPlan } else { $AzureConfig.resourceGroup }
    $asp = az appservice plan show --name $AzureConfig.appServicePlan --resource-group $rgPlan --query name -o tsv 2>&1
    $resultados.AppServicePlan = ($LASTEXITCODE -eq 0)
    Write-Host "[Azure] App Service Plan '$($AzureConfig.appServicePlan)' en '$rgPlan' existe: $($resultados.AppServicePlan)"
    if (-not $resultados.AppServicePlan) { $errores += "AppServicePlan" }

    # Opcional: advertencias para recursos no críticos
    $sa = az storage account show --name $AzureConfig.storageAccount --resource-group $AzureConfig.resourceGroup --query name -o tsv 2>&1
    $resultados.StorageAccount = ($LASTEXITCODE -eq 0)
    if (-not $resultados.StorageAccount) { Write-Host "[Azure] [ADVERTENCIA] StorageAccount '$($AzureConfig.storageAccount)' no encontrado (no crítico)" }

    if ($AzureConfig.keyVault) {
        $kv = az keyvault show --name $AzureConfig.keyVault --resource-group $AzureConfig.resourceGroup --query name -o tsv 2>&1
        $resultados.KeyVault = ($LASTEXITCODE -eq 0)
        if (-not $resultados.KeyVault) { Write-Host "[Azure] [ADVERTENCIA] KeyVault '$($AzureConfig.keyVault)' no encontrado (no crítico)" }
    }

    if ($errores.Count -gt 0) {
        throw "Validación de infraestructura Azure falló. Faltan críticos: $($errores -join ', '). No se puede continuar."
    }

    Write-Host "[Azure] Toda la infraestructura crítica validada exitosamente"
    return $resultados
}

function New-ProyectoWebApp {
    <#
    .SYNOPSIS
        Crea una nueva Azure Web App usando infraestructura EXISTENTE solamente.
    .PARAMETER WebAppName
        Nombre de la Web App (derivado automáticamente del proyecto).
    .PARAMETER AzureConfig
        Hashtable con configuración de Azure.
    .OUTPUTS
        Hashtable con información de la Web App.
    #>
    param(
        [Parameter(Mandatory)] [string] $WebAppName,
        [Parameter(Mandatory)] [hashtable] $AzureConfig
    )

    $horaInicio = Get-Date

    Write-Host "[Azure] Creando Web App: $WebAppName"

    # Determinar grupo de recursos del ASP para el ID completo del recurso
    $rgPlan = if ($AzureConfig.ContainsKey("resourceGroupPlan") -and $AzureConfig.resourceGroupPlan) { $AzureConfig.resourceGroupPlan } else { $AzureConfig.resourceGroup }
    $aspId = "/subscriptions/$($AzureConfig.SubscriptionId)/resourceGroups/$rgPlan/providers/Microsoft.Web/serverfarms/$($AzureConfig.appServicePlan)"

    $existente = az webapp show --name $WebAppName --resource-group $AzureConfig.resourceGroup --query name -o tsv 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[Azure] Web App ya existe: $WebAppName"
        $creado = $false
    }
    else {
        $salida = az webapp create `
            --name $WebAppName `
            --resource-group $AzureConfig.resourceGroup `
            --plan $aspId `
            --runtime "PYTHON:3.12" 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Error al crear Web App: $WebAppName`n$salida"
        }
        Write-Host "[Azure] Web App creada: $WebAppName"
        $creado = $true
    }

    $hostPredeterminado = "https://$WebAppName.azurewebsites.net"

    az webapp config set `
        --name $WebAppName `
        --resource-group $AzureConfig.resourceGroup `
        --startup-file "startup.sh" 2>&1 | Out-Null

    az webapp config appsettings set `
        --name $WebAppName `
        --resource-group $AzureConfig.resourceGroup `
        --settings SCM_DO_BUILD_DURING_DEPLOYMENT=false WEBSITE_RUN_FROM_PACKAGE=0 2>&1 | Out-Null

    $tiempoTranscurrido = (Get-Date) - $horaInicio
    $duracion = [math]::Round($tiempoTranscurrido.TotalSeconds, 2)

    return @{
        WebAppName = $WebAppName
        Url = $hostPredeterminado
        Created = $creado
        Duration = $duracion
        Status = "OK"
    }
}

function Deploy-ProyectoZipToAzure {
    <#
    .SYNOPSIS
        Despliega un paquete ZIP a Azure Web App usando Zip Deploy.
    .PARAMETER WebAppName
        Nombre de la Web App.
    .PARAMETER ResourceGroup
        Nombre del grupo de recursos.
    .PARAMETER ZipPath
        Ruta al paquete ZIP.
    .PARAMETER MaxRetries
        Número máximo de reintentos de despliegue.
    .OUTPUTS
        Hashtable con estado del despliegue.
    #>
    param(
        [Parameter(Mandatory)] [string] $WebAppName,
        [Parameter(Mandatory)] [string] $ResourceGroup,
        [Parameter(Mandatory)] [string] $ZipPath,
        [int] $MaxRetries = 3
    )

    $horaInicio = Get-Date

    Write-Host "[Deploy] Iniciando Zip Deploy: $ZipPath -> $WebAppName"

    $intento = 0
    $desplegado = $false

    do {
        $intento++
        Write-Host "[Deploy] Intento $intento de $MaxRetries"

        $salida = az webapp deploy `
            --name $WebAppName `
            --resource-group $ResourceGroup `
            --src-path $ZipPath `
            --type zip 2>&1

        if ($LASTEXITCODE -eq 0) {
            $desplegado = $true
            Write-Host "[Deploy] Zip Deploy exitoso en intento $intento"
            break
        }
        else {
            Write-Host "[Deploy] Intento $intento falló. Esperando antes de reintentar..."
            Start-Sleep -Seconds 10
        }
    } while ($intento -lt $MaxRetries)

    $tiempoTranscurrido = (Get-Date) - $horaInicio
    $duracion = [math]::Round($tiempoTranscurrido.TotalSeconds, 2)

    if (-not $desplegado) {
        throw "Zip Deploy falló después de $MaxRetries intentos"
    }

    return @{
        Attempts = $intento
        Duration = $duracion
        Status = "OK"
    }
}

function Wait-ProyectoWebAppReady {
    <#
    .SYNOPSIS
        Espera hasta que la Web App responda con HTTP 200.
    .PARAMETER Url
        URL de la Web App.
    .PARAMETER TimeoutSeconds
        Tiempo máximo de espera.
    .OUTPUTS
        Hashtable con estado de disponibilidad.
    #>
    param(
        [Parameter(Mandatory)] [string] $Url,
        [int] $TimeoutSeconds = 120
    )

    $horaInicio = Get-Date
    Write-Host "[Azure] Esperando a que la Web App esté lista: $Url"

    $lista = $false
    $tiempoTranscurrido = 0

    while ($tiempoTranscurrido -lt $TimeoutSeconds) {
        try {
            $respuesta = Invoke-WebRequest -Uri "$Url/health" -Method GET -UseBasicParsing -TimeoutSec 10
            if ($respuesta.StatusCode -eq 200) {
                $lista = $true
                Write-Host "[Azure] Web App lista después de ${tiempoTranscurrido}s"
                break
            }
        }
        catch {
            # Aún no está lista
        }

        Start-Sleep -Seconds 5
        $tiempoTranscurrido = [math]::Round(((Get-Date) - $horaInicio).TotalSeconds)
    }

    if (-not $lista) {
        Write-Host "[Azure] La Web App no se puso lista dentro de ${TimeoutSeconds}s"
    }

    return @{
        Ready = $lista
        WaitTime = $tiempoTranscurrido
        Url = $Url
    }
}

function Obtener-ModoIdentidadAzure {
    <#
    .SYNOPSIS
        Retorna el modo actual de autenticación de identidad Azure desde la configuración.
    .PARAMETER ConfigPath
        Ruta a Hermes.Azure.json.
    .OUTPUTS
        Hashtable con detalles del modo de identidad.
    .NOTES
        Modos soportados:
          - TemporaryExistingApp: Usa un App Registration existente (ej. 'Hermes-Enterprise-OIDC')
            con identidad federada OIDC. HUMANO_REQUERIDO para la creación inicial del App Registration
            y configuración de credencial federada.
          - DedicatedHermesApp: Estado futuro donde Hermes crea su propio App Registration
            automáticamente (requiere permisos de Administrador de Aplicaciones).
          - LEGACY: Usa sesión local de az CLI para autenticación.
    #>
    param(
        [Parameter(Mandatory)] [string] $ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "[AzureIdentity] ADVERTENCIA: Configuración no encontrada en $ConfigPath"
        return @{
            Mode = "UNKNOWN"
            TenantId = ""
            SubscriptionId = ""
            TargetApp = ""
            Scope = ""
            ScopeType = ""
            Description = "Archivo de configuración no encontrado"
            IsReady = $false
        }
    }

    $configuracion = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

    # Soporte para ambos formatos: plano y anidado
    $cfg = $configuracion
    if ($configuracion.PSObject.Properties.Name -contains "Azure") {
        $cfg = $configuracion.Azure
    }

    $modo = if ($cfg.PSObject.Properties.Name -contains "AzureIdentityMode") { $cfg.AzureIdentityMode } else { "LEGACY" }
    $tenantId = if ($cfg.PSObject.Properties.Name -contains "tenantId") { $cfg.tenantId } else { "" }
    $subscriptionId = if ($cfg.PSObject.Properties.Name -contains "subscriptionId") { $cfg.subscriptionId } else { "" }
    $appDestino = if ($cfg.PSObject.Properties.Name -contains "AzureIdentityTargetApp") { $cfg.AzureIdentityTargetApp } else { "" }
    $alcance = if ($cfg.PSObject.Properties.Name -contains "AzureIdentityScope") { $cfg.AzureIdentityScope } else { "" }
    $tipoAlcance = if ($cfg.PSObject.Properties.Name -contains "AzureIdentityScopeType") { $cfg.AzureIdentityScopeType } else { "" }
    $descripcion = if ($cfg.PSObject.Properties.Name -contains "AzureIdentityModeDescription") { $cfg.AzureIdentityModeDescription } else { "Autenticación de sesión local az CLI heredada" }

    $estaListo = $false
    $bloqueador = ""

    if ($modo -eq "TemporaryExistingApp" -or $modo -eq "DedicatedHermesApp" -or $modo -eq "DedicatedApp") {
        # La preparación OIDC depende de que los secretos de GitHub estén configurados
        try {
            $propietario = "FREDYASARMIENTOT"
            $nombreRepo = "HERMES-ENTERPRISE"
            $repoCompleto = "$propietario/$nombreRepo"

            $verificacionClientId = gh secret list --repo $repoCompleto --json name 2>&1
            if ($LASTEXITCODE -eq 0) {
                $infoSecreto = $verificacionClientId | ConvertFrom-Json
                $nombresSecretos = $infoSecreto | ForEach-Object { $_.name }
                $tieneClientId = $nombresSecretos -contains "AZURE_CLIENT_ID"
                $tieneTenantId = $nombresSecretos -contains "AZURE_TENANT_ID"
                $tieneSubId = $nombresSecretos -contains "AZURE_SUBSCRIPTION_ID"
                if ($tieneClientId -and $tieneTenantId -and $tieneSubId) {
                    $estaListo = $true
                } else {
                    $faltantes = @()
                    if (-not $tieneClientId) { $faltantes += "AZURE_CLIENT_ID" }
                    if (-not $tieneTenantId) { $faltantes += "AZURE_TENANT_ID" }
                    if (-not $tieneSubId) { $faltantes += "AZURE_SUBSCRIPTION_ID" }
                    $bloqueador = "Secretos de GitHub no configurados: $($faltantes -join ', ')"
                }
            } else {
                $bloqueador = "No se puede acceder a secretos de GitHub para $repoCompleto. Asegúrese de que 'gh' esté autenticado."
            }
        } catch {
            $bloqueador = "Error al verificar secretos de GitHub: $_"
        }

        if (-not $estaListo) {
            $bloqueador += " (HUMANO_REQUERIDO)"
        }
    } elseif ($modo -eq "LEGACY" -or $modo -eq "UNKNOWN") {
        # Modo heredado - verificar si az cli tiene sesión activa
        try {
            $verificacionAz = az account show 2>&1
            if ($LASTEXITCODE -eq 0) {
                $estaListo = $true
            } else {
                $bloqueador = "No hay sesión activa de az CLI. Ejecute 'az login'"
            }
        } catch {
            $bloqueador = "az CLI no disponible: $_"
        }
    }

    Write-Host "[AzureIdentity] Mode: $modo | Ready: $estaListo"
    if ($bloqueador) { Write-Host "[AzureIdentity] Bloqueador: $bloqueador" }

    return @{
        Mode = $modo
        TenantId = $tenantId
        SubscriptionId = $subscriptionId
        TargetApp = $appDestino
        Scope = $alcance
        ScopeType = $tipoAlcance
        Description = $descripcion
        IsReady = $estaListo
        Blocker = $bloqueador
    }
}

function Afirmar-IdentidadAzureLista {
    <#
    .SYNOPSIS
        Valida que la autenticación de identidad Azure esté lista para usar.
        Lanza un error descriptivo si no está lista.
    .PARAMETER ConfigPath
        Ruta a Hermes.Azure.json.
    .OUTPUTS
        Hashtable con estado de identidad.
    #>
    param(
        [Parameter(Mandatory)] [string] $ConfigPath
    )

    $estadoIdentidad = Obtener-ModoIdentidadAzure -ConfigPath $ConfigPath

    if (-not $estadoIdentidad.IsReady) {
        $msg = "La identidad Azure NO está lista. Modo: $($estadoIdentidad.Mode). Bloqueador: $($estadoIdentidad.Blocker)"
        if ($estadoIdentidad.Mode -eq "TemporaryExistingApp" -or $estadoIdentidad.Mode -eq "DedicatedApp" -or $estadoIdentidad.Mode -eq "DedicatedHermesApp") {
            $msg += "`n  HUMANO_REQUERIDO: Un Administrador de Azure AD debe:"
            $msg += "`n    1. Crear App Registration '$($estadoIdentidad.TargetApp)' (NO 'UR - App - SII 2.0')"
            $msg += "`n    2. Crear credencial federada para este repositorio:"
            $msg += "`n       Subject: repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production"
            $msg += "`n       Issuer: https://token.actions.githubusercontent.com"
            $msg += "`n       Audience: api://AzureADTokenExchange"
            $msg += "`n    3. Conceder rol Contributor en $($estadoIdentidad.ScopeType) '$($estadoIdentidad.Scope)' (NO subscription-wide)"
            $msg += "`n    4. Configurar AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID como secretos de GitHub"
        } elseif ($estadoIdentidad.Mode -eq "LEGACY" -or $estadoIdentidad.Mode -eq "UNKNOWN") {
            $msg += "`n  Ejecute 'az login' para autenticarse localmente para modo LEGACY."
        }
        throw $msg
    }

    Write-Host "[AzureIdentity] Autenticación lista: $($estadoIdentidad.Mode) -> $($estadoIdentidad.TargetApp)"
    return $estadoIdentidad
}

Export-ModuleMember -Function Leer-ConfiguracionAzure, Validar-InfraestructuraAzure, New-ProyectoWebApp, Deploy-ProyectoZipToAzure, Wait-ProyectoWebAppReady, Obtener-ModoIdentidadAzure, Afirmar-IdentidadAzureLista
