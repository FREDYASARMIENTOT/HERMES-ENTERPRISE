<#
.SYNOPSIS
    NextTaskBuilder - Genera NEXT_TASK.md con la próxima tarea a ejecutar
.DESCRIPTION
    Crea un documento que especifica claramente qué debe hacer el Worker
    a continuación, incluyendo objetivo, entradas, salidas, criterios de
    aceptación y condiciones de rollback.
.BUDGET
    Maximo 200 lineas.
.INPUTS
    - BootstrapState: Estado actual con próximo objetivo definido
    - OutputPath: Ruta donde se generará NEXT_TASK.md
.OUTPUTS
    PSCustomObject con Path, Tokens, IsValid
.EXAMPLE
    $state = Get-BootstrapState
    $result = Build-NextTask -BootstrapState $state -OutputPath "D:\HERMES-ENTERPRISE\.hermes\context"
#>
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
    
    # Obtener información de Git
    $commitHash = Get-GitCommitHash -OutputPath $OutputPath
    
    # Construir contenido de NEXT_TASK.md
    $content = @"
---
contextVersion: 1
bootstrapVersion: $($BootstrapState.BootstrapVersion)
generatedAt: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
generator: NextTaskBuilder
commit: $commitHash
---

# Próxima Tarea

## Objetivo
$($BootstrapState.ProximoObjetivo)

## Entradas Requeridas
"@

    # Agregar entradas
    if ($BootstrapState.EntradasRequeridas.Count -gt 0) {
        $BootstrapState.EntradasRequeridas | ForEach-Object {
            $content += "`n- $_"
        }
    } else {
        $content += "`n- (Ninguna entrada específica requerida)"
    }
    
    $content += "`n`n## Salidas Esperadas"
    
    # Agregar salidas
    if ($BootstrapState.SalidasEsperadas.Count -gt 0) {
        $BootstrapState.SalidasEsperadas | ForEach-Object {
            $content += "`n- $_"
        }
    } else {
        $content += "`n- (Ninguna salida específica definida)"
    }
    
    $content += "`n`n## Archivos a Crear/Modificar"
    
    if ($BootstrapState.ArchivosAccion.Count -gt 0) {
        $BootstrapState.ArchivosAccion | ForEach-Object {
            $content += "`n- ``$_``"
        }
    } else {
        $content += "`n- (A determinar durante la ejecución)"
    }
    
    $content += @"


## Criterios de Aceptación
"@

    if ($BootstrapState.CriteriosAceptacion.Count -gt 0) {
        $BootstrapState.CriteriosAceptacion | ForEach-Object {
            $content += "`n- [ ] $_"
        }
    } else {
        $content += "`n- [ ] Todos los tests unitarios pasan"
        $content += "`n- [ ] Verificación ad-hoc exitosa"
        $content += "`n- [ ] Documentación actualizada"
        $content += "`n- [ ] Commit realizado con mensaje descriptivo"
    }
    
    $content += @"


## Pruebas Requeridas
- [ ] Tests unitarios para todos los componentes nuevos
- [ ] Pruebas de integración si aplica
- [ ] Verificación ad-hoc con script temporal
- [ ] Validación de presupuestos de líneas cumplidos

## Condiciones de Rollback
Si la implementación:
- Rompe componentes existentes (BootstrapState, BootstrapWizard, EnvironmentManager)
- No pasa las pruebas unitarias
- Viola las restricciones de archivos prohibidos
- Produce errores en la verificación ad-hoc

**Acción:** Revertir con ``git revert HEAD`` y corregir antes de reintentar.

## Commit Esperado
\`\`\`
feat: $($BootstrapState.MensajeCommit)
\`\`\`

## Notas Adicionales
- Mantener KISS/DRY en la implementación
- Seguir patrones establecidos por componentes anteriores
- No modificar archivos prohibidos bajo ninguna circunstancia
- Limpiar recursos temporales después de verificación
"@
    
    # Escribir archivo con encabezado YAML
    $filePath = Join-Path $OutputPath "NEXT_TASK.md"
    
    # Asegurar que el directorio existe
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    $content | Set-Content -Path $filePath -Encoding UTF8
    
    # Calcular tokens estimados
    $tokens = Estimate-Tokens -FilePath $filePath
    
    return [PSCustomObject]@{
        Path = $filePath
        Tokens = $tokens
        IsValid = (Test-Path $filePath)
    }
}

function Get-GitCommitHash {
    param([string]$OutputPath)
    
    try {
        $projectRoot = Split-Path $OutputPath -Parent
        $hash = git -C $projectRoot rev-parse HEAD 2>$null
        return if ($hash) { $hash } else { "unknown" }
    } catch {
        return "unknown"
    }
}

function Estimate-Tokens {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw
    # Estimación: 1 token ~= 4 caracteres (aproximación conservadora)
    return [math]::Ceiling($content.Length / 4)
}

Export-ModuleMember -Function Build-NextTask
