<#
.SYNOPSIS
    MemoryBuilder - Genera PROJECT_MEMORY.md con decisiones arquitectónicas
.DESCRIPTION
    Crea un documento que almacena decisiones ADR, convenciones arquitectónicas,
    excepciones y contexto histórico del proyecto. Separado de CURRENT_STATE.md
    para evitar que el estado crezca indefinidamente.
.BUDGET
    Maximo 150 lineas.
.INPUTS
    - BootstrapState: Estado actual con memoria arquitectónica
    - OutputPath: Ruta donde se generará PROJECT_MEMORY.md
.OUTPUTS
    PSCustomObject con Path, Tokens, IsValid
.EXAMPLE
    $state = Get-BootstrapState -ProjectRoot "D:\HERMES-ENTERPRISE"
    $result = Build-ProjectMemory -BootstrapState $state -OutputPath ".hermes\context"
#>
function Build-ProjectMemory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$BootstrapState,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    # Construir contenido de PROJECT_MEMORY.md
    $content = @"
---
contextVersion: 1
bootstrapVersion: $($BootstrapState.BootstrapVersion)
generatedAt: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
generator: MemoryBuilder
memoryVersion: $($BootstrapState.MemoryVersion)
---

# Memoria del Proyecto

## Decisiones Arquitectónicas (ADR)

### ADR-001: Separación de Estado y Memoria
**Contexto:** CURRENT_STATE.md mezcla estado actual con decisiones históricas.  
**Decisión:** Separar en dos archivos independientes: CURRENT_STATE.md (estado) y PROJECT_MEMORY.md (memoria).  
**Consecuencia:** Estado permanece delgado, memoria crece orgánicamente sin afectar Workers.

### ADR-002: ProjectIndex.json como índice maestro
**Contexto:** Workers deben recorrer el repositorio para entender estructura.  
**Decisión:** Generar PROJECT_INDEX.json con todos los módulos, rutas y dependencias.  
**Consecuencia:** Workers obtienen vista completa sin escanear el sistema de archivos.

### ADR-003: Context Manifest para carga progresiva
**Contexto:** Workers cargan todos los archivos aunque no los necesiten.  
**Decisión:** Generar CONTEXT_MANIFEST.json con prioridad de carga.  
**Consecuencia:** Workers cargan solo lo necesario, optimizando tokens.

### ADR-004: Versionado de contexto
**Contexto:** Futuros cambios pueden romper compatibilidad de Workers.  
**Decisión:** Encabezado YAML con contextVersion en todos los artefactos.  
**Consecuencia:** Workers pueden detectar incompatibilidades y pedir actualización.

## Convenciones Arquitectónicas

### Patrones de Código
- PowerShell 7.0+ obligatorio
- Funciones con verbos estándar (Build-, Invoke-, Get-, New-, Test-)
- [CmdletBinding()] en toda función pública
- Presupuesto de líneas: 150-300 por módulo
- Comentarios con <# .SYNOPSIS #> en toda función

### Estructura de Directorios
- motor/ - Código de producción
- pruebas/unitarias/ - Tests con Pester
- documentacion/ - Markdown técnico
- configuracion/ - JSON de configuración
- .hermes/context/ - Artefactos de contexto (autogenerado)

### Restricciones de Módulos
- BootstrapState.ps1: NO MODIFICAR
- BootstrapWizard.ps1: NO MODIFICAR
- EnvironmentManager.ps1: NO MODIFICAR
- Kernel, Sandbox, EventBus, Logger: NO MODIFICAR

## Excepciones
- Las restricciones pueden relajarse si el Auditor de Calidad lo aprueba
- Los presupuestos de líneas son guías, no límites estrictos
- Se permiten archivos temporales en %TEMP% con prefijo hermes-verify-*

## Próximos Pasos Estratégicos
- Implementar BootstrapOrchestrator (Paso 4)
- Implementar Start-HermesProject.ps1 (objetivo final)
- Expandir Context Intelligence Engine con ML para priorización

## Lecciones Aprendidas
- Separar responsabilidades evita refactorizaciones
- Los artefactos de contexto son más valiosos que el historial conversacional
- La validación ad-hoc previene regresiones silenciosas
- Los workers autónomos requieren contratos claros

---
*Generado automáticamente por MemoryBuilder*
"@
    
    # Escribir archivo
    $filePath = Join-Path $OutputPath "PROJECT_MEMORY.md"
    
    # Asegurar directorio
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    $content | Set-Content -Path $filePath -Encoding UTF8
    
    # tokens
    $tokens = Math.Ceiling($content.Length / 4)
    
    return [PSCustomObject]@{
        Path = $filePath
        Tokens = $tokens
        IsValid = (Test-Path $filePath)
    }
}


