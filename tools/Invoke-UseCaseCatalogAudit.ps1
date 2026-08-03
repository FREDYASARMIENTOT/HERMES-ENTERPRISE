<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Invoke-UseCaseCatalogAudit.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Proposito:
    FASE 1 - Auditoria de Use Cases, Capabilities, Providers y Engines.
    Escanea todos los archivos .ps1/.psm1 del proyecto para descubrir y catalogar:
        - Use Cases (Id, Name, Category, Priority, Status, Capability, Provider, Engine, Dependencies, Input, Output)
        - Capabilities
        - Providers
        - Engines
    Persiste el catalogo en SQLite usando HermesPersistence.
====================================================================================================
#>

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Ejecuta la auditoria completa del catalogo de Use Cases del sistema.
.DESCRIPTION
    Escanea recursivamente todos los archivos .ps1 y .psm1 del proyecto para extraer:
        - Use Cases registrados en UseCaseRegistry / UseCaseLibrary
        - Capabilities registradas en CapabilityRegistry / CapabilityRegistrar
        - Providers referenciados
        - Engines referenciados
    Luego persiste todo en SQLite.
.PARAMETER ProjectRoot
    Ruta raiz del proyecto HERMES-ENTERPRISE.
.PARAMETER DatabasePath
    Ruta opcional para la base de datos SQLite. Por defecto: ./data/hermes.db
.PARAMETER Force
    Si se especifica, fuerza la re-auditoria incluso si ya existen datos.
.EXAMPLE
    Invoke-UseCaseCatalogAudit -ProjectRoot "D:\HERMES-ENTERPRISE"
