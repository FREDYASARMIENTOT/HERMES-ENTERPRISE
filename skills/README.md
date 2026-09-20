# Skills — HERMES-ENTERPRISE

Directorio de skills operativas para Cline.

## Skills disponibles

| Skill | Capacidad | Archivo |
|-------|-----------|---------|
| **Crear Proyecto** | Ciclo E2E de creación, despliegue, validación y recuperación de proyectos Hermes hijo | `hermes-enterprise-create-project/SKILL.md` |

## ¿Cómo usar una skill?

Cada skill contiene reglas operativas que Cline debe aplicar cuando una tarea involucre la capacidad correspondiente.

**Skill "Crear Proyecto":** Aplicar cuando una tarea involucre crear, desplegar, validar, reparar o recuperar un proyecto Hermes hijo. Cubre Portal, Factory, Child CI, Control Plane, OIDC, Azure, readiness, functional tests, evidence, persistencia y E2E.

## Convención

- Cada skill reside en `skills/<nombre-capacidad>/SKILL.md`
- El nombre lógico identifica claramente la capacidad (ej: `hermes-enterprise-create-project`)
- Las skills se referencian por su nombre en los reportes de estado