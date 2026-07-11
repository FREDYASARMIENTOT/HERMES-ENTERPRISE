# NEXT_TASK — HERMES-ENTERPRISE
## Próxima tarea: Fase 6 — Capabilities

---

## Objetivo General

Construir el sistema de Capabilities que permita a Hermes Enterprise consumir proveedores externos
(Azure, GitHub, Docker, Data Factory, etc.) **sin modificar** el Bootstrap Engine.

Las Capabilities son módulos desacoplados, registrables dinámicamente, con contratos estrictos.

---

## Siguiente Sprint Propuesto

### Sprint 6.0 — Capability Contract (Design Lock)

**Objetivo**: Definir formalmente qué es una Capability y cuál es su contrato.

**Entregables (solo documentación)**:
- `.hermes/specs/CAPABILITY_CONTRACT.md`
- `.hermes/specs/CAPABILITY_SEQUENCE.md`

**NO hacer**:
- ❌ Implementar código
- ❌ Crear Providers, Plugins, Builders
- ❌ Modificar Bootstrap Engine
- ❌ Crear tests
- ❌ Hacer commits

---

## Definición Propuesta de Capability

Una Capability es un módulo ejecutable que:

1. Tiene un nombre único.
2. Declara requisitos (input contract).
3. Produce recursos (output artifacts).
4. No interactúa con el usuario final.
5. Se registra en un CapabilityRegistry.
6. Es invocada por BootstrapOrchestrator V2 (posteriormente).
7. NO conoce BootstrapRequest ni BootstrapState.
8. NO conoce otros Providers.

---

## Secuencia esperada (Fase 6)

```
Usuario
  ↓
Start-HermesProject
  ↓
ProjectArchitecture (con CapacidadesSeleccionadas)
  ↓
BootstrapRequest
  ↓
BootstrapState
  ↓
BootstrapOrchestrator V2 (adapta para consumir Capabilities)
  ↓
CapabilityRegistry.Resolve
  ↓
Capability.Execute
  ↓
Resultado consolidado
```

---

## Prioridad de Capabilities

1. **Azure Resource Discovery** (ya existe parcialmente en pruebas — revisar)
2. **GitHub Repository Management**
3. **Docker Build / Push**
4. **Azure Data Factory Pipelines**
5. **Azure Storage**
6. **App Service Deployment**

---

## Criterios de Éxito para cada Capability

- ✅ Contrato documentado (`<CAPABILITY>_CONTRACT.md`)
- ✅ Secuencia documentada (`<CAPABILITY>_SEQUENCE.md`)
- ✅ Test unitario
- ✅ Verificación ad-hoc
- ✅ Sin modificar componentes congelados
- ✅ Sin lógica duplicada
- ✅ Commit atómico

---

## Reglas Permanentes

- **No romper el Bootstrap Engine.**
- **Una Capability = un archivo de implementación + un test + una verificación.**
- **Capabilities nunca se invocan desde el Entry Point.**
- **Capabilities nunca escriben en BootstrapState directamente.**
- **Todo se devuelve como resultado de la ejecución (no efectos secundarios).**

---

Esperando aprobación explícita para iniciar Sprint 6.0.
