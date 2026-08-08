function Read-AzureConfiguration {
    <#
    .SYNOPSIS
        Reads Azure infrastructure configuration from Hermes.Azure.json.
    .PARAMETER ConfigPath
        Path to Hermes.Azure.json.
    .OUTPUTS
        Hashtable with Azure infrastructure details.
    #>
    param(
        [Parameter(Mandatory)] [string] $ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Azure configuration not found: $ConfigPath"
    }

    $config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

    $required = @("ResourceGroupAplicaciones", "AppServicePlan", "StorageAccount")
    $missing = @()
    $azure = @{}

    # Support both flat and nested config formats
    $cfg = $config
    if ($config.PSObject.Properties.Name -contains "Azure") {
        $cfg = $config.Azure
    }

    $azure["resourceGroup"] = $cfg.ResourceGroupAplicaciones
    $azure["resourceGroupPlan"] = if ($cfg.PSObject.Properties.Name -contains "ResourceGroupPlan") { $cfg.ResourceGroupPlan } else { $cfg.ResourceGroupAplicaciones }
    $azure["appServicePlan"] = $cfg.AppServicePlan
    $azure["storageAccount"] = $cfg.StorageAccount
    $azure["keyVault"] = ""

    if ($cfg.PSObject.Properties.Name -contains "KeyVault") {
        $azure["keyVault"] = $cfg.KeyVault
    }

    foreach ($prop in @("ResourceGroupAplicaciones", "ResourceGroupPlan", "AppServicePlan", "StorageAccount")) {
        if ([string]::IsNullOrEmpty($cfg.$prop) -or $cfg.$prop -eq "") {
            $missing += $prop
        }
    }


    if ($missing.Count -gt 0) {
        throw "Missing required Azure resources in config: $($missing -join ', '). Cannot proceed."
    }

    if ($cfg.PSObject.Properties.Name -contains "Location") {
        $azure.Location = $cfg.Location
    }
    if ($cfg.PSObject.Properties.Name -contains "subscriptionId") {
        $azure.SubscriptionId = $cfg.subscriptionId
    }

    Write-Host "[Azure] Configuration loaded from: $ConfigPath"
    Write-Host "[Azure] ResourceGroup: $($azure.resourceGroup)"
    Write-Host "[Azure] AppServicePlan: $($azure.appServicePlan)"

    return $azure
}

function Validate-AzureInfrastructure {
    <#
    .SYNOPSIS
        Validates that required Azure infrastructure exists (NO creation allowed).
    .PARAMETER AzureConfig
        Hashtable with Azure configuration.
    .OUTPUTS
        Hashtable with validation results.
    #>
    param(
        [Parameter(Mandatory)] [hashtable] $AzureConfig
    )

    Write-Host "[Azure] Validating existing infrastructure..."

    $errors = @()
    $results = @{
        ResourceGroup = $false
        AppServicePlan = $false
        StorageAccount = $false
        KeyVault = $false
    }

    $rgOut = az group exists --name $AzureConfig.resourceGroup 2>&1
    $results.ResourceGroup = ([string]$rgOut).Trim() -eq "true"
    Write-Host "[Azure] Resource Group '$($AzureConfig.resourceGroup)' exists: $($results.ResourceGroup)"
    if (-not $results.ResourceGroup) { $errors += "ResourceGroup" }

    $aspRg = if ($AzureConfig.ContainsKey("resourceGroupPlan") -and $AzureConfig.resourceGroupPlan) { $AzureConfig.resourceGroupPlan } else { $AzureConfig.resourceGroup }
    $asp = az appservice plan show --name $AzureConfig.appServicePlan --resource-group $aspRg --query name -o tsv 2>&1
    $results.AppServicePlan = ($LASTEXITCODE -eq 0)
    Write-Host "[Azure] App Service Plan '$($AzureConfig.appServicePlan)' in '$aspRg' exists: $($results.AppServicePlan)"
    if (-not $results.AppServicePlan) { $errors += "AppServicePlan" }

    # Optional: log warnings for non-critical resources
    $sa = az storage account show --name $AzureConfig.storageAccount --resource-group $AzureConfig.resourceGroup --query name -o tsv 2>&1
    $results.StorageAccount = ($LASTEXITCODE -eq 0)
    if (-not $results.StorageAccount) { Write-Host "[Azure] [WARN] StorageAccount '$($AzureConfig.storageAccount)' not found (non-critical)" }

    if ($AzureConfig.keyVault) {
        $kv = az keyvault show --name $AzureConfig.keyVault --resource-group $AzureConfig.resourceGroup --query name -o tsv 2>&1
        $results.KeyVault = ($LASTEXITCODE -eq 0)
        if (-not $results.KeyVault) { Write-Host "[Azure] [WARN] KeyVault '$($AzureConfig.keyVault)' not found (non-critical)" }
    }

    if ($errors.Count -gt 0) {
        throw "Azure infrastructure validation failed. Missing critical: $($errors -join ', '). Cannot proceed."
    }

    Write-Host "[Azure] All critical infrastructure validated successfully"
    return $results
}

