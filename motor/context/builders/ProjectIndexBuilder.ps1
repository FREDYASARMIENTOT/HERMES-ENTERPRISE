# ProjectIndexBuilder.ps1
# Genera PROJECT_INDEX.json - indice maestro del repositorio

function Build-ProjectIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    $modules = @()

    # Escanear motor/bootstrap
    $bootstrapPath = Join-Path $ProjectRoot "motor\bootstrap\engine"
    if (Test-Path $bootstrapPath) {
        $bootstrapFiles = Get-ChildItem $bootstrapPath -Filter "*.ps1" -Recurse
        foreach ($file in $bootstrapFiles) {
            $modules += @{
                name = $file.BaseName
                path = $file.FullName.Replace($ProjectRoot, "").TrimStart("\")
                type = "bootstrap"
                priority = "high"
                isPublic = $true
                description = Extract-Description $file.FullName
            }
        }
    }
    
    # Escanear motor/context (si existe)
    $contextPath = Join-Path $ProjectRoot "motor\context"
    if (Test-Path $contextPath) {
        $contextFiles = Get-ChildItem $contextPath -Filter "*.ps1" -Recurse
        foreach ($file in $contextFiles) {
            $modules += @{
                name = $file.BaseName
                path = $file.FullName.Replace($ProjectRoot, "").TrimStart("\")
                type = "context"
                priority = "high"
                isPublic = $true
                description = Extract-Description $file.FullName
            }
        }
    }
    
    # Obtener documentacion
    $docPath = Join-Path $ProjectRoot "documentacion"
    $documentation = @()
    if (Test-Path $docPath) {
        $docFiles = Get-ChildItem $docPath -Filter "*.md" -Recurse
        foreach ($file in $docFiles) {
            $documentation += @{
                title = Extract-Title $file.FullName
                path = $file.FullName.Replace($ProjectRoot, "").TrimStart("\")
                type = "design"
                lastModified = $file.LastWriteTime.ToString("yyyy-MM-dd")
            }
        }
    }
    
    # Obtener pruebas
    $testPath = Join-Path $ProjectRoot "pruebas\unitarias"
    $tests = @()
    if (Test-Path $testPath) {
        $testFiles = Get-ChildItem $testPath -Filter "Test-*.ps1" -Recurse
        foreach ($file in $testFiles) {
            $tests += @{
                name = $file.BaseName
                path = $file.FullName.Replace($ProjectRoot, "").TrimStart("\")
                testsModule = ($file.BaseName -replace "^Test-", "")
                status = "exists"
            }
        }
    }
    
    # Configuracion
    $configPath = Join-Path $ProjectRoot "configuracion\bootstrap.enterprise.json"
    $config = @()
    if (Test-Path $configPath) {
        $config += @{
            name = "bootstrap.enterprise.json"
            path = "configuracion\bootstrap.enterprise.json"
            type = "config"
            description = "Configuracion global del Bootstrap Engine"
        }
    }
    
    # Construir indice completo
    $index = [PSCustomObject]@{
        schemaVersion = "1.0"
        generatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        generator = "ProjectIndexBuilder"
        
        project = @{
            name = "HERMES-ENTERPRISE"
            root = $ProjectRoot
            version = Get-ProjectVersion $ProjectRoot
        }
        
        modules = $modules
        documentation = $documentation
        tests = $tests
        configuration = $config
        
        criticalComponents = @{
            bootstrap = @("BootstrapState", "BootstrapWizard", "EnvironmentManager", "ContextEngine")
            context = @("ContextEngine", "ContextValidator", "ProjectIndexBuilder", "ManifestBuilder")
        }
        
        publicFiles = ($modules | Where-Object { $_.isPublic -eq $true } | Select-Object -ExpandProperty path)
        internalFiles = @()
        
        priorities = @{
            high = @("ContextEngine", "BootstrapState", "BootstrapWizard")
            medium = @("NextTaskBuilder", "SummaryBuilder", "WorkerContextBuilder")
            low = @("templates", "schemas")
        }
        
        dependencies = @{
            ContextEngine = @("ContextValidator", "ProjectIndexBuilder", "ManifestBuilder", "CurrentStateBuilder", "NextTaskBuilder", "WorkerContextBuilder", "SummaryBuilder")
            BootstrapWizard = @("BootstrapState")
            EnvironmentManager = @()
        }
    }
    
    # Escribir JSON
    $jsonPath = Join-Path $OutputPath "PROJECT_INDEX.json"
    $index | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8
    
    return $jsonPath
}

function Extract-Description {
    param([string]$filePath)
    
    $content = Get-Content $filePath -Raw
    if ($content -match "\.SYNOPSIS\s*\n(.+?)(?:\n\.DESCRIPTION|\n\Z|\n\n)") {
        return $matches[1].Trim()
    }
    return "Modulo PowerShell HERMES Enterprise"
}

function Extract-Title {
    param([string]$filePath)
    
    $content = Get-Content $filePath -First 10
    if ($content -match "^# (.+)") {
        return $matches[1].Trim()
    }
    return [System.IO.Path]::GetFileNameWithoutExtension($filePath)
}

function Get-ProjectVersion {
    param([string]$projectRoot)
    
    $statePath = Join-Path $projectRoot ".hermes\bootstrap\CURRENT_STATE.md"
    if (Test-Path $statePath) {
        $content = Get-Content $statePath -Raw
        if ($content -match "^version:\s*(.+)") {
            return $matches[1].Trim()
        }
    }
    return "0.1.0"
}
