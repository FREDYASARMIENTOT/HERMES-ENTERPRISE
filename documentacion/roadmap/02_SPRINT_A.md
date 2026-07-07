---
# ============================================================================
# HERMES-ENTERPRISE
# Sprint A: Safe Sandbox
# ============================================================================
titulo: "Sprint A — Safe Sandbox"
proyecto: "HERMES-ENTERPRISE"
version_doc: "1.0.0"
estado: "Propuesta de Diseño"
autor: "Fredy Alejandro Sarmiento Torres"
fecha_creacion: "2026-07-07"
fecha_revision: "2026-07-07"
sprint_id: "SA-001"
duracion_semanas: 4
story_points_totales: 40
equipo: "3-5 Ingenieros Senior"
dependencias: "ROADMAP_EVOLUTIVO_INCREMENTAL.md, SRS_HERMES_ENTERPRISE.md"
prerequisito: "Fase 0.5 completada"
bloquea: "Sprint B, Sprint C"
clasificacion: "Diseño Estratégico"
criterio_exito: "Sandbox 100% recuperable ante fallos"
# ============================================================================
---

# Sprint A — Safe Sandbox

## Navegación

| Documento | Estado |
|---|---|
| [← ROADMAP_EVOLUTIVO_INCREMENTAL.md](../ROADMAP_EVOLUTIVO_INCREMENTAL.md) | Línea base |
| [← SRS_HERMES_ENTERPRISE.md](../SRS_HERMES_ENTERPRISE.md) | Requisitos |
| [→ Sprint B: Professional Project Generator](03_SPRINT_B.md) | Siguiente sprint |
| [→ Sprint C: Memory & Learning](04_SPRINT_C.md) | Sprint posterior |

---

## 1. Visión General

### 1.1 Objetivo del Sprint

Convertir el Sandbox de HERMES-ENTERPRISE en un entorno completamente seguro, recuperable y auditable.

El Sandbox actual (implementado en `ExecutionSupervisor.ps1`, `ExecutionLogger.ps1`, `ExecutionDashboard.ps1`) ejecuta 7 pasos secuenciales sin capacidad de recuperación. Si un paso falla en el paso 6, se pierde todo el trabajo de los pasos 1-5. Este sprint elimina esa fragilidad.

### 1.2 Alcance

**Incluye:**
- Motor de Snapshots (guardado de estado en disco)
- Motor de Restauración (carga de snapshots con validación)
- Motor de Rollback (reversión a estado anterior)
- Motor de Recovery (continuación de ejecuciones fallidas)
- Transaction Log (audit trail completo)
- Suite de pruebas de recuperación
- Validación de integridad de snapshots
- Diagrama de máquina de estados de recuperación

**Fuera de alcance:**
- Distribución de snapshots entre nodos
- Snapshots incrementales complejos
- Integración con servicios cloud externos

### 1.3 Motivación

**Problema actual:**
```
Ejecución Sandbox: 7 pasos secuenciales
  Paso 1 → Paso 2 → ... → Paso 6 (FALLA) → ???
  
Resultado: Todo el trabajo previo se pierde.
Tiempo desperdiciado: ~100% de la ejecución.
```

**Estado deseado:**
```
Ejecución Sandbox: 7 pasos con checkpoints
  Paso 1 → [SNAPSHOT] → Paso 2 → [SNAPSHOT] → ... → Paso 6 (FALLA)
                                                            ↓
                                                     [RECOVERY desde Paso 5]
                                                             ↓
                                                     Paso 6 (REINTENTO) → Paso 7 → COMPLETADO
```

### 1.4 Métricas de éxito

| Métrica | Valor actual | Objetivo post-Sprint A |
|---|---|---|
| Tasa de recuperación ante fallo | 0% | 95%+ |
| Tiempo de recuperación (P50) | N/A | < 30 segundos |
| Pérdida de datos en fallo | 100% | < 1 snapshot atrás |
| Cobertura de pruebas de recovery | 0% | 80%+ |
| Audit trail completeness | Parcial | 100% |

---

## 2. Arquitectura de Diseño

### 2.1 Componentes del Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                    EXECUTION SUPERVISOR                          │
│                         (Orquestador)                            │
└────────────┬────────────────┬────────────────┬──────────────────┘
             │                │                │
             ▼                ▼                ▼
┌─────────────────┐ ┌──────────────┐ ┌─────────────────────┐
│ SNAPSHOT ENGINE │ │RECOVERY ENG. │ │ TRANSACTION LOG     │
│                 │ │              │ │                     │
│ • Save State    │ │ • Detect     │ │ • Append-only       │
│ • Named snaps   │ │ • Resume     │ │ • Timestamped       │
│ • Metadata      │ │ • Validate   │ │ • Hashed            │
│ • Compression   │ │ • Rollback   │ │ • Queryable         │
└────────┬────────┘ └──────┬───────┘ └──────────┬──────────┘
         │                 │                     │
         ▼                 ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│              VALIDATION ENGINE                               │
│                                                              │
│  • Integrity checks (SHA-256)                                │
│  • Schema validation                                         │
│  • Dependency verification                                   │
│  • Corruption detection                                      │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│              PERSISTENCE LAYER                               │
│                                                              │
│  • Snapshots/{id}/                                           │
│  │   ├── snapshot.json          (metadatos)                  │
│  │   ├── state.json             (estado de ejecución)        │
│  │   ├── context.json           (developer context)          │
│  │   ├── integrity.sha256       (hash de verificación)       │
│  │   └── artifacts/             (archivos generados)         │
│  ├── transactions.log           (audit trail)                │
│  └── transactions.index.json    (índice de transacciones)    │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Máquina de Estados de Recuperación

