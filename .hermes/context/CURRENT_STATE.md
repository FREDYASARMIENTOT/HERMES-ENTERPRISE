# CURRENT_STATE — HERMES-ENTERPRISE
## Versión del Framework: 1.0.0-bootstrap
## Última actualización: 2026-07-10

---

## Estado General

**Fase actual**: 5 — Bootstrap Engine v1.0 ✅ COMPLETADO

**Release**: Bootstrap Engine v1.0 cerrado y listo para producción conceptual.

---

## Arquitectura Bootstrap Engine v1.0

El motor de bootstrap está completamente estable. Los contratos están congelados.
El flujo de creación de proyectos ya está definido end-to-end.

### Flujo Oficial

```
Usuario
  ↓
Start-HermesProject           (Entry Point único)
  ↓
ProjectArchitecture           (Contrato arquitectónico - Sprint 5.4)
  ↓
New-BootstrapRequestFromProjectArchitecture (Converter - Sprint 5.5)
  ↓
BootstrapRequest              (DTO inmutable)
  ↓
BootstrapState                (Estado interno - CONGELADO)
  ↓
BootstrapOrchestrator         (Coordinador - CONGELADO)
```

### Componentes Congelados

NO MODIFICAR sin aprobación explícita del arquitecto:

- `motor/bootstrap/request/BootstrapRequest.ps1`
- `motor/bootstrap/engine/BootstrapState.ps1`
- `motor/bootstrap/engine/New-BootstrapStateFromRequest.ps1`
- `motor/bootstrap/engine/BootstrapOrchestrator.ps1`
- `motor/bootstrap/engine/BootstrapWizard.ps1`
- `motor/bootstrap/engine/environment/EnvironmentManager.ps1`

### Componentes Implementados (no congelados)

- `motor/bootstrap/request/New-BootstrapRequestFromProjectArchitecture.ps1` (Sprint 5.5)
- `motor/bootstrap/request/BootstrapRequestBuilder.ps1` (legacy, pendiente de revisión)
- `motor/bootstrap/Start-HermesProject.ps1` (reimplementado Sprint 5.6)

---

## Contratos Documentados

Ubicación: `.hermes/specs/`

1. **PROJECT_ARCHITECTURE_CONTRACT.md** — Define cómo se describe un proyecto antes de crearlo.
2. **PROJECT_STRUCTURE_SEQUENCE.md** — Secuencia de creación desde el usuario hasta el proyecto generado.
3. Todos los proyectos poseen obligatoriamente `FrontEnd/` y `BackEnd/` aunque estén vacíos.

---

## Documentación de Skills

- `.hermes/skills/hermes-enterprise-development/SKILL.md` — Metodología completa de desarrollo del framework.
- Contiene reglas arquitectónicas, de sprint, de calidad, convenciones y lecciones aprendidas.

---

## Estado del Context Package

Los tres archivos del Context Package están sincronizados con el estado real del repo:

- `CURRENT_STATE.md` — este documento
- `NEXT_TASK.md` — próxima tarea (Fase 6 — Capabilities)
- `SESSION_HANDOFF.json` — metadata de handoff entre sesiones

---

## Métricas

| Indicador | Valor |
|-----------|-------|
| Sprint de cierre | 5.7 |
| Commits totales Bootstrap | ~25 |
| Componentes congelados | 6 |
| Contratos documentados | 2 |
| Tests unitarios | 5 archivos (ver `pruebas/unitarias/`) |
| Skills documentadas | 1 |

---

## Lecciones Clave Consolidadas

1. ProjectArchitecture SIEMPRE precede a BootstrapRequest.
2. Start-HermesProject es el único Entry Point público.
3. Bootstrap Engine nunca conoce Azure.
4. Providers nunca conocen Bootstrap.
5. Capabilities nunca interactúan directamente con el usuario.
6. Scope Lock obligatorio en cada Sprint.
7. Un Sprint = una responsabilidad, un Commit = un artefacto.
8. Toda implementación requiere test, verificación ad-hoc y limpieza.

---

## Listo para Fase 6

Bootstrap Engine v1.0 está completamente estabilizado.
Las próximas capacidades (Azure, GitHub, Docker, Data Factory, etc.) llegarán como módulos desacoplados.
El motor es independiente de cualquiera de ellas.