#>
function Invoke-UseCaseCatalogAudit {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ProjectRoot = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [string]$DatabasePath = $null,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  HERMES ENTERPRISE - USE CASE CATALOG AUDIT (FASE 1)" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
        throw "ProjectRoot not found: $ProjectRoot"
    }

    # Resolve database path from config or default
    if ([string]::IsNullOrEmpty($DatabasePath)) {
        $configPath = Join-Path -Path $ProjectRoot -ChildPath 'motor/config/persistence.psd1'
        if (Test-Path -Path $configPath) {
            $config = Import-PowerShellDataFile -Path $configPath
            $resolvedDbPath = Join-Path -Path $ProjectRoot -ChildPath $config.SQLite.DatabasePath
        } else {
            $resolvedDbPath = Join-Path -Path $ProjectRoot -ChildPath 'data/hermes.db'
        }
    } else {
        $resolvedDbPath = $DatabasePath
    }

    Write-Host "[INFO] Project Root : $ProjectRoot" -ForegroundColor Yellow
    Write-Host "[INFO] Database Path : $resolvedDbPath" -ForegroundColor Yellow
    Write-Host ""

    # ---- STEP 1: Scan all .ps1 and .psm1 files ---------------------------------
    Write-Host "[STEP 1/5] Scanning project files..." -ForegroundColor Green
    $files = @()
    $directoriesToScan = @(
        'motor',
        'scripts',
        'tools',
        'builders',
        'engine',
        'configuracion'
    )

    foreach ($dir in $directoriesToScan) {
        $fullDir = Join-Path -Path $ProjectRoot -ChildPath $dir
        if (Test-Path -Path $fullDir -PathType Container) {
            $found = Get-ChildItem -Path $fullDir -Recurse -Filter *.ps1 -File -ErrorAction SilentlyContinue |
                     Select-Object -ExpandProperty FullName
            $files += $found

            $found = Get-ChildItem -Path $fullDir -Recurse -Filter *.psm1 -File -ErrorAction SilentlyContinue |
                     Select-Object -ExpandProperty FullName
            $files += $found
        }
    }

    # Also scan root .ps1 files
    $rootFiles = Get-ChildItem -Path $ProjectRoot -Filter *.ps1 -File -ErrorAction SilentlyContinue |
                 Select-Object -ExpandProperty FullName
    $files += $rootFiles

    $files = $files | Sort-Object -Unique
    Write-Host "       Found $($files.Count) .ps1/.psm1 files to analyze." -ForegroundColor Gray

    # ---- Preload all file contents for pattern matching ------------------------
    $fileContent = @{}
    foreach ($f in $files) {
        $fileContent[$f] = Get-Content -Path $f -Raw -ErrorAction SilentlyContinue
    }

    # ---- STEP 2: Extract Use Cases --------------------------------------------
    Write-Host "[STEP 2/5] Extracting Use Cases..." -ForegroundColor Green
    $useCases = [System.Collections.ArrayList]@()
    $useCaseNames = @{}  # Track unique names to avoid duplicates

    foreach ($f in $files) {
        $content = $fileContent[$f]
        if ([string]::IsNullOrEmpty($content)) { continue }

        $lines = @(Get-Content -Path $f -ErrorAction SilentlyContinue)
        if ($lines.Count -eq 0) { continue }

        # Pattern A: Invoke-UseCase_* functions with their metadata
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            if ($line -match '^function Invoke-UseCase_(\w+)') {
                $ucName = $matches[1]
                $capability = ''
                $engine = ''
                $provider = ''
                $inputParams = @()

                # Scan from this line forward to extract metadata
                $j = $i
                $braceDepth = 0
                while ($j -lt $lines.Count) {
                    $l = $lines[$j].Trim()
                    if ($l -match "'(capability\.[\w\.]+)'") { $capability = $matches[1] }
                    if ($l -match 'Engine\s*=\s*''(\w+)Engine''') { $engine = "$($matches[1])Engine" }
                    if ($l -match 'Engine\s*=\s*''(\w+)''') { $engine = $matches[1] }
                    if ($l -match 'Provider\s*=\s*''(\w+)Provider''') { $provider = "$($matches[1])Provider" }
                    if ($l -match 'Provider\s*=\s*''(\w+)''') { $provider = $matches[1] }
                    if ($l -match 'Input parameter\s+["''](\w+)["'']') { $inputParams += $matches[1] }

                    if ($l -eq '{') { $braceDepth++ }
                    if ($l -eq '}') {
                        $braceDepth--
                        if ($braceDepth -lt 0) { break }
                    }

                    # Stop at next function definition
                    if ($braceDepth -eq 0 -and $j -gt $i -and $l -match '^function ') { break }
                    $j++
                }

                if (-not [string]::IsNullOrEmpty($ucName) -and -not $useCaseNames.ContainsKey($ucName)) {
                    $useCaseNames[$ucName] = $true
                    $catVal = ''
                    if ($ucName -match '^(\w+)') { $catVal = $matches[1] } else { $catVal = 'General' }
                    $inputArr = @($inputParams)
                    $null = $useCases.Add([pscustomobject]@{
                        Name       = $ucName
                        Capability = $capability
                        Engine     = $engine
                        Provider   = $provider
                        Status     = 'Registered'
                        Priority   = 'Normal'
                        Category   = $catVal
                        Dependencies = @()
                        Input      = $inputArr
                        Output     = @()
                        SourceFile = $f
                    })
                }
            }
        }

        # Pattern B: New-*UseCase factory functions (Id, Name, Capability, EngineType, ProviderType)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            if ($line -match '^function New-(\w+)UseCase\b') {
                $baseName = $matches[1]
                $ucName = "${baseName}UseCase"
                $cap = ''
                $eng = ''
                $prov = ''
                $status = 'Registered'
                $ucId = ''

                $j = $i + 1
                while ($j -lt $lines.Count) {
                    $l = $lines[$j].Trim()
                    if ($l -match "Capability\s*=\s*'(.+?)'") { $cap = $matches[1] }
                    if ($l -match "EngineType\s*=\s*'(.+?)'") { $eng = "$($matches[1])Engine" }
                    if ($l -match "ProviderType\s*=\s*'(.+?)'") { $prov = "$($matches[1])Provider" }
                    if ($l -match "Status\s*=\s*'(.+?)'") { $status = $matches[1] }
                    if ($l -match "Id\s*=\s*'(.+?)'") { $ucId = $matches[1] }

                    if ($l -eq '}') { break }
                    $j++
                }

                if (-not [string]::IsNullOrEmpty($ucName) -and -not $useCaseNames.ContainsKey($ucName)) {
                    $useCaseNames[$ucName] = $true
                    $null = $useCases.Add([pscustomobject]@{
                        Name       = $ucName
                        Capability = $cap
                        Engine     = $eng
                        Provider   = $prov
                        Status     = $status
                        Priority   = 'Normal'
                        Category   = $baseName
                        Dependencies = @()
                        Input      = @()
                        Output     = @()
                        SourceFile = $f
                    })
                }
            }
        }
    }

    # Pattern C: Also detect use cases from .usecase.ps1 file names
    $usecaseFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter *.usecase.ps1 -File -ErrorAction SilentlyContinue
    foreach ($ucFile in $usecaseFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($ucFile.FullName)
        $ucName = $baseName -replace '\.usecase$', ''
        if (-not $useCaseNames.ContainsKey($ucName)) {
            $useCaseNames[$ucName] = $true

            # Try to extract capabilities from file content
            $ucContent = Get-Content -Path $ucFile.FullName -Raw -ErrorAction SilentlyContinue
            $caps = @()
            if ($ucContent) {
                # Extract all capability.xxx.yyy patterns
                $capMatches = [regex]::Matches($ucContent, "'(capability\.[\w\.]+)'")
                foreach ($m in $capMatches) {
                    $caps += $m.Groups[1].Value
                }
                # Also extract from -CapabilityName 'xxx' patterns
                $nameMatches = [regex]::Matches($ucContent, "-CapabilityName\s+'(.+?)'")
                foreach ($m in $nameMatches) {
                    $capName = $m.Groups[1].Value
                    if ($caps -notcontains $capName) { $caps += $capName }
                }
            }

            $capVal = ''
            if ($caps.Count -gt 0) { $capVal = $caps[0] }
            $catVal = $ucName -replace '([a-z])([A-Z])', '$1 '
            $emptyArr = @()
            $null = $useCases.Add([pscustomobject]@{
                Name        = $ucName
                Capability  = $capVal
                Engine      = ''
                Provider    = ''
                Status      = 'Registered'
                Priority    = 'Normal'
                Category    = $catVal
                Dependencies = $emptyArr
                Input       = $emptyArr
                Output      = $emptyArr
                SourceFile  = $ucFile.FullName
            })
        }
    }

    Write-Host "       Found $($useCases.Count) Use Cases." -ForegroundColor Gray

    # ---- STEP 3: Extract Capabilities -----------------------------------------
    Write-Host "[STEP 3/5] Extracting Capabilities..." -ForegroundColor Green
    $capabilities = [System.Collections.ArrayList]@()
    $capabilityNames = @{}

    foreach ($f in $files) {
        $content = $fileContent[$f]
        if ([string]::IsNullOrEmpty($content)) { continue }

        # Pattern 1: capability.xxx.yyy from string literals
        $capMatches = [regex]::Matches($content, "'(capability\.[\w\.]+)'")
        foreach ($m in $capMatches) {
            $capName = $m.Groups[1].Value
            if (-not $capabilityNames.ContainsKey($capName)) {
                $capabilityNames[$capName] = $true
                $null = $capabilities.Add([pscustomobject]@{
                    Name         = $capName
                    UseCase      = ''
                    Engine       = ''
                    Provider     = ''
                    Status       = 'Registered'
                    SourceFile   = $f
                })
            }
        }
    }

    # Pattern 2: Direct registration calls (Register-Capability with -CapabilityName)
    foreach ($f in $files) {
        $lines = @(Get-Content -Path $f -ErrorAction SilentlyContinue)
        if ($lines.Count -eq 0) { continue }

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            if ($line -match "Register-Capability\b") {
                $j = $i
                $capName2 = ''
                while ($j -le $i + 10 -and $j -lt $lines.Count) {
                    if ($lines[$j] -match "-CapabilityName\s+'(.+?)'") {
                        $capName2 = $matches[1]
                        break
                    }
                    $j++
                }
                if (-not [string]::IsNullOrEmpty($capName2) -and -not $capabilityNames.ContainsKey($capName2)) {
                    $capabilityNames[$capName2] = $true
                    $null = $capabilities.Add([pscustomobject]@{
                        Name         = $capName2
                        UseCase      = ''
                        Engine       = ''
                        Provider     = ''
                        Status       = 'Registered'
                        SourceFile   = $f
                    })
                }
            }
        }
    }

    Write-Host "       Found $($capabilities.Count) Capabilities." -ForegroundColor Gray

    # ---- STEP 4: Extract Providers and Engines --------------------------------
    Write-Host "[STEP 4/5] Extracting Providers and Engines..." -ForegroundColor Green

    $providers = [System.Collections.ArrayList]@()
    $providerNames = @{}
    $engines = [System.Collections.ArrayList]@()
    $engineNames = @{}

    foreach ($f in $files) {
        $content = $fileContent[$f]
        if ([string]::IsNullOrEmpty($content)) { continue }

        # Pattern: Provider = 'XxxProvider'
        $provMatches = [regex]::Matches($content, "Provider\s*=\s*'(\w+)Provider'")
        foreach ($m in $provMatches) {
            $provName = "$($m.Groups[1].Value)Provider"
            if (-not $providerNames.ContainsKey($provName)) {
                $providerNames[$provName] = $true
                $null = $providers.Add([pscustomobject]@{
                    Name       = $provName
                    Type       = $m.Groups[1].Value
                    Status     = 'Available'
                    SourceFile = $f
                })
            }
        }

        # Pattern: ProviderType = 'Xxx'
        $provTypeMatches = [regex]::Matches($content, "ProviderType\s*=\s*'(\w+)'")
        foreach ($m in $provTypeMatches) {
            $provName = "$($m.Groups[1].Value)Provider"
            if (-not $providerNames.ContainsKey($provName)) {
                $providerNames[$provName] = $true
                $null = $providers.Add([pscustomobject]@{
                    Name       = $provName
                    Type       = $m.Groups[1].Value
                    Status     = 'Available'
                    SourceFile = $f
                })
            }
        }

        # Pattern: Engine = 'XxxEngine'
        $engMatches = [regex]::Matches($content, "Engine\s*=\s*'(\w+)Engine'")
        foreach ($m in $engMatches) {
            $engName = "$($m.Groups[1].Value)Engine"
            if (-not $engineNames.ContainsKey($engName)) {
                $engineNames[$engName] = $true
                $null = $engines.Add([pscustomobject]@{
                    Name       = $engName
                    Type       = $m.Groups[1].Value
                    Status     = 'Available'
                    SourceFile = $f
                })
            }
        }

        # Pattern: EngineType = 'Xxx'
        $engTypeMatches = [regex]::Matches($content, "EngineType\s*=\s*'(\w+)'")
        foreach ($m in $engTypeMatches) {
            $engName = "$($m.Groups[1].Value)Engine"
            if (-not $engineNames.ContainsKey($engName)) {
                $engineNames[$engName] = $true
                $null = $engines.Add([pscustomobject]@{
                    Name       = $engName
                    Type       = $m.Groups[1].Value
                    Status     = 'Available'
                    SourceFile = $f
                })
            }
        }
    }

    Write-Host "       Found $($providers.Count) Providers." -ForegroundColor Gray
    Write-Host "       Found $($engines.Count) Engines." -ForegroundColor Gray

    # ---- Enrich capabilities with Engine/Provider mappings from CapabilityRegistrar -
    $registrarFile = Join-Path -Path $ProjectRoot -ChildPath 'motor/kernel/Capabilities/CapabilityRegistrar.ps1'
    if (Test-Path -Path $registrarFile) {
        $regContent = Get-Content -Path $registrarFile -Raw -ErrorAction SilentlyContinue
        if ($regContent) {
            # Parse capability blocks: 'capability.xxx.yyy' = @{ Engine = 'Xxx', Provider = 'Xxx' }
            $blockMatches = [regex]::Matches($regContent, "'([\w\.]+)'\s*=\s*@\{[\s\S]*?Engine\s*=\s*'(\w+)'[\s\S]*?Provider\s*=\s*'(\w+)'")
            foreach ($m in $blockMatches) {
                $capName = $m.Groups[1].Value
                $engineName = $m.Groups[2].Value
                $providerName = $m.Groups[3].Value

                # Update capability records with engine/provider
                foreach ($cap in $capabilities) {
                    if ($cap.Name -eq $capName) {
                        $cap.Engine = $engineName
                        $cap.Provider = $providerName
                    }
                }
                # Update use cases with capability
                foreach ($uc in $useCases) {
                    if ($uc.Capability -eq $capName) {
                        $uc.Engine = $engineName
                        $uc.Provider = $providerName
                    }
                }
            }
        }
    }

    # ---- Also link capabilities to use cases based on matching ----
    foreach ($uc in $useCases) {
        if (-not [string]::IsNullOrEmpty($uc.Capability)) {
            foreach ($cap in $capabilities) {
                if ($cap.Name -eq $uc.Capability) {
                    $cap.UseCase = $uc.Name
                    if ([string]::IsNullOrEmpty($cap.Engine)) { $cap.Engine = $uc.Engine }
                    if ([string]::IsNullOrEmpty($cap.Provider)) { $cap.Provider = $uc.Provider }
                }
            }
        }
    }

    # ---- STEP 5: Persist to SQLite --------------------------------------------
    Write-Host "[STEP 5/5] Persisting catalog to SQLite..." -ForegroundColor Green

    # Load HermesPersistence module
    $persistenceModulePath = Join-Path -Path $ProjectRoot -ChildPath 'motor/persistence/HermesPersistence.psm1'
    if (-not (Test-Path -Path $persistenceModulePath)) {
        Write-Warning "HermesPersistence module not found at: $persistenceModulePath"
        Write-Warning "Catalog will be returned as objects without persistence."
        return [pscustomobject]@{
            AuditTimestamp = [datetime]::UtcNow.ToString('o')
            ProjectRoot    = $ProjectRoot
            UseCases       = @($useCases)
            Capabilities   = @($capabilities)
            Providers      = @($providers)
            Engines        = @($engines)
            Persisted      = $false
        }
    }

    try {
        Import-Module -Name $persistenceModulePath -Force -ErrorAction Stop
        Write-Host "       HermesPersistence module loaded." -ForegroundColor Gray
    }
    catch {
        Write-Warning "Could not load HermesPersistence module: $_"
        return [pscustomobject]@{
            AuditTimestamp = [datetime]::UtcNow.ToString('o')
            ProjectRoot    = $ProjectRoot
            UseCases       = @($useCases)
            Capabilities   = @($capabilities)
            Providers      = @($providers)
            Engines        = @($engines)
            Persisted      = $false
        }
    }

    # Ensure database directory exists
    $dbDir = Split-Path -Path $resolvedDbPath -Parent
    if (-not (Test-Path -Path $dbDir)) {
        New-Item -Path $dbDir -ItemType Directory -Force | Out-Null
    }

    $manager = New-HermesDatabaseManager -DatabasePath $resolvedDbPath
    try {
        Connect-HermesDatabase -Manager $manager
        Write-Host "       Connected to SQLite database." -ForegroundColor Gray

        # Initialize standard schema
        $null = Initialize-HermesSchema -Manager $manager

        # Create catalog tables
        $createTables = @(
            "CREATE TABLE IF NOT EXISTS UseCaseCatalog (
                Id TEXT PRIMARY KEY,
                Name TEXT NOT NULL,
                DisplayName TEXT NOT NULL DEFAULT '',
                Category TEXT NOT NULL DEFAULT 'General',
                Priority TEXT NOT NULL DEFAULT 'Normal',
                Status TEXT NOT NULL DEFAULT 'Registered',
                Capability TEXT NOT NULL DEFAULT '',
                Engine TEXT NOT NULL DEFAULT '',
                Provider TEXT NOT NULL DEFAULT '',
                Dependencies TEXT NOT NULL DEFAULT '[]',
                InputParameters TEXT NOT NULL DEFAULT '[]',
                OutputParameters TEXT NOT NULL DEFAULT '[]',
                SourceFile TEXT NOT NULL DEFAULT '',
                AuditVersion INTEGER NOT NULL DEFAULT 1,
                CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),
                UpdatedAt TEXT NOT NULL DEFAULT (datetime('now'))
            )",
            "CREATE TABLE IF NOT EXISTS CapabilityCatalog (
                Id TEXT PRIMARY KEY,
                Name TEXT NOT NULL UNIQUE,
                DisplayName TEXT NOT NULL DEFAULT '',
                UseCase TEXT NOT NULL DEFAULT '',
                Engine TEXT NOT NULL DEFAULT '',
                Provider TEXT NOT NULL DEFAULT '',
                Status TEXT NOT NULL DEFAULT 'Registered',
                SourceFile TEXT NOT NULL DEFAULT '',
                AuditVersion INTEGER NOT NULL DEFAULT 1,
                CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),
                UpdatedAt TEXT NOT NULL DEFAULT (datetime('now'))
            )",
            "CREATE TABLE IF NOT EXISTS ProviderCatalog (
                Id TEXT PRIMARY KEY,
                Name TEXT NOT NULL UNIQUE,
                ProviderType TEXT NOT NULL DEFAULT 'Local',
                Status TEXT NOT NULL DEFAULT 'Available',
                SourceFile TEXT NOT NULL DEFAULT '',
                AuditVersion INTEGER NOT NULL DEFAULT 1,
                CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),
                UpdatedAt TEXT NOT NULL DEFAULT (datetime('now'))
            )",
            "CREATE TABLE IF NOT EXISTS EngineCatalog (
                Id TEXT PRIMARY KEY,
                Name TEXT NOT NULL UNIQUE,
                EngineType TEXT NOT NULL DEFAULT 'Standard',
                Status TEXT NOT NULL DEFAULT 'Available',
                SourceFile TEXT NOT NULL DEFAULT '',
                AuditVersion INTEGER NOT NULL DEFAULT 1,
                CreatedAt TEXT NOT NULL DEFAULT (datetime('now')),
                UpdatedAt TEXT NOT NULL DEFAULT (datetime('now'))
            )",
            "CREATE TABLE IF NOT EXISTS AuditMetadata (
                Id TEXT PRIMARY KEY,
                AuditType TEXT NOT NULL,
                EntityCount INTEGER NOT NULL DEFAULT 0,
                AuditVersion INTEGER NOT NULL DEFAULT 1,
                CreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
            )"
        )
        foreach ($sql in $createTables) {
            $null = Invoke-HermesSql -Manager $manager -Sql $sql -Mode NonQuery
        }

        # Persist Use Cases
        Write-Host "       Persisting $($useCases.Count) Use Cases..." -ForegroundColor Gray
        $ucInserted = 0
        foreach ($uc in $useCases) {
            $ucId = "uc-" + ($uc.Name.ToLower() -replace '[^a-z0-9]', '-')
            try {
                $params = @{
                    '@Id' = $ucId
                    '@Name' = $uc.Name
                    '@DisplayName' = ($uc.Name -replace '([a-z])([A-Z])', '$1 $2')
                    '@Category' = if ($uc.Category -ne '') { $uc.Category } else { 'General' }
                    '@Priority' = $uc.Priority
                    '@Status' = $uc.Status
                    '@Capability' = $uc.Capability
                    '@Engine' = $uc.Engine
                    '@Provider' = $uc.Provider
                    '@Dependencies' = '[]'
                    '@InputParameters' = if ($uc.Input -and $uc.Input.Count -gt 0) { ($uc.Input | ConvertTo-Json -Compress) } else { '[]' }
                    '@OutputParameters' = '[]'
                    '@SourceFile' = $uc.SourceFile
                }
                $null = Invoke-HermesSql -Manager $manager -Sql @"
INSERT OR REPLACE INTO UseCaseCatalog
    (Id, Name, DisplayName, Category, Priority, Status, Capability, Engine, Provider, Dependencies, InputParameters, OutputParameters, SourceFile)
VALUES
    ('$($params['@Id'])', '$($params['@Name'])', '$($params['@DisplayName'])', '$($params['@Category'])', '$($params['@Priority'])', '$($params['@Status'])', '$($params['@Capability'])', '$($params['@Engine'])', '$($params['@Provider'])', '$($params['@Dependencies'])', '$($params['@InputParameters'])', '$($params['@OutputParameters'])', '$($params['@SourceFile'])')
"@ -Mode NonQuery
                $ucInserted++
            }
            catch {
                Write-Warning "Failed to insert use case '$($uc.Name)': $_"
            }
        }

        # Persist Capabilities
        Write-Host "       Persisting $($capabilities.Count) Capabilities..." -ForegroundColor Gray
        $capInserted = 0
        foreach ($cap in $capabilities) {
            $capId = "cap-" + ($cap.Name.ToLower() -replace '\.', '-')
            try {
                $dName = $cap.Name -replace 'capability\.', '' -replace '\.', ' '
                $ucName = $cap.UseCase
                $engName = $cap.Engine
                $provName = $cap.Provider
                $status = $cap.Status
                $src = $cap.SourceFile
                $null = Invoke-HermesSql -Manager $manager -Sql @"
INSERT OR REPLACE INTO CapabilityCatalog
    (Id, Name, DisplayName, UseCase, Engine, Provider, Status, SourceFile)
VALUES
    ('$capId', '$($cap.Name)', '$dName', '$ucName', '$engName', '$provName', '$status', '$src')
"@ -Mode NonQuery
                $capInserted++
            }
            catch {
                Write-Warning "Failed to insert capability '$($cap.Name)': $_"
            }
        }

        # Persist Providers
        Write-Host "       Persisting $($providers.Count) Providers..." -ForegroundColor Gray
        $provInserted = 0
        foreach ($prov in $providers) {
            $provId = "prov-" + ($prov.Name.ToLower() -replace '[^a-z0-9]', '-')
            try {
                $pName = $prov.Name
                $pType = $prov.Type
                $pStatus = $prov.Status
                $pSrc = $prov.SourceFile
                $null = Invoke-HermesSql -Manager $manager -Sql @"
INSERT OR REPLACE INTO ProviderCatalog
    (Id, Name, ProviderType, Status, SourceFile)
VALUES
    ('$provId', '$pName', '$pType', '$pStatus', '$pSrc')
"@ -Mode NonQuery
                $provInserted++
            }
            catch {
                Write-Warning "Failed to insert provider '$($prov.Name)': $_"
            }
        }

        # Persist Engines
        Write-Host "       Persisting $($engines.Count) Engines..." -ForegroundColor Gray
        $engInserted = 0
        foreach ($eng in $engines) {
            $engId = "eng-" + ($eng.Name.ToLower() -replace '[^a-z0-9]', '-')
            try {
                $eName = $eng.Name
                $eType = $eng.Type
                $eStatus = $eng.Status
                $eSrc = $eng.SourceFile
                $null = Invoke-HermesSql -Manager $manager -Sql @"
INSERT OR REPLACE INTO EngineCatalog
    (Id, Name, EngineType, Status, SourceFile)
VALUES
    ('$engId', '$eName', '$eType', '$eStatus', '$eSrc')
"@ -Mode NonQuery
                $engInserted++
            }
            catch {
                Write-Warning "Failed to insert engine '$($eng.Name)': $_"
            }
        }

        # Record Audit Metadata
        $auditId = "audit-$(Get-Date -Format 'yyyyMMddHHmmss')"
        $totalCount = $useCases.Count + $capabilities.Count + $providers.Count + $engines.Count
        $null = Invoke-HermesSql -Manager $manager -Sql @"