```
                    ┌──────────┐
                    │  IDLE    │
                    └────┬─────┘
                         │ Start Execution
                         ▼
                    ┌──────────┐
            ┌──────│ RUNNING  │◄──────────────┐
            │      └──┬───┬───┘               │
            │         │   │                    │
            │         │   │ Failure            │ Resume
            │         │   ▼                    │
            │         │ ┌────────┐             │
            │         │ │FAILED  │─────────────┤
            │         │ └────────┘             │
            │         │                        │
    Step    │         │ Rollback               │
  Complete  │         ▼                        │
            │     ┌──────────┐                 │
            ├────►│ROLLING   │                 │
            │     │BACK      │                 │
            │     └────┬─────┘                 │
            │          │                       │
            │          ▼                       │
            │    ┌──────────┐                  │
            │    │ROLLED    │                  │
            │    │BACK      │                  │
            │    └────┬─────┘                  │
            │         │                        │
            │         │ Retry                  │
            │         ▼                        │
            │    ┌──────────┐                  │
            └────┤RECOVERING│──────────────────┘
                 └────┬─────┘
                      │
                      ▼
                 ┌──────────┐
                 │COMPLETED │
                 └──────────┘
```

**Estados:**
- `IDLE`: Sin ejecución activa
- `RUNNING`: Ejecutando pasos del Sandbox
- `FAILED`: Un paso falló, esperando decisión
- `ROLLING_BACK`: Revirtiendo a snapshot anterior
- `ROLLED_BACK`: Rollback completado, listo para retry
- `RECOVERING`: Reintentando desde el último snapshot válido
- `COMPLETED`: Ejecución finalizada exitosamente

### 2.3 Modelo de Datos del Snapshot

```json
{
  "snapshot_id": "snap_2026-07-07T14:30:00Z_abc123",
  "sandbox_path": "C:\\Sandboxes\\ProyectoX",
  "execution_id": "exec_uuid_v4",
  "created_at": "2026-07-07T14:30:00Z",
  "step_number": 3,
  "step_name": "EjecutarEscenario",
  "step_status": "COMPLETED",
  "percentage": 43,
  "developer_context": {
    "scenario": "EmptyFolder",
    "project_name": "ProyectoX",
    "artifacts_generated": 12,
    "tests_passed": 8
  },
  "state": {
    "errors": [],
    "warnings": [],
    "completed_steps": ["CrearSandbox", "InicializarEscenario"],
    "current_step": "EjecutarEscenario",
    "remaining_steps": ["SmokeTest", "ExportarReportes", "GenerarUserGuide", "GenerarInstructions"]
  },
  "integrity": {
    "algorithm": "SHA-256",
    "hash": "a1b2c3d4e5f6...",
    "checksum_files": [
      {"path": "state.json", "hash": "..."},
      {"path": "context.json", "hash": "..."}
    ]
  },
  "metadata": {
    "size_bytes": 4194304,
    "compression": "gzip",
    "duration_seconds": 45,
    "system_info": {
      "os": "Windows 10",
      "powershell_version": "7.4.0",
      "hermes_version": "0.9.1"
    }
  }
}
```

### 2.4 Modelo de Datos del Transaction Log

```json
{
  "transaction_id": "tx_2026-07-07T14:30:00Z_def456",
  "timestamp": "2026-07-07T14:30:00Z",
  "execution_id": "exec_uuid_v4",
  "operation": "STEP_COMPLETED",
  "step_name": "CrearSandbox",
  "previous_state": "PENDING",
  "new_state": "COMPLETED",
  "snapshot_created": "snap_2026-07-07T14:28:00Z_abc123",
  "details": {
    "duration_seconds": 12,
    "files_created": 5,
    "warnings": 0,
    "errors": 0
  },
  "actor": "ExecutionSupervisor",
  "integrity": {
    "hash": "f7e8d9c0b1a2...",
    "previous_hash": "e6f5d4c3b2a1..."
  }
}
```

---

## 3. Épicas

### Épica SA-E1: Motor de Snapshots

**Descripción:** Como usuario de HERMES-ENTERPRISE, quiero que el estado del Sandbox se guarde automáticamente en checkpoints para poder recuperar el progreso en caso de fallo.

**Criterios de aceptación de la épica:**
- Los snapshots se crean automáticamente después de cada paso completado
- Los snapshots incluyen metadatos completos del estado de ejecución
- Los snapshots son verificables mediante hash SHA-256
- Los snapshots pueden tener nombres customizados por el usuario

### Épica SA-E2: Motor de Restauración

**Descripción:** Como usuario de HERMES-ENTERPRISE, quiero poder restaurar un snapshot para continuar desde ese punto exacto en el tiempo.

**Criterios de aceptación de la épica:**
- El motor identifica automáticamente el último snapshot válido
- La restauración valida la integridad antes de aplicar
- Después de restaurar, la ejecución continúa desde el siguiente paso
- Se pueden listar y seleccionar snapshots específicos por nombre/fecha

### Épica SA-E3: Motor de Rollback

**Descripción:** Como usuario de HERMES-ENTERPRISE, quiero poder revertir a un estado anterior si una operación causa problemas.

**Criterios de aceptación de la épica:**
- El rollback puede ir a cualquier snapshot anterior
- El rollback limpia archivos generados después del snapshot objetivo
- El rollback es atómico (o se completa o no cambia nada)
- Se registran todos los rollbacks en el transaction log

