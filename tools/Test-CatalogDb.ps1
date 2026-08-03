<#
.SYNOPSIS
    Tests the Use Case Catalog SQLite database directly using HermesSQLiteProvider.
#>
param(
    [string]$DatabasePath = "data/hermes_test.db"
)

function Write-Color {
    param([string]$Text, [string]$Color = 'White')
    Write-Host $Text -ForegroundColor $Color
}

Add-Type -Path "lib/HermesSQLiteProvider.dll" -ErrorAction Stop

$conn = New-Object -TypeName HermesSQLiteProvider.SQLiteConnection -ArgumentList $DatabasePath
$conn.Open()
Write-Color "Connected to: $DatabasePath" Cyan

$cmd = $conn.CreateCommand()

# Test UseCaseCatalog
$cmd.CommandText = "SELECT Name, Capability, Engine, Provider FROM UseCaseCatalog ORDER BY Name"
$r = $cmd.ExecuteReader()
Write-Color "`n=== USE CASE CATALOG ===" Green
while ($r.Read()) {
    Write-Host ("  {0,-30} {1,-35} {2,-18} {3}" -f $r['Name'], $r['Capability'], $r['Engine'], $r['Provider'])
}
$r.Close()

# Test CapabilityCatalog
$cmd.CommandText = "SELECT COUNT(*) FROM CapabilityCatalog"
$r = $cmd.ExecuteReader()
$r.Read() | Out-Null
Write-Color "`nCapabilities: $($r[0])" Yellow
$r.Close()

$cmd.CommandText = "SELECT Name, Engine, Provider FROM CapabilityCatalog ORDER BY Name"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Host ("  {0,-40} {1,-18} {2}" -f $r['Name'], $r['Engine'], $r['Provider'])
}
$r.Close()

# Test ProviderCatalog
$cmd.CommandText = "SELECT COUNT(*) FROM ProviderCatalog"
$r = $cmd.ExecuteReader()
$r.Read() | Out-Null
Write-Color "`nProviders: $($r[0])" Yellow
$r.Close()

$cmd.CommandText = "SELECT Name FROM ProviderCatalog ORDER BY Name"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Host ("  {0}" -f $r['Name'])
}
$r.Close()

# Test EngineCatalog
$cmd.CommandText = "SELECT COUNT(*) FROM EngineCatalog"
$r = $cmd.ExecuteReader()
$r.Read() | Out-Null
Write-Color "`nEngines: $($r[0])" Yellow
$r.Close()

$cmd.CommandText = "SELECT Name FROM EngineCatalog ORDER BY Name"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Host ("  {0}" -f $r['Name'])
}
$r.Close()

# Test AuditMetadata
$cmd.CommandText = "SELECT Id, AuditType, EntityCount FROM AuditMetadata ORDER BY CreatedAt DESC LIMIT 1"
$r = $cmd.ExecuteReader()
if ($r.Read()) {
    Write-Color "`n=== AUDIT METADATA ===" Green
    Write-Host ("  Audit ID: {0}" -f $r['Id'])
    Write-Host ("  Type: {0}" -f $r['AuditType'])
    Write-Host ("  Entities: {0}" -f $r['EntityCount'])
}
$r.Close()

$conn.Close()
Write-Color "`nDatabase connection closed." Cyan