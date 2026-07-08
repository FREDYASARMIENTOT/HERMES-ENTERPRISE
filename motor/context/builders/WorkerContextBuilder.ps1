<#
.SYNOPSIS
    WorkerContextBuilder - Genera WORKER_CONTEXT.json como contrato estructurado para Workers
.DESCRIPTION
    Crea un contrato JSON que contiene toda la información necesaria para que
    un Worker pueda ejecutar su tarea: proyecto, versión, fase, componentes,
    paths permitidos/prohibidos, tests requeridos y dependencias.
.BUDGET
    Maximo 250 lineas.
.INPUTS
    - BootstrapState: Estado actual del proyecto
    - ProjectRoot: Ruta raíz del proyecto
    - OutputPath: Ruta donde se generará WORKER_CONTEXT.json
.OUTPUTS
    PSCustomObject con Path, Tokens, IsValid
.EXAMPLE
    $state = Get-BootstrapState
    $result = Build-WorkerContext -BootstrapState $state -ProjectRoot "D:\HERMES-ENTERPRISE" -OutputPath "D:\HERMES-ENTERPRISE\.hermes\context"
#>
function Build-WorkerContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$BootstrapState,
        
        [Parameter(Mandatory)]
        [string]$ProjectRoot,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    # Validar BootstrapState
    if (-not $BootstrapState.ProjectName) {
        throw "BootstrapState debe contener ProjectName"
    }
    
    # Obtener información de Git
    $commitHash = Get-GitCommitHash -ProjectRoot $ProjectRoot
    $branch = Get-GitBranch -ProjectRoot $ProjectRoot
    
    # Construir contexto para Worker
    $context = [PSCustomObject]@{
        contextVersion = 1
        bootstrapVersion = $BootstrapState.BootstrapVersion
        generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        generator = "WorkerContextBuilder"
        
        project = [PSCustomObject]@{
            name = $BootstrapState.ProjectName
            version = $BootstrapState.BootstrapVersion
            phase = "Fase $($BootstrapState.FaseActual)"
            step = "Paso $($BootstrapState.StepActual)"
            commit = $commitHash
            branch = $branch
            workingDirectory = $ProjectRoot
        }
        
        completedModules = if ($BootstrapState.ComponentesCompletados) { 
            $BootstrapState.ComponentesCompletados 
        } else { 
            @() 
        }
        
        pendingModules = if ($BootstrapState.ComponentesPendientes) { 
            $BootstrapState.ComponentesPendientes 
        } else { 
            @() 
        }
        
        paths = [PSCustomObject]@{
            allowed = @(
                "motor\**\*.ps1",
                "pruebas\unitarias\**\*.ps1",
                "documentacion\**\*.md",
                "configuracion\*.json"
            )
            forbidden = @(
                "motor\bootstrap\engine\BootstrapState.ps1",
                "motor\bootstrap\engine\BootstrapWizard.ps1",
                "motor\bootstrap\engine\EnvironmentManager.ps1",
                "motor\kernel\**",
                "motor\sandbox\**",
                "motor\eventos\**",
                "motor\logging\**",
                "motor\plugins\**"
            )
        }
        
        tests = [PSCustomObject]@{
            required = @(
                "Tests unitarios para todos los componentes nuevos",
                "Tests de integración si aplica",
                "Verificación ad-hoc con script temporal"
            )
            coverage = "100% de funciones públicas"
            location = "pruebas\unitarias\"
        }
        
        dependencies = if ($BootstrapState.Dependencias) { 
            $BootstrapState.Dependencias 
        } else { 
            @() 
        }
        
        constraints = @(
            "Mantener KISS/DRY",
            "Seguir patrones establecidos",
            "Presupuestos de líneas por módulo",
            "Limpieza automática de recursos temporales",
            "No modificar componentes existentes"
        )
        
        nextObjective = if ($BootstrapState.ProximoObjetivo) { 
            $BootstrapState.ProximoObjetivo 
        } else { 
            "No definido" 
        }
    }
    
    # Escribir JSON con formato legible
    $filePath = Join-Path $OutputPath "WORKER_CONTEXT.json"
    
    # Asegurar que el directorio existe
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    $context | ConvertTo-Json -Depth 10 | Set-Content -Path $filePath -Encoding UTF8
    
    # Calcular tokens estimados
    $tokens = Estimate-Tokens -FilePath $filePath
    
    return [PSCustomObject]@{
        Path = $filePath
        Tokens = $tokens
        IsValid = (Test-Path $filePath)
    }
}

function Get-GitCommitHash {
    param([string]$ProjectRoot)
    
    try {
        $hash = git -C $ProjectRoot rev-parse HEAD 2>$null
        return if ($hash) { $hash } else { "unknown" }
    } catch {
        return "unknown"
    }
}

function Get-GitBranch {
    param([string]$ProjectRoot)
    
    try {
        $branch = git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null
        return if ($branch) { $branch } else { "unknown" }
    } catch {
        return "unknown"
    }
}

function Estimate-Tokens {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw
    # JSON es más compacto: 1 token ~= 3-4 caracteres
    return [math]::Ceiling($content.Length / 3.5)
}

Export-ModuleMember -Function Build-WorkerContext
