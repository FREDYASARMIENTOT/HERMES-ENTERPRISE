---
titulo: Bootstrap Engine - Secuencia de Ejecución
fase: 4.5A.1
estado: aprobado
fecha: 2026-07-10
relacionado: documentacion/bootstrap-engine/bootstrap-contracts.md
proposito: Flujo de ejecución del bootstrap. Lectura < 2 minutos.
---

# Bootstrap Engine - Secuencia de Ejecución

## Flujo Completo

```
Usuario
   │
   ▼
┌─────────────────────────┐
│ Start-HermesProject     │  ← launcher
└───────────┬─────────────┘
            │ construye
            ▼
┌─────────────────────────┐
│ BootstrapRequest        │  contrato: datos del usuario
└───────────┬─────────────┘
            │ convierte
            ▼
┌─────────────────────────┐
│ BootstrapStateFactory   │  función: New-BootstrapStateFromRequest
└───────────┬─────────────┘
            │ crea
            ▼
┌─────────────────────────┐
│ BootstrapState          │  contrato: estado del motor
└───────────┬─────────────┘
            │ coordina
            ▼
┌─────────────────────────┐
│ BootstrapOrchestrator   │  función: Invoke-BootstrapOrchestrator
└───────────┬─────────────┘
            │ invoca en orden
            ▼
┌─────────────────────────────────────────────────┐
│ BootstrapWizard        (Validate-WizardData)    │
│ EnvironmentManager     (Invoke-EnvironmentManager) │
│ GitManager             (Invoke-GitManager)       │
│ ContextEngine          (Invoke-ContextEngine)    │
│ VSCodeManager          (Invoke-VSCodeManager)    │
└───────────┬─────────────┘
            │ retorna
            ▼
      Bootstrap Report
```

---

## Tabla de Pasos

| # | Componente (función pública) | Entrada | Salida | ¿Muta State? |
|---|------------------------------|---------|--------|--------------|
| 1 | Start-HermesProject | Parámetros CLI + interacción | `BootstrapRequest` | No (crea Request) |
| 2 | BootstrapStateFactory (`New-BootstrapStateFromRequest`) | `BootstrapRequest` | `BootstrapState` Fase00 | Crea el State |
| 3 | BootstrapWizard (`Validate-WizardData`) | `Request` + `State` | `State` con datos validados | Sí (opcional) |
| 4 | EnvironmentManager (`Invoke-EnvironmentManager`) | `Request` + `State` | `State` actualizado | Sí |
| 5 | GitManager (`Invoke-GitManager`) | `Request` + `State` | `State` actualizado | Sí |
| 6 | ContextEngine (`Invoke-ContextEngine`) | `Request` + `State` | `State` actualizado | Sí |
| 7 | VSCodeManager (`Invoke-VSCodeManager`) | `Request` + `State` | `State` actualizado | Sí |
| 8 | BootstrapOrchestrator | `Request` + `State` final | Reporte de ejecución | No (ya cerrado) |

---

## Matriz de Mutaciones del Estado

| Componente | Fase inicial | Fase final | Campos que muta |
|------------|--------------|------------|-----------------|
| BootstrapStateFactory | — | Fase00 / Pending | crea Id, StartedAt, Status=Pending |
| BootstrapWizard | Fase00 | Fase00 | agrega datos validados (si son opcionales) |
| EnvironmentManager | Fase00 | Fase01 | registra runtime detectado, entorno listo |
| GitManager | Fase01 | Fase02 | registra URL remoto, rama, commit inicial |
| ContextEngine | Fase02 | Fase03 | registra artefactos generados, hash |
| VSCodeManager | Fase03 | Fase04 | registra workspace abierto (Sí/No) |
| BootstrapOrchestrator | Fase04 | Completed/Failed | Status final, FinishedAt |

---

## Responsabilidades por Componente

**Start-HermesProject** — Único launcher.
Interactúa con el usuario → construye `BootstrapRequest` → invoca Factory → invoca Orchestrator → muestra reporte. **Nunca** crea carpetas, env, repo, ni contextos.

**BootstrapStateFactory** — Constructor puro.
Convierte `BootstrapRequest` a `BootstrapState` inicial. Sin I/O, sin managers, sin preguntas.

**BootstrapOrchestrator** — Coordinador.
Ejecuta los 5 managers en orden (Wizard→Environment→Git→Context→VSCode). Pasa `Request` + `State` a cada paso. **Nunca** usa `Read-Host` ni crea archivos.

**BootstrapWizard** — Validador mínimo.
Solo confirma que los datos del `Request` sean suficientes. Puede pedir datos **opcionales** faltantes, pero jamás repregunta `NombreProyecto` ni campos obligatorios (eso ya pertenece al Request).

**EnvironmentManager / GitManager / ContextEngine / VSCodeManager** — Managers ejecutores.
Cada uno tiene su dominio (entorno, repo, docs, IDE). No se conocen entre sí. Se comunican solo vía `BootstrapState`.

---

## Invariantes

1. `BootstrapRequest` **nunca se modifica** después del paso 1.
2. `BootstrapState` es el **único vehículo** de progreso y errores.
3. **Ningún manager** recibe `BootstrapRequest` directamente; el Orchestrator extrae lo necesario.
4. Solo `Start-HermesProject` habla con el usuario.
5. `BootstrapWizard` **jamás repregunta** datos que ya están en `BootstrapRequest`.

---

## Componentes

| Componente | Estado |
|------------|--------|
| BootstrapState | 🔵 Congelado |
| BootstrapOrchestrator | 🔵 Congelado |
| BootstrapWizard | 🔵 Congelado |
| EnvironmentManager | 🔵 Congelado |
| GitManager | 🔵 Congelado |
| ContextEngine | 🔵 Congelado |
| VSCodeManager | 🔵 Congelado |
| BootstrapRequest | 🟡 Estable |
| BootstrapStateFactory | ⚪ Pendiente (4.5B) |
| Start-HermesProject | ⚪ Pendiente (Paso 5) |
