<#
.SYNOPSIS
    WorkerContextBuilder - Genera WORKER_CONTEXT.json como contrato estructurado para Workers
.DESCRIPTION
    Crea un contrato JSON que contiene toda la información necesaria para que
    un Worker pueda ejecutar su tarea: proyecto, versión, fase, componentes,
    paths permitidos/prohibidos, tests requeridos y dependencias.
.NOTES
    Fase 3.5B - Namespace Cleanup
    Depende de GitHelpers y TokenHelpers
    
    Firma: Build-WorkerContext -BootstrapState <obj> -OutputPath <str>
#>

# Importar helpers centralizados
. "$PSScriptRoot\..\helpers\GitHelpers.ps1"
. "$PSScriptRoot\..\helpers\TokenHelpers.ps1"

function Build-WorkerContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$BootstrapState,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    # Validar BootstrapState
    if (-not $BootstrapState.ProjectName) {
        throw "BootstrapState debe contener ProjectName"
    }
    
    # Calcular ProjectPath desde OutputPath (robusto, funciona aunque el directorio no exista)
    # OutputPath es siempre: <ProjectPath>\.hermes\context
    $parent1 = Split-Path -Path $OutputPath -Parent     # D:\HERMES-ENTERPRISE\.hermes
    $ProjectPath = Split-Path -Path $parent1 -Parent    # D:\HERMES-ENTERPRISE
    
    # Obtener información de Git
    $commitHash = Get-GitCommitHash -ProjectPath $ProjectPath
    $branch = Get-GitBranch -ProjectPath $ProjectPath
    
    # Construir WORKER_CONTEXT.json
    $context = [PSCustomObject]@{
        contextVersion = 1
        bootstrapVersion = $BootstrapState.BootstrapVersion
        generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        generator = "WorkerContextBuilder"
        
        project = [PSCustomObject]@{
            name = $BootstrapState.ProjectName
            version = $BootstrapState.BootstrapVersion
            phase = "Fase $($BootstrapState.CurrentPhase)"
            step = "Paso $($BootstrapState.CurrentStep)"
            commit = $commitHash
            branch = $branch
            workingDirectory = $ProjectPath
        }
        
        components = @{
            completed = $BootstrapState.ComponentesCompletados
            pending = $BootstrapState.ComponentesPendientes
        }
        
        environment = @{
            pythonVersion = "3.x"
            powershellVersion = $PSVersionTable.PSVersion.ToString()
        }
        
        gitInfo = @{
            status = "clean"
            lastCommit = $commitHash
            branch = $branch
        }
        
        tests = @{
            unitTests = "pending"
            integrationTests = "pending"
            adHocVerification = "pending"
        }
        
        documentation = @{
            PUBLIC_API = "generated"
            BuilderContract = "generated"
            DependencyGraph = "generated"
            ArchitectureReport = "generated"
        }
        
        nextObjective = $BootstrapState.ProximoObjetivo
        
        files = [PSCustomObject]@{
            allowed = @(
                "motor\**\*.ps1",
                "pruebas\unitarias\**\*.ps1",
                "documentacion\context\**\*.md"
            )
            forbidden = @(
                "motor\bootstrap\engine\BootstrapState.ps1",
                "motor\sandbox\**",
                "motor\eventos\**",
                "motor\logger\**",
                "motor\kernel\**"
            )
        }
    }
    
    # Escribir WORKER_CONTEXT.json
    $contextPath = Join-Path $OutputPath "WORKER_CONTEXT.json"
    $context | ConvertTo-Json -Depth 10 | Set-Content -Path $contextPath -Encoding UTF8
    
    # Calcular tokens estimados
    $tokens = Estimate-Tokens -Content (Get-Content -Path $contextPath -Raw)
    
    return [PSCustomObject]@{
        Path = $contextPath
        Tokens = $tokens
        IsValid = (Test-Path $contextPath)
    }
}