### Épica SA-E4: Motor de Recovery

**Descripción:** Como usuario de HERMES-ENTERPRISE, quiero que el sistema pueda continuar automáticamente una ejecución fallida desde el último punto válido.

**Criterios de aceptación de la épica:**
- Al detectar un fallo, el sistema ofrece opciones: retry, rollback, abort
- El recovery reinicia desde el último snapshot válido automáticamente (modo auto)
- En modo interactivo, el usuario decide la estrategia de recovery
- El recovery preserva logs y artefactos generados antes del fallo

### Épica SA-E5: Transaction Log y Auditoría

**Descripción:** Como administrador de HERMES-ENTERPRISE, quiero un log de auditoría completo e inmutable de todas las operaciones del Sandbox.

**Criterios de aceptación de la épica:**
- Cada operación genera una entrada en el transaction log
- El log es append-only (no se puede modificar retroactivamente)
- Cada entrada incluye hash encadenado para detectar manipulación
- El log se puede exportar y consultar por rango de fechas

### Épica SA-E6: Suite de Pruebas de Recovery

**Descripción:** Como QA Lead, quiero una suite de pruebas que valide la capacidad de recuperación del sistema.

**Criterios de aceptación de la épica:**
- Pruebas de snapshot creation/restoration (unitarias)
- Pruebas de rollback con validación de estado (integración)
- Pruebas de recovery ante fallos simulados (end-to-end)
- Pruebas de integridad con datos corrompidos (negativas)
- Cobertura mínima del 80% en componentes del Sprint A

---

## 4. Historias de Usuario

### SA-US-01: Snapshot Automático

**Como** usuario de HERMES-ENTERPRISE
**Quiero** que se cree un snapshot automáticamente después de cada paso del Sandbox
**Para** poder recuperar mi progreso si algo falla después

**Criterios de aceptación:**
1. DADO que estoy ejecutando el Sandbox
   CUANDO un paso se completa exitosamente
   ENTONCES se crea un snapshot con el estado completo
   Y el snapshot incluye: nombre auto-generado, timestamp, paso ejecutado, estado actual

2. DADO que se creó un snapshot
   CUANDO verifico su integridad
   ENTONCES el hash SHA-256 es válido
   Y todos los archivos referenciados existen

3. DADO que se creó un snapshot
   CUANDO lo listan los snapshots disponibles
   ENTONCES aparece con su nombre, fecha, paso y estado

**Story Points:** 8
**Horas estimadas:** 16h
**Prioridad:** Crítica

---

### SA-US-02: Snapshot con Nombre

**Como** usuario avanzado de HERMES-ENTERPRISE
**Quiero** poder dar un nombre descriptivo a un snapshot
**Para** identificar fácilmente puntos de restauración importantes

**Criterios de aceptación:**
1. DADO que estoy ejecutando el Sandbox con `-Interactive`
   CUAN DO llego a un paso donde quiero crear un checkpoint nombrado
   ENTONCES puedo especificar un nombre como `"pre-migracion"` o `"estado-limpio"`

2. DADO que creé un snapshot nombrado
   CUANDO ejecuto otro sandbox en el mismo directorio
   ENTONCES puedo listar snapshots anteriores
   Y los identifico por nombre o por timestamp automático

**Story Points:** 3
**Horas estimadas:** 6h
**Prioridad:** Alta

---

### SA-US-03: Restaurar desde Snapshot

**Como** usuario de HERMES-ENTERPRISE
**Quiero** restaurar el Sandbox desde un snapshot específico
**Para** continuar la ejecución desde ese punto si algo falla

**Criterios de aceptación:**
1. DADO que existe un snapshot válido
   CUANDO ejecuto `Restore-HermesEnterpriseSandbox -SnapshotId <id>`
   ENTONCES el estado del Sandbox se carga desde el snapshot
   Y la ejecución continúa desde el siguiente paso al snapshot
   Y los artefactos generados después del snapshot se limpian

2. DADO que estoy restaurando un snapshot
   CUANDO la validación de integridad falla
   ENTONCES la restauración se aborta
   Y se muestra un error detallado
   Y el estado anterior no se modifica

**Story Points:** 8
**Horas estimadas:** 16h
**Prioridad:** Crítica

---

### SA-US-04: Rollback a Estado Anterior

**Como** usuario de HERMES-ENTERPRISE
**Quiero** poder revertir a un snapshot anterior
**Para** deshacer cambios que causaron problemas

**Criterios de aceptación:**
1. DADO que la ejecución actual tiene 3 snapshots anteriores
   CUANDO ejecuto `Rollback-HermesEnterpriseSandbox -StepsBack 2`
   ENTONCES el sistema revierte al snapshot de 2 pasos atrás
   Y los archivos generados desde ese snapshot se eliminan
   Y se registra la operación en el transaction log
   Y la ejecución puede continuar desde el paso revertido

2. DADO que ejecuté un rollback
   CUANDO verifico el transaction log
   ENTONCES veo la operación de rollback detallada
   Y puedo ver qué paso se revirtió y por qué

**Story Points:** 5
**Horas estimadas:** 10h
**Prioridad:** Alta

---

### SA-US-05: Recovery Automático

**Como** usuario de HERMES-ENTERPRISE
**Quiero** que el sistema intente automáticamente recuperar una ejecución fallida
**Para** no tener que intervenir manualmente en errores transitorios

