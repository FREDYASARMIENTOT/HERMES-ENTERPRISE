Param(
    [Parameter(Mandatory=$true)][string]$ConfigPath
)
function Log { param($level,$msg) Write-Host "[$level] $msg" }
if (-not (Test-Path $ConfigPath)) { Log ERROR "Config file not found: $ConfigPath"; exit 1 }
$ext = [IO.Path]::GetExtension($ConfigPath).ToLower()
switch ($ext) {
    '.json' {
        $raw = Get-Content -Raw -Path $ConfigPath
        try { $obj = $raw | ConvertFrom-Json -ErrorAction Stop } catch { Log ERROR "Invalid JSON: $($_.Exception.Message)"; exit 1 }
    }
    default {
        Log ERROR "Unsupported config format: $ext. Only JSON is allowed for LoadConfiguration."; exit 1
    }
}
# Normalize to PSCustomObject
if ($obj -is [System.Management.Automation.PSCustomObject]) { $normalized = $obj } else { $normalized = [PSCustomObject]$obj }
# Minimal normalization defaults
if (-not $normalized.project) { $normalized | Add-Member -NotePropertyName project -NotePropertyValue (@{ name = 'ProyectoDefault' }) -Force }
if (-not $normalized.github) { $normalized | Add-Member -NotePropertyName github -NotePropertyValue (@{ create = $false; visibility='private'; configure_actions=$false }) -Force }
if (-not $normalized.python) { $normalized | Add-Member -NotePropertyName python -NotePropertyValue (@{ create_venv = $false; install_requirements = $false }) -Force }
if (-not $normalized.vscode) { $normalized | Add-Member -NotePropertyName vscode -NotePropertyValue (@{ open = $false }) -Force }
if (-not $normalized.tests) { $normalized | Add-Member -NotePropertyName tests -NotePropertyValue (@{ run = $false }) -Force }
# Output normalized object
$normalized | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path $env:TEMP 'hermes_config_out.json') -Encoding utf8
Write-Host "[INFO] Configuration loaded and normalized"
return $normalized
