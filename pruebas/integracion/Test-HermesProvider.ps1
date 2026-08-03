<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-HermesProvider.ps1
Proposito: Script de diagnostico minimo para identificar por que HermesSQLiteProvider no carga
====================================================================================================
#>

[CmdletBinding()]
param(
    [string]$DllPath = (Resolve-Path "$PSScriptRoot\..\..\lib\HermesSQLiteProvider.dll" -ErrorAction SilentlyContinue)
)

$ErrorActionPreference = 'Stop'

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   TEST-HERMES PROVIDER - DIAGNOSTICO MINIMO    " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# PASO 0: Environment
Write-Host "PASO 0 - Informacion del Entorno" -ForegroundColor Yellow
Write-Host ("  PowerShell version : " + $PSVersionTable.PSVersion)
Write-Host ("  CLR version        : " + [System.Environment]::Version)
Write-Host ("  OS                 : " + [System.Environment]::OSVersion)
Write-Host ("  Architecture       : " + [System.Environment]::Is64BitProcess)
Write-Host ("  Current directory  : " + (Get-Location))
Write-Host ("  Script root        : " + $PSScriptRoot)
Write-Host ("  DLL path arg       : " + $DllPath)
Write-Host ("  DLL exists         : " + (Test-Path $DllPath))
Write-Host ""

# ── Almacenamos variables que se iran completando paso a paso ──
$script:resolvedDll = $null
$script:asm          = $null
$script:connType     = $null
$script:conn         = $null

# ====================================================================
# PASO 1: Resolver configuracion
# ====================================================================
Write-Host "PASO 1 - Resolver configuracion (persistence.psd1)" -ForegroundColor Yellow
try {
    $configPath = Join-Path $PSScriptRoot "..\..\motor\config\persistence.psd1"
    Write-Host ("  Config path : " + $configPath)
    Write-Host ("  Exists      : " + (Test-Path $configPath))

    $cfg = Import-LocalizedData -BaseDirectory (Split-Path $configPath -Parent) -FileName "persistence.psd1" -ErrorAction Stop
    Write-Host "  Config loaded successfully" -ForegroundColor Green
    Write-Host ("  Provider    : " + $cfg.Provider)
    Write-Host ("  AssemblyPath: " + $cfg.HermesSQLiteProvider.AssemblyPath)
}
catch {
    Write-Host "  [ERROR] Failed to load config" -ForegroundColor Red
    Write-Host ("  Exception type : " + $_.Exception.GetType().FullName) -ForegroundColor Red
    Write-Host ("  Message        : " + $_.Exception.Message) -ForegroundColor Red
    Write-Host ("  InnerException : " + $_.Exception.InnerException) -ForegroundColor Red
    Write-Host ("  StackTrace     : " + $_.Exception.StackTrace) -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host ("  Inner Stack    : " + $_.Exception.InnerException.StackTrace) -ForegroundColor Red
    }
    throw "PASO 1 FAILED: Cannot load persistence.psd1"
}
Write-Host ""

# ====================================================================
# PASO 2: Resolver DLL
# ====================================================================
Write-Host "PASO 2 - Resolver ruta del DLL" -ForegroundColor Yellow
try {
    $workspaceRoot = $env:HERMES_WORKSPACE_ROOT
    if (-not $workspaceRoot) {
        $workspaceRoot = (Resolve-Path "$PSScriptRoot\..\.." -ErrorAction Stop).Path
    }
    Write-Host ("  Workspace Root : " + $workspaceRoot)

    $dllRelPath = $cfg.HermesSQLiteProvider.AssemblyPath
    Write-Host ("  DLL rel path   : " + $dllRelPath)

    $hermesDllRaw = Join-Path $workspaceRoot $dllRelPath
    Write-Host ("  DLL full path  : " + $hermesDllRaw)

    $resolvedPath = if (Test-Path $hermesDllRaw) {
        (Resolve-Path $hermesDllRaw -ErrorAction Stop).Path
    }
    else {
        $hermesDllRaw
    }
    Write-Host ("  Resolved path  : " + $resolvedPath)
    Write-Host ("  Exists         : " + (Test-Path $resolvedPath))

    if (-not (Test-Path $resolvedPath)) {
        throw "DLL file does not exist at resolved path: " + $resolvedPath
    }

    $dllInfo = Get-Item $resolvedPath
    Write-Host ("  File size      : " + $dllInfo.Length + " bytes")
    Write-Host ("  Last modified  : " + $dllInfo.LastWriteTime)

    try {
        $asmName = [System.Reflection.AssemblyName]::GetAssemblyName($resolvedPath)
        Write-Host ("  Assembly Name  : " + $asmName.FullName) -ForegroundColor Green
    }
    catch {
        Write-Host ("  [WARN] Cannot read assembly metadata: " + $_.Exception.Message) -ForegroundColor Yellow
    }

    $script:resolvedDll = $resolvedPath
}
catch {
    Write-Host "  [ERROR] Failed to resolve DLL path" -ForegroundColor Red
    Write-Host ("  Exception type : " + $_.Exception.GetType().FullName) -ForegroundColor Red
    Write-Host ("  Message        : " + $_.Exception.Message) -ForegroundColor Red
    Write-Host ("  InnerException : " + $_.Exception.InnerException) -ForegroundColor Red
    Write-Host ("  StackTrace     : " + $_.Exception.StackTrace) -ForegroundColor Red
    throw "PASO 2 FAILED: Cannot resolve HermesSQLiteProvider.dll"
}
Write-Host ""