**Criterios de aceptación:**
1. DADO que el Sandbox está en modo `-AutoRecovery`
   CUAN DO un paso falla
   ENTONCES el sistema detecta el fallo
   Y automáticamente intenta restaurar el último snapshot válido
   Y reintenta el paso fallido
   Y si tiene éxito, continúa con los pasos restantes

2. DADO que el recovery automático falló (el reintento también falla)
   CUANDO se alcanza el límite de reintentos (default: 3)
   ENTONCES el sistema cambia a modo interactivo
   Y solicita al usuario que decida: abortar, omitir paso, o rollback manual

3. DADO que se activó el recovery automático
   CUANDO se completa la recuperación
   ENTONCES el transaction log muestra la secuencia completa de eventos
   Y el usuario puede ver qué paso falló, cuántos reintentos hubo, y el resultado final

**Story Points:** 8
**Horas estimadas:** 16h
**Prioridad:** Crítica

---

### SA-US-06: Transaction Log Completo

**Como** administrador de HERMES-ENTERPRISE
**Quiero** un log de auditoría inmutable de todas las operaciones
**Para** poder rastrear qué sucedió en una ejecución y detectar anomalías

**Criterios de aceptación:**
1. DADO que se está ejecutando cualquier operación del Sandbox
   CUANDO se inicia/completa/falla una operación
   ENTONCES se genera una entrada en el transaction log
   Y la entrada incluye: timestamp, operation, actor, execution_id, estado anterior/nuevo

2. DADO que se generaron múltiples entradas de transaction log
   CUANDO verifico la cadena de hashes
   ENTONCES cada entrada referencia el hash de la entrada anterior
   Y la secuencia es inmutable (cualquier modificación rompe la cadena)

3. DADO que quiero auditar una ejecución
   CUANDO ejecuto `Export-HermesEnterpriseTransactionLog -ExecutionId <id> -Format HTML`
   ENTONCES se genera un reporte legible con timeline visual
   Y puedo filtrar por tipo de operación, rango de fechas, o nivel de severidad

**Story Points:** 5
**Horas estimadas:** 10h
**Prioridad:** Alta

---

### SA-US-07: Validación de Integridad de Snapshots

**Como** QA Lead de HERMES-ENTERPRISE
**Quiero** poder validar la integridad de un snapshot antes de restaurarlo
**Para** asegurar que no está corrupto

**Criterios de aceptación:**
1. DADO que existe un snapshot
   CUANDO ejecuto `Test-HermesEnterpriseSnapshotIntegrity -SnapshotId <id>`
   ENTONCES se verifica el hash SHA-256 de todos los archivos
   Y se valida que el esquema JSON sea correcto
   Y se verifica que todos los archivos referenciados existan
   Y se retorna un resultado con el estado de cada verificación

2. DADO que un snapshot tiene archivos corruptos
   CUANDO ejecuto la validación de integridad
   ENTONCES la validación falla
   Y se reportan exactamente qué archivos tienen problemas
   Y el snapshot NO se puede usar para restauración

3. DADO que quiero validar múltiples snapshots de una ejecución
   CUANDO ejecuto `Test-HermesEnterpriseAllSnapshots -ExecutionId <id>`
   ENTONCES se valida cada snapshot
   Y se genera un reporte de salud con resumen: X válidos, Y inválidos, Z con warnings

**Story Points:** 5
**Horas estimadas:** 10h
**Prioridad:** Alta

---

### SA-US-08: Suite de Pruebas de Recovery

**Como** QA Lead de HERMES-ENTERPRISE
**Quiero** una suite de pruebas que valide los escenarios de recuperación
**Para** garantizar que la capacidad de recovery funciona correctamente

**Criterios de aceptación:**
1. La suite incluye al menos las siguientes pruebas:
   - `Test-SnapshotCreation`: Crear snapshot y validar integridad
   - `Test-SnapshotRestoration`: Restaurar snapshot y verificar estado
   - `Test-RollbackFunctionality`: Rollback y verificar limpieza de archivos
   - `Test-RecoveryFromStepFailure`: Simular fallo en paso N y recuperar
   - `Test-CorruptedSnapshotRejection`: Snapshot corrupto debe ser rechazado
   - `Test-TransactionLogIntegrity`: Verificar cadena de hashes
   - `Test-ConcurrentSnapshots`: Múltiples ejecuciones simultáneas
   - `Test-LargeSnapshotPerformance`: Snapshots > 100MB

2. La suite se ejecuta con `Invoke-HermesEnterpriseRecoveryTests`
   Y genera un reporte con resultados detallados
   Y cada prueba tiene tiempo de ejecución, estado y detalles de fallo si aplica

3. La cobertura de código de los componentes del Sprint A es ≥ 80%

**Story Points:** 5
**Horas estimadas:** 10h
**Prioridad:** Alta

---

### SA-US-09: Recovery Interactivo

**Como** usuario que ejecuta el Sandbox en modo interactivo
**Quiero** que ante un fallo se me presenten opciones claras de recuperación
**Para** poder decidir la mejor estrategia según el contexto

**Criterios de aceptación:**
1. DADO que estoy ejecutando con `-Interactive`
   CUAN DO un paso falla
   ENTONCES se muestra un menú:
   ```
   ══════════════════════════════════════════════════
   FALLO EN PASO 5: ExportarReportes
   Error: Access denied to output directory
   
   Opciones de recuperación:
   [1] Reintentar este paso
   [2] Omitir este paso y continuar
   [3] Rollback al último snapshot (Paso 4)
   [4] Seleccionar snapshot específico
   [5] Abortar ejecución
   ══════════════════════════════════════════════════
   ```

