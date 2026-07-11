---
name: hermes-enterprise-development
description: Metodología de desarrollo para HERMES-ENTERPRISE Framework
version: 1.0.0
author: Hermes Agent
created: 2026-07-10
---

# HERMES-ENTERPRISE Development Skill

## Propósito

Esta skill define las reglas, patrones y metodología para desarrollar el HERMES-ENTERPRISE Framework. 
Aplícala en cada sprint para mantener consistencia arquitectónica, calidad de código y trazabilidad.

## Reglas Fundamentales

### 1. Arquitectónicas

- **ProjectArchitecture siempre precede a BootstrapRequest**: Todo proyecto debe pasar por el contrato arquitectónico antes de generar la solicitud de bootstrap.
- **Todo proyecto posee FrontEnd/ y BackEnd/**: Estructura mínima obligatoria, aunque estén vacíos.
- **Start-HermesProject es el único Entry Point público**: Ningún otro componente debe ser invocado directamente desde fuera del motor.
- **Bootstrap Engine nunca conoce Azure**: El motor es agnóstico al proveedor cloud.
- **Providers nunca conocen Bootstrap**: Implementan contratos específicos, no saben quiénes los consumen.
- **Capabilities nunca interactúan directamente con el usuario**: Solo reciben instrucciones y retornan resultados.

### 2. de Sprint

- **Un Sprint = una responsabilidad**: Cada sprint debe tener un objetivo único y acotado.
- **Un Commit = un artefacto**: Cada commit representa una unidad atómica de funcionalidad.
- **Scope Lock obligatorio**: No agregar funcionalidades no planificadas durante el sprint.
- **Design Lock antes de implementar**: Si el problema es de modelo, detener y rediseñar antes de codificar.

### 3. de Calidad

- **Toda implementación requiere test unitario**: Sin excepciones.
- **Toda implementación requiere verificación ad-hoc**: Script temporal en `hermes/verification-scripts/`.
- **Toda verificación ad-hoc requiere limpieza**: Eliminar el script después de ejecutar.
- **Commit solo después de verificación exitosa**: Working tree limpio, tests verdes.

## Flujo Bootstrap Engine v1.0

```
Usuario
  ↓
Start-HermesProject           (Entry Point público)
  ↓
ProjectArchitecture           (Contrato arquitectónico - Sprint 5.4)
  ↓
New-BootstrapRequestFromProjectArchitecture (Converter - Sprint 5.5)
  ↓
BootstrapRequest              (DTO inmutable)
  ↓
BootstrapState                (Estado interno - congelado)
  ↓
BootstrapOrchestrator         (Coordinador - pendiente Fase 6)
```

## Componentes Congelados

NO MODIFICAR estos componentes sin aprobación explícita:

- `motor/bootstrap/engine/BootstrapState.ps1`
- `motor/bootstrap/engine/New-BootstrapStateFromRequest.ps1`
- `motor/bootstrap/request/BootstrapRequest.ps1`
- `motor/bootstrap/request/BootstrapRequestBuilder.ps1`
- `motor/bootstrap/engine/BootstrapWizard.ps1`
- `motor/bootstrap/engine/New-BootstrapStateFromRequest.ps1`

## Convenciones de Nombres

- **Archivos**: PascalCase (ej: `Start-HermesProject.ps1`)
- **Funciones públicas**: Verbo-Prefijo-Sustantivo (ej: `Invoke-BootstrapOrchestrator`)
- **Funciones privadas**: Verbo-Sustantivo (ej: `Convertir-RespuestaSN`)
- **Variables**: PascalCase (ej: `$ProyectoArquitectura`)
- **Parámetros**: PascalCase (ej: `-NombreProyecto`)

## Nombres en Español

- Usar español para variables, parámetros y funciones del framework.
- Excepciones: términos técnicos consolidados en inglés (Bootstrap, Provider, Plugin, etc.)

## Estructura de Archivos Obligatoria para Todo Sprint

1. **Implementación**: `motor/<área>/<Componente>.ps1`
2. **Test unitario**: `pruebas/unitarias/Test-<Componente>.ps1`
3. **Verificación ad-hoc**: `hermes/verification-scripts/hermes-verify-sprint-X.Y.ps1`

## Prohibiciones

- ❌ Modificar componentes congelados sin aprobación
- ❌ Agregar lógica de proveedor (Azure/GitHub/Docker) en el Bootstrap Engine
- ❌ Crear Providers, Capabilities o Plugins sin contrato previo
- ❌ Saltarse tests unitarios o verificación ad-hoc
- ❌ Hacer commit sin working tree limpio
- ❌ Expandir scope del sprint sin aprobación explícita

## Validaciones de Componentes

Todo componente debe validar:
- **Tipos de entrada**: Usar `[PSCustomObject]` con `PSTypeName` explícito
- **Tipos de salida**: Documentar con `[OutputType([PSCustomObject])]`
- **Propiedades mínimas**: Validar presencia y contenido antes de procesar
- **Inmutabilidad**: No modificar objetos de entrada, crear copias si es necesario

## Próximos Pasos (Fase 6 - Capabilities)

1. Diseñar contrato de Capability (CapabilityContract.ps1)
2. Implementar CapabilityRegistry (registro dinámico)
3. Adaptar BootstrapOrchestrator para consumir capabilities
4. Implementar primera capability: Azure

## Lecciones Aprendidas (Sprints 5.4 - 5.6)

### Sprint 5.4 - Design Lock
- **Problema**: No había contrato arquitectónico definido
- **Solución**: Crear ProjectArchitecture como contrato puro
- **Lección**: Definir contratos antes de implementar

### Sprint 5.5 - Converter
- **Problema**: No existía transición entre arquitectura y solicitud
- **Solución**: Implementar New-BootstrapRequestFromProjectArchitecture
- **Lección**: Separar responsabilidades claramente (contrato vs. solicitud)

### Sprint 5.6 - Entry Point
- **Problema**: Start-HermesProject no seguía el nuevo flujo arquitectónico
- **Solución**: Reimplementar siguiendo ProjectArchitecture
- **Lección**: El entry point debe reflejar la arquitectura actual

## Recursos

- **Documentación de arquitectura**: `.hermes/specs/`
- **Contratos**: `.hermes/specs/ARCHITECTURE_CONTRACTS.md`
- **Flujo de ejecución**: `.hermes/specs/EXECUTION_FLOW.md`
- **Componentes**: `motor/bootstrap/`

## Checklist Pre-Commit

- [ ] Working tree limpio
- [ ] Tests unitarios pasando
- [ ] Verificación ad-hoc ejecutada
- [ ] Script de verificación eliminado
- [ ] Componentes congelados intactos
- [ ] Documentación actualizada (si aplica)
- [ ] Commit message siguiendo convención (feat/fix/chore/...)