INSERT OR REPLACE INTO AuditMetadata (Id, AuditType, EntityCount, AuditVersion)
VALUES ('$auditId', 'UseCaseCatalog', $totalCount, 1)
"@ -Mode NonQuery

        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host "                   AUDIT RESULTS SUMMARY" -ForegroundColor Cyan
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host "  Use Cases    : $($useCases.Count) discovered, $ucInserted persisted" -ForegroundColor White
        Write-Host "  Capabilities : $($capabilities.Count) discovered, $capInserted persisted" -ForegroundColor White
        Write-Host "  Providers    : $($providers.Count) discovered, $provInserted persisted" -ForegroundColor White
        Write-Host "  Engines      : $($engines.Count) discovered, $engInserted persisted" -ForegroundColor White
        Write-Host "  Database     : $resolvedDbPath" -ForegroundColor White
        Write-Host "  Audit ID     : $auditId" -ForegroundColor White
        Write-Host "================================================================" -ForegroundColor Cyan

        # Return catalog result
        return [pscustomobject]@{
            AuditTimestamp   = [datetime]::UtcNow.ToString('o')
            AuditId          = $auditId
            ProjectRoot      = $ProjectRoot
            DatabasePath     = $resolvedDbPath
            UseCases         = @($useCases)
            Capabilities     = @($capabilities)
            Providers        = @($providers)
            Engines          = @($engines)
            UseCaseCount     = $useCases.Count
            CapabilityCount  = $capabilities.Count
            ProviderCount    = $providers.Count
            EngineCount      = $engines.Count
            UseCasePersisted = $ucInserted
            CapabilityPersisted = $capInserted
            ProviderPersisted   = $provInserted
            EnginePersisted     = $engInserted
            Persisted        = $true
            AuditVersion     = 1
        }
    }
    catch {
        Write-Error "Persistence error: $_"
        throw
    }
    finally {
        if ($manager -and $manager.IsConnected) {
            Disconnect-HermesDatabase -Manager $manager
            Write-Host "       Database connection closed." -ForegroundColor Gray
        }
    }
}

# ---- Main Execution ---------------------------------------------------------
# Parse script-level parameters and invoke the audit function
$scriptDbPath = $null
$scriptForce = $false
if ($args.Count -ge 1) {
    for ($i = 0; $i -lt $args.Count; $i++) {
        if ($args[$i] -eq '-DatabasePath' -and ($i + 1) -lt $args.Count) {
            $scriptDbPath = $args[$i + 1]; $i++
        }
        elseif ($args[$i] -eq '-Force') {
            $scriptForce = $true
        }
    }
}
# Also check if there's a $DatabasePath variable defined at script scope
$scriptDbPath = if ([string]::IsNullOrEmpty($scriptDbPath)) { $null } else { $scriptDbPath }
$projectRoot = (Get-Location).Path
Invoke-UseCaseCatalogAudit -ProjectRoot $projectRoot -DatabasePath $scriptDbPath -Force:$scriptForce