2. DADO que elegí una opción de recovery
   CUANDO se completa la acción de recovery
   ENTONCES el transaction log registra mi decisión y el resultado
   Y la ejecución continúa o se aborta según lo elegido

**Story Points:** 3
**Horas estimadas:** 6h
**Prioridad:** Media

---

### SA-US-10: Dashboard de Snapshots

**Como** usuario de HERMES-ENTERPRISE
**Quiero** ver en el dashboard la información de snapshots disponibles
**Para** entender el estado de recuperación en todo momento

**Criterios de aceptación:**
1. El `ExecutionDashboard` ahora muestra:
   - Número de snapshots creados
   - Último snapshot válido
   - Tiempo total en snapshots (overhead)
   - Estado de recovery si está activo

2. DADO que estoy en modo interactivo
   CUANDO se pregunta por el estado
   ENTONCES se muestra información completa de snapshots
   Y se puede listar snapshots con detalles

**Story Points:** 3
**Horas estimadas:** 6h
**Prioridad:** Media

---

## 5. Tareas con Story Points y Horas

### Épica SA-E1: Motor de Snapshots (20 SP / 40h)

| ID | Tarea | Story Points | Horas | Dependencias | Responsable |
|---|---|---|---|---|---|
| SA-T1.1 | Diseñar modelo de datos del snapshot | 2 | 4h | - | Chief Architect |
| SA-T1.2 | Implementar `New-HermesEnterpriseSnapshot` | 5 | 10h | T1.1 | Enterprise Engineer |
| SA-T1.3 | Implementar `Get-HermesEnterpriseSnapshots` | 3 | 6h | T1.1 | Enterprise Engineer |
| SA-T1.4 | Implementar integración con ExecutionSupervisor | 5 | 10h | T1.2, T1.3 | Enterprise Engineer |
| SA-T1.5 | Implementar snapshot con nombre personalizado | 3 | 6h | T1.2 | Senior Engineer |
| SA-T1.6 | Documentar Snapshot Engine | 2 | 4h | T1.2 | Enterprise Engineer |

**Total Épica E1: 20 SP / 40h**

### Épica SA-E2: Motor de Restauración (16 SP / 32h)

| ID | Tarea | Story Points | Horas | Dependencias | Responsable |
|---|---|---|---|---|---|
| SA-T2.1 | Diseñar lógica de restauración | 2 | 4h | T1.1 | Chief Architect |
| SA-T2.2 | Implementar `Restore-HermesEnterpriseSandbox` | 5 | 10h | T2.1, T1.2 | Enterprise Engineer |
| SA-T2.3 | Implementar validación de integridad pre-restauración | 5 | 10h | T2.2 | Enterprise Engineer |
| SA-T2.4 | Implementar limpieza de artefactos post-snapshot | 3 | 6h | T2.2 | Senior Engineer |
| SA-T2.5 | Integrar restauración con Supervisor (modo recovery) | 3 | 6h | T2.2, T1.4 | Enterprise Engineer |
| SA-T2.6 | Documentar Restore Engine | 2 | 4h | T2.2 | Enterprise Engineer |

**Total Épica E2: 16 SP / 32h** *(Nota: se reduce a 8 SP reutilizando validación de SA-E6)*

**Revisado (para evitar duplicación con SA-E6):**

| ID | Tarea | Story Points | Horas | Dependencias | Responsable |
|---|---|---|---|---|---|
| SA-T2.1 | Diseñar lógica de restauración | 2 | 4h | T1.1 | Chief Architect |
| SA-T2.2 | Implementar `Restore-HermesEnterpriseSandbox` | 3 | 6h | T2.1, T1.2 | Enterprise Engineer |
| SA-T2.3 | Implementar limpieza de artefactos post-snapshot | 3 | 6h | T2.2 | Senior Engineer |
| SA-T2.4 | Integrar restauración con Supervisor (modo recovery) | 3 | 6h | T2.2, T1.4 | Enterprise Engineer |
| SA-T2.5 | Documentar Restore Engine | 2 | 4h | T2.2 | Enterprise Engineer |

**Total Épica E2 (revisado): 13 SP / 26h**

### Épica SA-E3: Motor de Rollback (8 SP / 16h)

| ID | Tarea | Story Points | Horas | Dependencias | Responsable |
|---|---|---|---|---|---|
| SA-T3.1 | Diseñar estrategia de rollback | 1 | 2h | T1.1 | Chief Architect |
| SA-T3.2 | Implementar `Rollback-HermesEnterpriseSandbox` | 5 | 10h | T3.1, T2.2 | Enterprise Engineer |
| SA-T3.3 | Implementar rollback atómico con transacción | 3 | 6h | T3.2 | Senior Engineer |
| SA-T3.4 | Integrar rollback con Transaction Log | 2 | 4h | T3.2 | Enterprise Engineer |
| SA-T3.5 | Documentar Rollback Engine | 2 | 4h | T3.2 | Enterprise Engineer |

**Total Épica E3: 13 SP / 26h** *(Se consolida con diseño de T3.1 que es trivial)*

**Revisado:**

| ID | Tarea | Story Points | Horas | Dependencias | Responsable |
|---|---|---|---|---|---|
| SA-T3.1 | Implementar `Rollback-HermesEnterpriseSandbox` | 5 | 10h | T2.2, T1.2 | Enterprise Engineer |
| SA-T3.2 | Implementar rollback atómico con transacción | 3 | 6h | T3.1 | Senior Engineer |
| SA-T3.3 | Integrar rollback con Transaction Log | 2 | 4h | T3.1, T5.1 | Enterprise Engineer |
| SA-T3.4 | Documentar Rollback Engine | 1 | 2h | T3.1 | Enterprise Engineer |