# ====================================================================
# PASO 3: Load Assembly (LoadFrom)
# ====================================================================
Write-Host "PASO 3 - Load Assembly (LoadFrom)" -ForegroundColor Yellow
try {
    # Check if already loaded
    $alreadyLoaded = $null -ne ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
        $_.FullName -like "HermesSQLiteProvider*" -or $_.Location -like "*HermesSQLiteProvider*"
    })
    Write-Host ("  Already loaded? : " + $alreadyLoaded)

    if (-not $alreadyLoaded) {
        Write-Host ("  Loading via Assembly.LoadFrom: " + $script:resolvedDll)
        $script:asm = [System.Reflection.Assembly]::LoadFrom($script:resolvedDll)
        Write-Host "  LoadFrom succeeded!" -ForegroundColor Green
    }
    else {
        Write-Host "  Assembly already loaded, retrieving from AppDomain" -ForegroundColor Green
        $script:asm = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
            $_.FullName -like "HermesSQLiteProvider*" -or $_.Location -like "*HermesSQLiteProvider*"
        } | Select-Object -First 1
    }

    if ($script:asm) {
        Write-Host ("  Assembly FullName: " + $script:asm.FullName) -ForegroundColor Green
        Write-Host ("  Location         : " + $script:asm.Location) -ForegroundColor Green
        Write-Host ("  ImageRuntimeVer  : " + $script:asm.ImageRuntimeVersion) -ForegroundColor Green
        Write-Host ("  IsDynamic        : " + $script:asm.IsDynamic) -ForegroundColor Green
    }
    else {
        throw "Assembly object is null after load attempt"
    }
}
catch {
    Write-Host "  [ERROR] Failed to load assembly" -ForegroundColor Red
    Write-Host ("  Exception type  : " + $_.Exception.GetType().FullName) -ForegroundColor Red
    Write-Host ("  Message         : " + $_.Exception.Message) -ForegroundColor Red
    Write-Host ("  InnerException  : " + $_.Exception.InnerException) -ForegroundColor Red
    Write-Host ("  StackTrace      : " + $_.Exception.StackTrace) -ForegroundColor Red

    if ($_.Exception.InnerException) {
        Write-Host ("  Inner Stack     : " + $_.Exception.InnerException.StackTrace) -ForegroundColor Red
    }

    # FusionLog: can be on FileNotFoundException / BadImageFormatException / etc
    $ex = $_.Exception
    while ($ex) {
        if ($ex.GetType().Name -match "FileNotFoundException|BadImageFormatException|FileLoadException") {
            try {
                $fusionLog = $ex.FusionLog
                if (-not [string]::IsNullOrEmpty($fusionLog)) {
                    Write-Host ("  --- FusionLog ---") -ForegroundColor Red
                    Write-Host $fusionLog -ForegroundColor Red
                    Write-Host ("  --- End FusionLog ---") -ForegroundColor Red
                }
            }
            catch {
                Write-Host ("  [FusionLog not accessible on this exception]") -ForegroundColor Yellow
            }
        }
        $ex = $ex.InnerException
    }

    throw "PASO 3 FAILED: LoadFrom failed for " + $script:resolvedDll
}
Write-Host ""

# ====================================================================
# PASO 4: GetType
# ====================================================================
Write-Host "PASO 4 - GetType Hermes.Data.SQLite.HermesSQLiteConnection" -ForegroundColor Yellow
try {
    Write-Host "  Attempting direct GetType from assembly..."
    $script:connType = $script:asm.GetType("Hermes.Data.SQLite.HermesSQLiteConnection")
    if ($script:connType) {
        Write-Host ("  GetType succeeded: " + $script:connType.FullName) -ForegroundColor Green
        Write-Host ("  Assembly          : " + $script:connType.Assembly.FullName) -ForegroundColor Green
        Write-Host ("  IsPublic          : " + $script:connType.IsPublic) -ForegroundColor Green
        Write-Host ("  IsClass           : " + $script:connType.IsClass) -ForegroundColor Green
        Write-Host ("  IsAbstract        : " + $script:connType.IsAbstract) -ForegroundColor Green
    }
    else {
        Write-Host "  GetType returned null - enumerating all types in assembly:" -ForegroundColor Yellow
        $allTypes = $script:asm.GetTypes()
        if ($allTypes.Count -eq 0) {
            Write-Host "    (No types found in assembly!)" -ForegroundColor Red
        }
        else {
            foreach ($t in $allTypes) {
                Write-Host ("    - " + $t.FullName + " (Public=" + $t.IsPublic + ", Class=" + $t.IsClass + ")")
            }
        }
        throw "GetType returned null for 'Hermes.Data.SQLite.HermesSQLiteConnection'"
    }
}
catch {
    Write-Host "  [ERROR] Failed to get type" -ForegroundColor Red
    Write-Host ("  Exception type : " + $_.Exception.GetType().FullName) -ForegroundColor Red
    Write-Host ("  Message        : " + $_.Exception.Message) -ForegroundColor Red
    Write-Host ("  InnerException : " + $_.Exception.InnerException) -ForegroundColor Red
    Write-Host ("  StackTrace     : " + $_.Exception.StackTrace) -ForegroundColor Red

    $ex = $_.Exception
    while ($ex) {
        if ($ex.GetType().Name -match "FileNotFoundException|BadImageFormatException") {
            try { Write-Host ("  FusionLog: " + $ex.FusionLog) -ForegroundColor Red } catch {}
        }
        $ex = $ex.InnerException
    }

    throw "PASO 4 FAILED: Cannot resolve type Hermes.Data.SQLite.HermesSQLiteConnection"
}
Write-Host ""

