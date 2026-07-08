<#
.SYNOPSIS
    CurrentStateBuilder - Genera CURRENT_STATE.md
.DESCRIPTION
    Genera estado actual del proyecto con componentes implementados,
    fase, paso, restricciones y próximo objetivo.
.NOTES
    Fase 3.5B - Namespace Cleanup
    Depende de ContextHelpers.ps1
#>

# Cargar helpers centralizados
. (Join-Path $PSScriptRoot '..\helpers\ContextHelpers.ps1')

function Build-CurrentState {
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
    $projectPath = Split-Path -Path $parent1 -Parent    # D:\HERMES-ENTERPRISE
    
    # Obtener información de Git
    $commitHash = Get-GitCommitHash -ProjectPath $projectPath
    $branch = Get-GitBranch -ProjectPath $projectPath
    $lastVerification = Get-LastVerification -ProjectPath $projectPath
    
    # Construir contenido de CURRENT_STATE.md
    $content = @"
---
contextVersion: 1
bootstrapVersion: $($BootstrapState.BootstrapVersion)
generatedAt: $(Get-Date -Format "yyyy-MM-dd")
generator: CurrentStateBuilder
commit: $commitHash
---

# Current State

## Project
**Nombre:** $($BootstrapState.ProjectName)
**Versión:** $($BootstrapState.BootstrapVersion)
**Commit:** $commitHash
**Rama:** $branch

## Current Step
**Fase:** $(if ($BootstrapState.CurrentPhase) { $BootstrapState.CurrentPhase } else { "N/A" })
**Paso:** $(if ($BootstrapState.CurrentStep) { $BootstrapState.CurrentStep } else { "N/A" })
**Estado:** $(if ($BootstrapState.StepStatus) { $BootstrapState.StepStatus } else { "N/A" })

## Components Implemented
"@

    # Agregar componentes implementados
    if ($BootstrapState.ComponentesCompletados) {
        foreach ($comp in $BootstrapState.ComponentesCompletados) {
            $content += "`n- $comp"
        }
    } else {
        $content += "`n- (Ninguno)"
    }
    
    $content += @"

## Components Pending
"@

    # Agregar componentes pendientes
    if ($BootstrapState.ComponentesPendientes) {
        foreach ($comp in $BootstrapState.ComponentesPendientes) {
            $content += "`n- $comp"
        }
    } else {
        $content += "`n- (Ninguno)"
    }
    
    $content += @"

## Last Verification
**Fecha:** $($lastVerification.Date)
**Estado:** $($lastVerification.Status)

## Next Objective
$(if ($BootstrapState.ProximoObjetivo) { $BootstrapState.ProximoObjetivo } else { "No definido" })

## Restrictions
- NO modificar BootstrapState.ps1
- NO modificar BootstrapWizard.ps1
- NO modificar EnvironmentManager.ps1
- NO modificar archivos fuera de motor/context/

---

## Files Modified
- motor/context/ContextEngine.ps1
- motor/context/CurrentStateBuilder.ps1

---

## Commit Message
feat: BootstrapEngine Phase 3 - CurrentStateBuilder implementado
"@
    
    # Escribir archivo con encabezado YAML
    $filePath = Join-Path $OutputPath "CURRENT_STATE.md"
    
    # Asegurar que el directorio existe
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    $content | Set-Content -Path $filePath -Encoding UTF8
    
    # Calcular tokens estimados
    $tokens = Estimate-Tokens -Content $content
    
    return [PSCustomObject]@{
        Path = $filePath
        Tokens = $tokens
        IsValid = (Test-Path $filePath)
    }
}