**Total Épica E3 (revisado): 11 SP / 22h**

### Épica SA-E4: Motor de Recovery (16 SP / 32h)

| ID | Tarea | Story Points | Horas | Dependencias | Responsable |
|---|---|---|---|---|---|
| SA-T4.1 | Diseñar máquina de estados de recovery | 2 | 4h | T1.1, T3.1 | Chief Architect |
| SA-T4.2 | Implementar `Invoke-HermesEnterpriseRecovery` | 5 | 10h | T4.1, T2.4 | Enterprise Engineer |
| SA-T4.3 | Implementar recovery automático con reintentos | 3 | 6h | T4.2 | Senior Engineer |
| SA-T4.4 | Implementar recovery interactivo con menú | 3 | 6h | T4.2, T4.3 | Enterprise Engineer |
| SA-T4.5 | Integrar recovery con ExecutionSupervisor | 3 | 6h | T4.2, T1.4 | Enterprise Engineer |
| SA-T4.6 | Documentar Recovery Engine | 2 | 4h | T4.2 | Enterprise Engineer |

**Total Épica E4: 18 SP / 36h**

### Épica SA-E5: Transaction Log (10 SP / 20h)

| ID | Tarea | Story Points | Horas | Dependencias | Responsable |
|---|---|---|---|---|---|
| SA-T5.1 | Diseñar formato de transaction log | 2 | 4h | - | Chief Architect |
| SA-T5.2 | Implementar `Write-HermesEnterpriseTransactionLog` | 3 | 6h | T5.1 | Enterprise Engineer |
| SA-T5.3 | Implementar `Get-HermesEnterpriseTransactionLog` | 2 | 4h | T5.2 | Senior Engineer |
| SA-T5.4 | Implementar cadena de hashes para inmutabilidad | 3 | 6h | T5.2 | Enterprise Engineer |
| SA-T5.5 | Implementar exportación de transaction log | 2 | 4h | T5.2 | Senior Engineer |
| SA-T5.6 | Integrar transaction log en todos los engines | 2 | 4h | T5.2, T4.5 | Enterprise Engineer |
| SA-T5.7 | Documentar Transaction Log | 1 | 2h | T5.2 | DevOps Lead |

**Total Épica E5: 15 SP / 30h** *(Revisado para consolidar)*

**Revisado:**

| ID | Tarea | Story Points | Horas | Dependencias | Responsable |
|---|---|---|---|---|---|
| SA-T5.1 | Implementar `Write-HermesEnterpriseTransactionLog` con hash chain | 5 | 10h | - | Enterprise Engineer |
| SA-T5.2 | Implementar consulta y exportación del log | 3 | 6h | T5.1 | Senior Engineer |
| SA-T5.3 | Integrar en todos los componentes del Sprint A | 2 | 4h | T5.1, T4.5 | Enterprise Engineer |

**Total Épica E5 (revisado): 10 SP / 20h**

### Épica SA-E6: Suite de Pruebas y Validación (13 SP / 26h)

| ID | Tarea | Story Points | Horas | Dependencias | Responsable |
|---|---|---|---|---|---|
| SA-T6.1 | Implementar pruebas unitarias del Snapshot Engine | 3 | 6h | T1.2 | QA Lead |
| SA-T6.2 | Implementar pruebas unitarias del Restore Engine | 3 | 6h | T2.2 | QA Lead |
| SA-T6.3 | Implementar pruebas de rollback | 2 | 4h | T3.1 | QA Lead |
| SA-T6.4 | Implementar pruebas end-to-end de recovery | 3 | 6h | T4.2 | QA Lead |
| SA-T6.5 | Implementar pruebas de integridad con datos corruptos | 2 | 4h | T6.1 | QA Lead |
| SA-T6.6 | Implementar pruebas de performance de snapshots grandes | 2 | 4h | T1.2 | QA Lead |
| SA-T6.7 | Implementar `Test-HermesEnterpriseSnapshotIntegrity` | 3 | 6h | T1.2, T5.1 | Enterprise Engineer |
| SA-T6.8 | Implementar `Test-HermesEnterpriseAllSnapshots` | 2 | 4h | T6.7 | Senior Engineer |
| SA-T6.9 | Documentar suite de pruebas | 1 | 2h | T6.4 | QA Lead |

**Total Épica E6: 21 SP / 42h** *(Revisado para consolidar)*

**Revisado:**

| ID | Tarea | Story Points | Horas | Dependencias | Responsable |
|---|---|---|---|---|---|
| SA-T6.1 | Implementar pruebas unitarias (Snapshot + Restore) | 5 | 10h | T1.2, T2.2 | QA Lead |
| SA-T6.2 | Implementar pruebas de integración (Rollback + Recovery) | 3 | 6h | T3.1, T4.2 | QA Lead |
| SA-T6.3 | Implementar `Test-HermesEnterpriseSnapshotIntegrity` | 3 | 6h | T1.2, T5.1 | Enterprise Engineer |
| SA-T6.4 | Implementar pruebas end-to-end con fallos simulados | 3 | 6h | T4.2 | QA Lead |
| SA-T6.5 | Documentar suite de pruebas | 1 | 2h | T6.4 | QA Lead |

**Total Épica E6 (revisado): 15 SP / 30h**

---

## 6. Resumen de Story Points por Épica

