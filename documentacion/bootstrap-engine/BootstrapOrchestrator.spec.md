# BootstrapOrchestrator - Especificación Ejecutable

## Responsabilidad Única
Coordinar el flujo de bootstrap sin contener lógica de negocio.

## Flujo de Invocación (orden estricto)

```
Start-HermesProject.ps1
    │
    ▼
Invoke-BootstrapOrchestrator
    │
    ├── 1. Initialize-BootstrapState
    │       (lee SESSION_HANDOFF.json, crea estado inicial)
    │
    ├── 2. Invoke-BootstrapWizard
    │       (interacción usuario: crear/abrir/clonar proyecto)
    │       │
    │       └── Salida: ProjectDescriptor + EnvironmentDescriptor
    │
    ├── 3. Invoke-EnvironmentManager
    │       (valida y configura entorno según ProjectDescriptor)
    │
    ├── 4. Invoke-GitManager
    │       (git init si nuevo, o valida repo existente)
    │
    ├── 5. Invoke-ContextEngine
    │       (genera Context Package completo en .hermes/context/)
    │
    ├── 6. Invoke-VSCodeManager
    │       (abre workspace en VS Code si aplica)
    │
    └── 7. Invoke-BootstrapReport
            (resume ejecución, métricas, siguiente paso)
```

## Contratos

### Entrada
```powershell
Invoke-BootstrapOrchestrator
    -ContextPath : string  # Ruta a .hermes/context/ (default: auto)
    -Force       : switch  # Saltar confirmaciones (CI/automatización)
```

### Salida
```powershell
PSCustomObject
    {
        Success        : bool
        ProjectPath    : string
        Environment    : string
        ContextPackage : string[]  # Archivos generados
        Duration       : TimeSpan
        NextStep       : string    # "DeveloperWorkspace" o "SessionManager"
        Errors         : string[]
    }
```

### Eventos Publicados
```
Bootstrap.Started
Bootstrap.Step.Started    (StepName)
Bootstrap.Step.Completed  (StepName, Duration)
Bootstrap.Completed
Bootstrap.Failed          (Error, StepName)
```

## Manejo de Errores

### Rollback
- Si falla paso N, ejecutar rollback de N hasta paso 1
- Rollback = limpieza de artefactos generados (no reversión de git)
- BootstrapState mantiene flag `IsRolledBack`

### Cancelación
- Usuario puede cancelar en cualquier wizard
- Cancelación genera salida `Success=$false`, `NextStep="UserCancelled"`

### Logging
- Cada paso emite evento + log a Logger si está disponible
- No lanza excepciones no capturadas hacia Start-HermesProject
- Devuelve objeto con `Errors[]` poblado si algo falla

## Puntos de Extensión

### Pre/Post Hooks
Cada paso acepta:
- `-PreHook  : scriptblock`  # Se ejecuta antes del paso
- `-PostHook : scriptblock`  # Se ejecuta después del paso

### Inyección de Dependencias
Orquestador acepta:
- `-GitManager    : object`  # Default: GitManager si existe, mock si no
- `-VSCodeManager : object`  # Default: VSCodeManager si existe, mock si no
- Permite tests unitarios sin dependencias externas

## Restricciones Arquitectónicas

### NO HACE
- ✗ No valida contratos (eso es Test-ContextContracts.ps1)
- ✗ No inspecciona builders/helpers (eso es ContextEngine)
- ✗ No interactúa con usuario directamente (eso es BootstrapWizard)
- ✗ No ejecuta git commands directamente (eso es GitManager)
- ✗ No abre VS Code directamente (eso es VSCodeManager)

### SÍ HACE
- ✓ Lee Context Package para obtener estado inicial
- ✓ Invoca managers en orden estricto
- ✓ Publica eventos en cada transición
- ✓ Captura errores y los reporta en salida
- ✓ Ejecuta rollback si es necesario
- ✓ Mide duración de cada paso

## Métricas

Tiempo máximo esperado por paso:
- BootstrapState: <100ms
- BootstrapWizard: depende de usuario (timeout 5min)
- EnvironmentManager: <2s
- GitManager: <1s
- ContextEngine: <3s
- VSCodeManager: <500ms
- BootstrapReport: <200ms

**Total esperado**: <10s (sin contar wizard)

## Tamaños Esperados

- BootstrapOrchestrator.ps1: ~150 líneas (solo coordinación)
- Cada paso invocable: función existente en su módulo (no se duplica)
- Tests unitarios: ~200 líneas (mock de managers)

## Criterios de Aceptación (Paso 4)

1. ✓ Invoke-BootstrapOrchestrator existe y se carga sin errores
2. ✓ Invoca los 7 pasos en orden correcto
3. ✓ Publica eventos en cada transición
4. ✓ Devuelve objeto con Success, ProjectPath, Duration, Errors
5. ✓ Maneja errores sin lanzar excepciones no capturadas
6. ✓ Soporta cancelación en BootstrapWizard
7. ✓ Tests unitarios pasan (mock de managers)
8. ✓ Verificación ad-hoc exitosa
9. ✓ Working tree clean
10. ✓ Commit único del Paso 4

## Próximos Pasos (Fuera del Alcance de Paso 4)

- BootstrapReport (paso 7) será implementado en Paso 5
- Refinamiento de Pre/Post hooks
- Telemetría avanzada (si se requiere)
- Integración con Start-HermesProject.ps1