function New-ProyectoWebApp {
    <#
    .SYNOPSIS
        Creates a new Azure Web App using EXISTING infrastructure only.
    .PARAMETER WebAppName
        Name for the Web App (auto-derived from project).
    .PARAMETER AzureConfig
        Hashtable with Azure configuration.
    .OUTPUTS
        Hashtable with Web App information.
    #>
    param(
        [Parameter(Mandatory)] [string] $WebAppName,
        [Parameter(Mandatory)] [hashtable] $AzureConfig
    )

    $startTime = Get-Date

    Write-Host "[Azure] Creating Web App: $WebAppName"

    # Determine ASP resource group for full resource ID
    $aspRg = if ($AzureConfig.ContainsKey("resourceGroupPlan") -and $AzureConfig.resourceGroupPlan) { $AzureConfig.resourceGroupPlan } else { $AzureConfig.resourceGroup }
    $aspId = "/subscriptions/$($AzureConfig.SubscriptionId)/resourceGroups/$aspRg/providers/Microsoft.Web/serverfarms/$($AzureConfig.appServicePlan)"

    $existing = az webapp show --name $WebAppName --resource-group $AzureConfig.resourceGroup --query name -o tsv 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[Azure] Web App already exists: $WebAppName"
        $created = $false
    }
    else {
        $output = az webapp create `
            --name $WebAppName `
            --resource-group $AzureConfig.resourceGroup `
            --plan $aspId `
            --runtime "PYTHON:3.12" 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Web App: $WebAppName`n$output"
        }
        Write-Host "[Azure] Web App created: $WebAppName"
        $created = $true
    }

    $defaultHost = "https://$WebAppName.azurewebsites.net"

    az webapp config set `
        --name $WebAppName `
        --resource-group $AzureConfig.resourceGroup `
        --startup-file "startup.sh" 2>&1 | Out-Null

    az webapp config appsettings set `
        --name $WebAppName `
        --resource-group $AzureConfig.resourceGroup `
        --settings SCM_DO_BUILD_DURING_DEPLOYMENT=false WEBSITE_RUN_FROM_PACKAGE=0 2>&1 | Out-Null

    $elapsed = (Get-Date) - $startTime
    $duration = [math]::Round($elapsed.TotalSeconds, 2)

    return @{
        WebAppName = $WebAppName
        Url = $defaultHost
        Created = $created
        Duration = $duration
        Status = "OK"
    }
}

function Deploy-ProyectoZipToAzure {
    <#
    .SYNOPSIS
        Deploys a ZIP package to Azure Web App using Zip Deploy.
    .PARAMETER WebAppName
        Name of the Web App.
    .PARAMETER ResourceGroup
        Resource group name.
    .PARAMETER ZipPath
        Path to the ZIP package.
    .PARAMETER MaxRetries
        Maximum number of deploy retries.
    .OUTPUTS
        Hashtable with deployment status.
    #>
    param(
        [Parameter(Mandatory)] [string] $WebAppName,
        [Parameter(Mandatory)] [string] $ResourceGroup,
        [Parameter(Mandatory)] [string] $ZipPath,
        [int] $MaxRetries = 3
    )

    $startTime = Get-Date

    Write-Host "[Deploy] Starting Zip Deploy: $ZipPath -> $WebAppName"

    $attempt = 0
    $deployed = $false

    do {
        $attempt++
        Write-Host "[Deploy] Attempt $attempt of $MaxRetries"

        $output = az webapp deploy `
            --name $WebAppName `
            --resource-group $ResourceGroup `
            --src-path $ZipPath `
            --type zip 2>&1

        if ($LASTEXITCODE -eq 0) {
            $deployed = $true
            Write-Host "[Deploy] Zip Deploy successful on attempt $attempt"
            break
        }
        else {
            Write-Host "[Deploy] Attempt $attempt failed. Waiting before retry..."
            Start-Sleep -Seconds 10
        }
    } while ($attempt -lt $MaxRetries)

    $elapsed = (Get-Date) - $startTime
    $duration = [math]::Round($elapsed.TotalSeconds, 2)

    if (-not $deployed) {
        throw "Zip Deploy failed after $MaxRetries attempts"
    }

    return @{
        Attempts = $attempt
        Duration = $duration
        Status = "OK"
    }
}

function Wait-ProyectoWebAppReady {
    <#
    .SYNOPSIS
        Waits for the Web App to respond with HTTP 200.
    .PARAMETER Url
        Web App URL.
    .PARAMETER TimeoutSeconds
        Maximum wait time.
    .OUTPUTS
        Hashtable with readiness status.
    #>
    param(
        [Parameter(Mandatory)] [string] $Url,
        [int] $TimeoutSeconds = 120
    )

    $startTime = Get-Date
    Write-Host "[Azure] Waiting for Web App to be ready: $Url"

    $ready = $false
    $elapsed = 0

    while ($elapsed -lt $TimeoutSeconds) {
        try {
            $response = Invoke-WebRequest -Uri "$Url/health" -Method GET -UseBasicParsing -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                $ready = $true
                Write-Host "[Azure] Web App ready after ${elapsed}s"
                break
            }
        }
        catch {
            # Not ready yet
        }

        Start-Sleep -Seconds 5
        $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
    }

    if (-not $ready) {
        Write-Host "[Azure] Web App did not become ready within ${TimeoutSeconds}s"
    }

    return @{
        Ready = $ready
        WaitTime = $elapsed
        Url = $Url
    }
}

Export-ModuleMember -Function Read-AzureConfiguration, Validate-AzureInfrastructure, New-ProyectoWebApp, Deploy-ProyectoZipToAzure, Wait-ProyectoWebAppReady