| Épica | Story Points | Horas | Porcentaje |
|---|---:|---:|---:|
| SA-E1: Motor de Snapshots | 20 | 40h | 36% |
| SA-E2: Motor de Restauración | 13 | 26h | 23% |
| SA-E3: Motor de Rollback | 11 | 22h | 20% |
| SA-E4: Motor de Recovery | 18 | 36h | 33% |
| SA-E5: Transaction Log | 10 | 20h | 18% |
| SA-E6: Suite de Pruebas y Validación | 15 | 30h | 27% |
| **TOTAL** | **40** | **80h** | **100%** |

*Nota: Los porcentajes suman >100% porque algunas tareas tienen dependencias y se ejecutan en paralelo.*

---

## 7. Cronograma del Sprint (4 Semanas)

### Semana 1: Fundamentos
| Día | Actividad | Entregable |
|---|---|---|
| L | Kickoff + Diseño de modelos de datos | Modelos JSON documentados |
| M | Implementación de Snapshot Engine (T1.2) | `New-HermesEnterpriseSnapshot` funcional |
| W | Implementación de Listing + Transaction Log base (T1.3, T5.1) | Snapshots listables, log escribiendo |
| T | Integración con ExecutionSupervisor (T1.4) | Snapshots automáticos en flujo |
| F | Integración completa de Transaction Log (T5.3) | Log completo con hash chain |

### Semana 2: Restauración y Rollback
| Día | Actividad | Entregable |
|---|---|---|
| L | Implementación de Restore Engine (T2.2) | `Restore-HermesEnterpriseSandbox` funcional |
| M | Validación de integridad + Limpieza artefactos (T2.3, T2.4) | Restauración robusta |
| W | Implementar Rollback Engine (T3.1) | `Rollback-HermesEnterpriseSandbox` funcional |
| T | Pruebas unitarias Snapshot + Restore (T6.1) | Tests verdes |
| F | Integración Restoration con Supervisor (T2.5) | Flujo completo de restore |

### Semana 3: Recovery
| Día | Actividad | Entregable |
|---|---|---|
| L | Diseño e implementación de Recovery Engine (T4.1, T4.2) | Máquina de estados + recovery básico |
| M | Recovery automático con reintentos (T4.3) | Auto-recovery funcional |
| W | Recovery interactivo con menú (T4.4) | Menú de opciones |
| T | Integración completa de Recovery (T4.5, T3.3) | Supervisor con recovery completo |
| F | Pruebas de integración Rollback + Recovery (T6.2) | Tests verdes |

### Semana 4: Pruebas y Stabilización
| Día | Actividad | Entregable |
|---|---|---|
| L | Pruebas de integridad y E2E con fallos (T6.3, T6.4) | Suite completa ejecutando |
| M | Documentación de Snapshot Integrity (T6.3, SA-US-07) | Functions documentadas |
| W | Documentación completa del Sprint (T1.6, T2.5, T3.4, T4.6, T6.5) | Docs completas |
| T | Bug fixes + Performance tuning | Stable build |
| F | Sprint Review + Retro + Demo | Sprint completado |

---

## 8. Equipo y Asignación de Roles

| Rol | Nombre | Responsabilidades | Carga |
|---|---|---|---|
| Chief Architect | TBD | Diseño de arquitectura, modelos de datos, máquina de estados | 25% |
| Enterprise Engineer | TBD | Implementación core de todos los engines | 100% |
| Senior Engineer | TBD | Implementación de features secundarias | 75% |
| Senior Engineer 2 | TBD | Features de soporte (listing, export, etc.) | 50% |
| QA Lead | TBD | Suite de pruebas completa | 75% |
| DevOps Lead | TBD | Infraestructura de testing, CI | 25% |
| Product Owner | TBD | Priorización, aceptación de historias | 15% |

---

## 9. Dependencias

### Dependencias Externas
| Depende de | Documento/Componente | Estado | Riesgo |
|---|---|---|---|
| Línea base Fase 0.5 | Arquitectura actual | Completada | Bajo |
| ExecutionSupervisor.ps1 | Motor de ejecución | Existente | Bajo |
| ExecutionLogger.ps1 | Sistema de logging | Existente | Bajo |
| PowerShell 7.4+ | Runtime | Existente | Bajo |

### Dependencias Internas (entre tareas del Sprint)
```
T5.1 (Transaction Log) ──────┐
                              ├──► T5.3 (Integrar en todos) ──► T6.1 (Tests)
T1.1 (Modelo datos) ─────────┤
                              ├──► T1.2 (Snapshot Engine) ──► T2.2 (Restore) ──► T3.1 (Rollback) ──► T4.2 (Recovery)
T1.3 (Listing)               │
                              └──► T1.4 (Integración)
```

### Bloqueantes
| Bloqueante | Impacto | Mitigación |
|---|---|---|
| Retraso en diseño de modelo de datos | Bloquea todas las implementaciones | Chief Architect dedicado semana 1 |
| Fallo en pruebas de integridad | Bloquea release | Buffer de 2 días en semana 4 |

---

## 10. Definición de Done (DoD) del Sprint

### DoD por Historia de Usuario
Cada historia de usuario está completa cuando:
- ✅ El código está implementado y funcionando
- ✅ Las pruebas unitarias pasan con ≥80% de cobertura
- ✅ El código sigue el `CODING_STANDARD.md` del proyecto
- ✅ Los nombres son descriptivos y en español (convención HERMES)
- ✅ Los comentarios son detallados
- ✅ La documentación de la función está actualizada
- ✅ La historia ha sido revisada por otro ingeniero (peer review)
- ✅ El Product Owner ha aceptado la historia