# ====================================================================
# PASO 5: Constructor
# ====================================================================
Write-Host "PASO 5 - Create instance via Activator.CreateInstance" -ForegroundColor Yellow
$connectionString = "Data Source=" + (Join-Path $workspaceRoot "data\test_hermes_provider.db") + ";Version=3;Pooling=True;Max Pool Size=100;"
try {
    Write-Host ("  ConnectionString: " + $connectionString)

    $script:conn = [Activator]::CreateInstance($script:connType, $connectionString)

    if ($script:conn) {
        Write-Host "  Constructor succeeded!" -ForegroundColor Green
        Write-Host ("  Connection type : " + $script:conn.GetType().FullName) -ForegroundColor Green
        Write-Host ("  ConnectionString: " + $script:conn.ConnectionString) -ForegroundColor Green
        Write-Host ("  State (pre-open): " + $script:conn.State) -ForegroundColor Green
        Write-Host ("  Timeout         : " + $script:conn.ConnectionTimeout) -ForegroundColor Green
    }
    else {
        throw "Activator.CreateInstance returned null"
    }
}
catch {
    Write-Host "  [ERROR] Failed to create connection instance" -ForegroundColor Red
    Write-Host ("  Exception type  : " + $_.Exception.GetType().FullName) -ForegroundColor Red
    Write-Host ("  Message         : " + $_.Exception.Message) -ForegroundColor Red
    Write-Host ("  InnerException  : " + $_.Exception.InnerException) -ForegroundColor Red
    Write-Host ("  StackTrace      : " + $_.Exception.StackTrace) -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host ("  Inner Stack     : " + $_.Exception.InnerException.StackTrace) -ForegroundColor Red
    }
    throw "PASO 5 FAILED: Cannot instantiate HermesSQLiteConnection"
}
Write-Host ""

# ====================================================================
# PASO 6: Open Connection
# ====================================================================
Write-Host "PASO 6 - Open" -ForegroundColor Yellow
try {
    Write-Host "  Attempting conn.Open ..."
    $script:conn.Open()
    Write-Host "  Open succeeded!" -ForegroundColor Green
    Write-Host ("  State (post-open): " + $script:conn.State) -ForegroundColor Green

    Write-Host "  Testing simple query..."
    $cmd = $script:conn.CreateCommand()
    $cmd.CommandText = "SELECT sqlite_version() AS version"
    $reader = $cmd.ExecuteReader()
    if ($reader.Read()) {
        $version = $reader.GetValue(0)
        Write-Host ("  SQLite version  : " + $version) -ForegroundColor Green
    }
    $reader.Close()
    $cmd.Dispose()

    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "   TEST COMPLETED SUCCESSFULLY                  " -ForegroundColor Green
    Write-Host "   HermesSQLiteProvider is fully operational    " -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] Open failed" -ForegroundColor Red
    Write-Host ("  Exception type  : " + $_.Exception.GetType().FullName) -ForegroundColor Red
    Write-Host ("  Message         : " + $_.Exception.Message) -ForegroundColor Red
    Write-Host ("  InnerException  : " + $_.Exception.InnerException) -ForegroundColor Red
    Write-Host ("  StackTrace      : " + $_.Exception.StackTrace) -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host ("  Inner Stack     : " + $_.Exception.InnerException.StackTrace) -ForegroundColor Red
    }

    $ex = $_.Exception
    while ($ex) {
        if ($ex.GetType().Name -match "FileNotFoundException|DllNotFoundException") {
            try { Write-Host ("  FusionLog: " + $ex.FusionLog) -ForegroundColor Red } catch {}
        }
        $ex = $ex.InnerException
    }

    throw "PASO 6 FAILED: conn.Open failed"
}
finally {
    if ($script:conn) {
        try {
            if ($script:conn.State -eq "Open") { $script:conn.Close() }
            $script:conn.Dispose()
        }
        catch {
            Write-Host "  [WARN] Cleanup error: $_" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

Write-Host "All 6 steps completed successfully!" -ForegroundColor Green