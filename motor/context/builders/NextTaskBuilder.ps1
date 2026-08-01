<#
.SYNOPSIS
    NextTaskBuilder - Genera NEXT_TASK.md
.DESCRIPTION
    Genera próxima tarea con objetivo, entradas, salidas, archivos
    permitidos/prohibidos y criterios de aceptación.
.NOTES
    Fase 3.5B - Namespace Cleanup
    Depende de ContextHelpers.ps1
#>

# Cargar helpers centralizados
. (Join-Path $PSScriptRoot '..\helpers\ContextHelpers.ps1')

function Build-NextTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$BootstrapState,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    # Validar BootstrapState
    if (-not $BootstrapState.ProximoObjetivo) {
        throw "BootstrapState debe contener ProximoObjetivo"
    }
    
    # Calcular ProjectPath desde OutputPath (robusto, funciona aunque el directorio no exista)
    # OutputPath es siempre: <ProjectPath>\.hermes\context
    $parent1 = Split-Path -Path $OutputPath -Parent     # D:\HERMES-ENTERPRISE\.hermes
    $projectPath = Split-Path -Path $parent1 -Parent    # D:\HERMES-ENTERPRISE
    
    # Obtener commit hash desde helpers centralizados
    $commitHash = Get-GitCommitHash -ProjectPath $projectPath
    $branch = Get-GitBranch -ProjectPath $projectPath
    
    # Construir contenido de NEXT_TASK.md
    $content = @"
---
project: $($BootstrapState.ProjectName)
version: $($BootstrapState.BootstrapVersion)
phase: $(if ($BootstrapState.CurrentPhase) { $BootstrapState.CurrentPhase } else { "N/A" })
step: $(if ($BootstrapState.CurrentStep) { $BootstrapState.CurrentStep } else { "N/A" })
git_commit: $commitHash
git_branch: $(Get-GitBranch -ProjectPath $OutputPath)
generated_at: $(Get-Date -Format "yyyy-MM-dd")
---

# Next Task

## Objective
$($BootstrapState.ProximoObjetivo)

## Inputs
"@

    # Agregar inputs
    if ($BootstrapState.EntradasRequeridas) {
        foreach ($inp in $BootstrapState.EntradasRequeridas) {
            $content += "`n- $inp"
        }
    } else {
        $content += "`n- BootstrapState actualizado"
    }
    
    $content += @"

## Expected Outputs
"@

    # Agregar outputs
    if ($BootstrapState.SalidasEsperadas) {
        foreach ($output in $BootstrapState.SalidasEsperadas) {
            $content += "`n- $output"
        }
    } else {
        $content += "`n- Módulo implementado y verificado"
    }
    
    $content += @"

## Allowed Files
"@

    # Agregar archivos permitidos
    if ($BootstrapState.ArchivosPermitidos) {
        foreach ($file in $BootstrapState.ArchivosPermitidos) {
            $content += "`n- $file"
        }
    } else {
        $content += "`n- motor/context/builders/*"
    }
    
    $content += @"

## Forbidden Files
"@

    # Agregar archivos prohibidos
    if ($BootstrapState.ArchivosProhibidos) {
        foreach ($file in $BootstrapState.ArchivosProhibidos) {
            $content += "`n- $file"
        }
    } else {
        $content += "`n- motor/bootstrap/engine/BootstrapState.ps1
- motor/bootstrap/engine/BootstrapWizard.ps1
- motor/bootstrap/engine/environment/EnvironmentManager.ps1"
    }
    
    $content += @"

## Required Tests
- Tests unitarios pasan (100%)
- Verificación ad-hoc exitosa
- Sin errores de parseo
- Sin colisiones de nombres de funciones

## Acceptance Criteria
"@

    # Agregar criterios de aceptación
    if ($BootstrapState.CriteriosAceptacion) {
        foreach ($criterion in $BootstrapState.CriteriosAceptacion) {
            $content += "`n- [ ] $criterion"
        }
    } else {
        $content += "`n- [ ] Código implementado según contrato
- [ ] Tests pasan
- [ ] Sin warnings de parseo
- [ ] Documentación actualizada"
    }
    
    $content += @"

## Commit Message
feat: $($BootstrapState.MensajeCommit)
"@
    
    # Escribir archivo con encabezado YAML
    $filePath = Join-Path $OutputPath "NEXT_TASK.md"
    
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
