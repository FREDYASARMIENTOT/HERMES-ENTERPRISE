Param(
    [Parameter(Mandatory=$true)][psobject]$ConfigObject
)
function Log { param($level,$msg) Write-Host "[$level] $msg" }
$required = @('project')
foreach ($r in $required) {
    if (-not $ConfigObject.PSObject.Properties.Name -contains $r) { Log ERROR "Missing required config key: $r"; exit 1 }
}
if (-not $ConfigObject.project.name) { Log ERROR "project.name is required"; exit 1 }
Log INFO "Configuration validated"
return $true