### DoD del Sprint Completo
El sprint está completo cuando:
- ✅ Todas las historias de usuario están aceptadas
- ✅ La suite de pruebas de recovery pasa 100%
- ✅ El SnapshotEngine se integra sin romper `ExecutionSupervisor.ps1`
- ✅ La restauración funciona en modo automático e interactivo
- ✅ El transaction log es verificable (hash chain)
- ✅ La documentación del Sprint está publicada
- ✅ CHANGELOG.md está actualizado
- ✅ SRS_HERMES_ENTERPRISE.md refleja las nuevas capacidades
- ✅ Arquitectura está actualizada con los nuevos componentes
- ✅ Commit atómico con Conventional Commit (`feat(sandbox): add safe sandbox`)
- ✅ Rate of recovery ≥ 95% en pruebas de integración

---

## 11. Riesgos y Mitigación

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Snapshots demasiado grandes (>1GB) | Media | Alto | Implementar compresión gzip desde T1.1 |
| Corrupción de snapshots en disco | Baja | Crítico | Validación pre-uso + hash en T6.3 |
| Recovery automático genera loops infinitos | Media | Alto | Límite de reintentos (3) + fallback a modo interactivo |
| Performance degradation por snapshots frecuentes | Alta | Medio | Snapshots solo post-paso completado (no durante) |
| Complejidad excesiva en máquina de estados | Media | Medio | Diagramas claros + pruebas exhaustivas |
| Incompatibilidad con futuras versiones | Baja | Medio | Formato versionado (v1.0 del modelo) |

---

## 12. Criterios de Éxito del Sprint

### Tangibles
- [ ] SnapshotEngine crea snapshots automáticamente tras cada paso
- [ ] SnapshotEngine permite snapshots nombrados manualmente
- [ ] RestoreEngine restaura un snapshot y continúa ejecución
- [ ] Rollback vuelve a snapshot anterior y limpia artefactos
- [ ] RecoveryEngine detecta fallos y ofrece opciones de recovery
- [ ] TransactionLog es completo, inmutable y exportable
- [ ] Suite de pruebas de recovery con ≥80% cobertura
- [ ] Snapshot validation detecta corrupción correctamente

### Cuantitativos
- [ ] Recovery exitoso en ≥95% de escenarios probados
- [ ] Time to recovery P50 < 30 segundos
- [ ] Snapshot overhead < 10% del tiempo total de ejecución
- [ ] Zero data loss en modo auto-recovery con reintentos

### Cualitativos
- [ ] El sistema es confiable y predecible
- [ ] Los usuarios pueden confiar en que su progreso no se pierde
- [ ] La auditoría es completa y verificable
- [ ] El código es mantenible y bien documentado

---

## 13. Decisiones de Diseño

### D-SA-01: Formato de Snapshot
**Opciones consideradas:**
- Opción A: Un solo archivo JSON con todo embebido (base64 para binarios)
- Opción B: Directorio con archivos separados (JSON + artefactos)
- Opción C: Archivo ZIP con estructura interna

**Decisión:** Opción B
**Justificación:** Facilita la inspección manual, debugging, y permite archivos grandes sin serialización

### D-SA-02: Estrategia de Rollback
**Opciones consideradas:**
- Opción A: Rollback destructive (elimina archivos)
- Opción B: Rollback non-destructive (archivos quedan, pero no se usan)
- Opción C: Rollback a snapshot previo + recreación desde ese punto

**Decisión:** Opción A (destructive, con backup)
**Justificación:** Simplicidad y alineación con el comportamiento esperado. Se genera backup previo.

### D-SA-03: Inmutabilidad del Transaction Log
**Opciones consideradas:**
- Opción A: Append-only sin hashes
- Opción B: Append-only con cadena de hashes (blockchain-style)
- Opción C: Append-only con firma digital

**Decisión:** Opción B
**Justificación:** Balance entre integridad y complejidad. Permite detección de manipulación sin necesidad de infraestructura de certificados.

---

## 14. Consideraciones de Seguridad

- Los snapshots NO deben incluir secretos ni credenciales
- El transaction log debe ser protegido contra escritura no autorizada
- Los hashes SHA-256 previenen manipulación inadvertida
- El rollback debe registrar quién lo ejecutó y desde qué contexto
- Considerar encriptación opcional de snapshots si contienen datos sensibles (futuro)

---

## 15. Apertura al Sprint B

El Sprint A establece los cimientos de seguridad que el Sprint B aprovechará:
- El `Project Generator` puede usar snapshots para checkpoint durante la generación
- El `Template Engine` puede usar rollbacks si un template genera archivos incorrectos
- El `Bootstrap Engine` puede usar recovery si un paso de scaffolding falla

→ Continuar con [Sprint B: Professional Project Generator](03_SPRINT_B.md)

---

## 16. Glosario

| Término | Definición |
|---|---|
| Snapshot | Captura completa del estado del Sandbox en un punto específico |
| Rollback | Reversión del estado a un snapshot anterior |
| Recovery | Proceso de continuar una ejecución fallida desde el último estado válido |
| Transaction Log | Registro inmutable de todas las operaciones con hash encadenado |
| Auto-Recovery | Modo donde el sistema intenta recuperarse automáticamente |
| Integrity Check | Verificación de que un snapshot no está corrupto |
| Checkpoint | Punto donde se guarda un snapshot automáticamente |

---

*Documento de Diseño — Sprint A: Safe Sandbox*
*Versión 1.0.0 — 2026-07-07*
*HERMES-ENTERPRISE Roadmap*
