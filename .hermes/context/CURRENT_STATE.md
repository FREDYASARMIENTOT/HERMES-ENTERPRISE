# HERMES ENTERPRISE - Estado Actual

## Fase del Proyecto

**Fase completada**: 5 (Bootstrap Engine - Request/State/Orchestrator)

**Estado del Bootstrap Engine**: Fase 5 cerrada (BootstrapOrchestrator pendiente de adaptar a Provider V2)

## Arquitectura del Bootstrap Engine

### Componentes Implementados y Congelados

1. **BootstrapRequest.ps1** (motor/bootstrap/request/)
   - DTO inmutable que captura intención del usuario
   - Valida datos en construcción (nombre, ruta, opciones)
   - Propiedades: nombre, ruta, crearGitRepo, crearEnvironment, framework

2. **New-BootstrapStateFromRequest.ps1** (motor/bootstrap/engine/)
   - Convierte BootstrapRequest → BootstrapState
   - Inicializa estado con ID, timestamps y metadatos
   - Responsable único de construcción del estado inicial

3. **BootstrapState.ps1** (motor/bootstrap/engine/)
   - Estado interno del motor
   - Propiedades: ID, estado, timestamp, resultados, errores
   - Componente congelado (no modificar)

4. **BootstrapOrchestrator.ps1** (motor/bootstrap/engine/)
   - Coordina ejecución del bootstrap completo
   - Consume BootstrapRequest + BootstrapState
   - Ejecuta 6 pasos: BootstrapState → BootstrapWizard → EnvironmentManager → GitManager → ContextEngine → VSCodeManager
   - Retorna BootstrapReport + BootstrapState actualizado
   - **Estado**: Pendiente de adaptación a Provider V2 (Fase 6)

### Entry Point Público

5. **Start-HermesProject.ps1** (motor/bootstrap/)
   - Único punto de invocación visible fuera del motor
   - Acepta parámetros mínimos: `NombreProyecto` (string) + `RutaProyecto`
   - Construye BootstrapRequest automáticamente
   - Delega en `New-BootstrapStateFromRequest` → `Invoke-BootstrapOrchestrator`
   - Retorna estructura de salida:
     - `Success` (bool)
     - `BootstrapReport` (objeto con detalles de ejecución)
     - `BootstrapState` (estado final del proyecto)
     - `ProximaAccion` (string con recomendación: "Continuar en VSCode" o "Proyecto creado sin workspace")

## Flujo Completo

```
Usuario → Start-HermesProject (entry point)
  ↓
BootstrapRequest (DTO inmutable)
  ↓
New-BootstrapStateFromRequest (conversión)
  ↓
BootstrapState (estado interno)
  ↓
Invoke-BootstrapOrchestrator (coordinación)
  ↓
6 pasos: BootstrapState → BootstrapWizard → EnvironmentManager → GitManager → ContextEngine → VSCodeManager
  ↓
BootstrapReport + BootstrapState actualizado
```

## Verificación

- Sprint 5.3: 5/5 tests ad-hoc pasados (orquestador V2 consume Request + State)
- Fase 5 cerrada: contratos congelados validados

## Documentación Consolidada

- **Contratos arquitectónicos**: `documentacion/bootstrap-engine/contratos-arquitectonicos.md`
- **Flujo de ejecución**: `documentacion/bootstrap-engine/BOOTSTRAP_SEQUENCE.md`

## Próximas Acciones (Fase 6)

1. Diseñar Provider Framework (contratos, secuencia, validaciones)
2. Adaptar BootstrapOrchestrator para consumir Providers
3. Implementar Provider V2 (Azure, AWS, Local, etc.)
