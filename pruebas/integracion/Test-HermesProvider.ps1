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

# PASO 1: Resolver configuracion
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

# PASO 2: Resolver DLL
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
    
    $resolvedDll = if (Test-Path $hermesDllRaw) {
        (Resolve-Path $hermesDllRaw -ErrorAction Stop).Path
    }
    else {
        $hermesDllRaw
    }
    Write-Host ("  Resolved path  : " + $resolvedDll)
    Write-Host ("  Exists         : " + (Test-Path $resolvedDll))
    
    if (-not (Test-Path $resolvedDll)) {
        throw "DLL file does not exist at resolved path: " + $resolvedDll
    }
    
    $dllInfo = Get-Item $resolvedDll
    Write-Host ("  File size      : " + $dllInfo.Length + " bytes")
    Write-Host ("  Last modified  : " + $dllInfo.LastWriteTime)
    
    try {
        $asmName = [System.Reflection.AssemblyName]::GetAssemblyName($resolvedDll)
        Write-Host ("  Assembly Name  : " + $asmName.FullName) -ForegroundColor Green
    }
    catch {
        Write-Host ("  [WARN] Cannot read assembly metadata: " + $_.Exception.Message) -ForegroundColor Yellow
    }
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

# PASO 3: Load Assembly (Add-Type)
Write-Host "PASO 3 - Load Assembly (Add-Type)" -ForegroundColor Yellow
try {
    $alreadyLoaded = $null -ne ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { 
        $_.FullName -like "HermesSQLiteProvider*" -or $_.Location -like "*HermesSQLiteProvider*"
    })
    Write-Host ("  Already loaded? : " + $alreadyLoaded)
    
    if (-not $alreadyLoaded) {
        Write-Host ("  Loading via Add-Type -Path " + $resolvedDll + " ...")
        Add-Type -Path $resolvedDll -ErrorAction Stop
        Write-Host "  Add-Type succeeded!" -ForegroundColor Green
    }
    else {
        Write-Host "  Assembly already loaded, skipping Add-Type" -ForegroundColor Green
    }
    
    $loadedAsm = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { 
        $_.FullName -like "HermesSQLiteProvider*" -or $_.Location -like "*HermesSQLiteProvider*"
    }
    if ($loadedAsm) {
        Write-Host ("  Assembly verified in AppDomain: " + $loadedAsm.FullName) -ForegroundColor Green
    }
    else {
        Write-Host "  [WARN] Assembly not found in AppDomain after load" -ForegroundColor Yellow
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
    if ($_.Exception -is [System.IO.FileNotFoundException]) {
        Write-Host ("  FusionLog       : " + $_.Exception.FusionLog) -ForegroundColor Red
    }
    throw "PASO 3 FAILED: Add-Type failed for " + $resolvedDll
}
Write-Host ""

# PASO 4: GetType
Write-Host "PASO 4 - GetType Hermes.Data.SQLite.HermesSQLiteConnection" -ForegroundColor Yellow
try {
    $typeLoaded = ([System.Management.Automation.PSTypeName]"Hermes.Data.SQLite.HermesSQLiteConnection").Type
    if ($typeLoaded) {
        Write-Host ("  PSTypeName resolution: " + $typeLoaded.FullName) -ForegroundColor Green
        Write-Host ("  Assembly             : " + $typeLoaded.Assembly.FullName) -ForegroundColor Green
    }
    else {
        Write-Host "  PSTypeName resolution FAILED (returned null)" -ForegroundColor Yellow
    }
    
    $asmLoaded = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { 
        $_.FullName -like "HermesSQLiteProvider*"
    }
    if ($asmLoaded) {
        Write-Host "  Direct GetType from assembly..."
        $directType = $asmLoaded.GetType("Hermes.Data.SQLite.HermesSQLiteConnection")
        if ($directType) {
            Write-Host ("  Direct GetType succeeded: " + $directType.FullName) -ForegroundColor Green
        }
        else {
            Write-Host "  Listing all types in assembly:" -ForegroundColor Yellow
            foreach ($t in $asmLoaded.GetExportedTypes()) {
                Write-Host ("    - " + $t.FullName)
            }
            if ($asmLoaded.GetExportedTypes().Count -eq 0) {
                Write-Host "    (No exported types found)" -ForegroundColor Red
                foreach ($t in $asmLoaded.GetTypes()) {
                    Write-Host ("    - " + $t.FullName)
                }
            }
        }
    }
    else {
        Write-Host "  [ERROR] Assembly not found in AppDomain" -ForegroundColor Red
    }
}
catch {
    Write-Host "  [ERROR] Failed to get type" -ForegroundColor Red
    Write-Host ("  Exception type : " + $_.Exception.GetType().FullName) -ForegroundColor Red
    Write-Host ("  Message        : " + $_.Exception.Message) -ForegroundColor Red
    Write-Host ("  InnerException : " + $_.Exception.InnerException) -ForegroundColor Red
    Write-Host ("  StackTrace     : " + $_.Exception.StackTrace) -ForegroundColor Red
    throw "PASO 4 FAILED: Cannot resolve type Hermes.Data.SQLite.HermesSQLiteConnection"
}
Write-Host ""

# PASO 5: Constructor
Write-Host "PASO 5 - New-Object HermesSQLiteConnection" -ForegroundColor Yellow
$connectionString = "Data Source=" + (Join-Path $workspaceRoot "data\test_hermes_provider.db") + ";Version=3;Pooling=True;Max Pool Size=100;"
$conn = $null
try {
    Write-Host ("  ConnectionString: " + $connectionString)
    
    $conn = New-Object Hermes.Data.SQLite.HermesSQLiteConnection($connectionString)
    
    if ($conn) {
        Write-Host "  Constructor succeeded!" -ForegroundColor Green
        Write-Host ("  Connection type : " + $conn.GetType().FullName) -ForegroundColor Green
        Write-Host ("  ConnectionString: " + $conn.ConnectionString) -ForegroundColor Green
        Write-Host ("  State (pre-open): " + $conn.State) -ForegroundColor Green
        Write-Host ("  Timeout         : " + $conn.ConnectionTimeout) -ForegroundColor Green
    }
    else {
        Write-Host "  [ERROR] Constructor returned null" -ForegroundColor Red
        throw "New-Object returned null"
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

# PASO 6: Open Connection
Write-Host "PASO 6 - Open" -ForegroundColor Yellow
try {
    Write-Host "  Attempting conn.Open ..."
    $conn.Open()
    Write-Host "  Open succeeded!" -ForegroundColor Green
    Write-Host ("  State (post-open): " + $conn.State) -ForegroundColor Green
    
    Write-Host "  Testing simple query..."
    $cmd = $conn.CreateCommand()
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
    throw "PASO 6 FAILED: conn.Open failed"
}
finally {
    if ($conn) {
        try {
            if ($conn.State -eq "Open") { $conn.Close() }
            $conn.Dispose()
        }
        catch { }
    }
}
Write-Host ""

Write-Host "All 6 steps completed successfully!" -ForegroundColor Green