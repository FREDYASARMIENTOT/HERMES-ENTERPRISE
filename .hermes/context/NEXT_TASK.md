# Task: Sprint 5.3 - BootstrapOrchestrator V2

## Objective

Refactorizar `BootstrapOrchestrador` para consumir el nuevo contrato `BootstrapRequest + BootstrapState` en lugar de los parámetros tradicionales (`-ProjectPath` y `-ContextPath`).

## Acceptance Criteria

### Funcionalidad
- [ ] `Invoke-BootstrapOrchestrador` acepta parámetros `-BootstrapRequest` y `-BootstrapState`
- [ ] Elimina parámetro `-ProjectPath`
- [ ] Elimina parámetro `-ContextPath`
- [ ] Integra con `New-BootstrapStateFromRequest` para inicializar estado
- [ ] Actualiza `BootstrapState` con metadatos: `BootstrapRequestId`, `TimestampInicio`, `TimestampFin`
- [ ] Mantiene SRP (Single Responsibility Principle) como coordinador
- [ ] No introduce nueva lógica de negocio

### Restricciones
- [ ] NO modificar `BootstrapState.ps1` (congelado)
- [ ] NO modificar `BootstrapRequest.ps1` (congelado)
- [ ] NO modificar `New-BootstrapStateFromRequest.ps1`
- [ ] Usar español para comentarios
- [ ] Comentarios solo en lógica crítica

### Verificación
- [ ] Working tree limpio
- [ ] Commit atómico
- [ ] Pruebas existentes pasan
- [ ] Sin romper contracts documentados

## Contexto

- **Documentación**: `documentacion/bootstrap-engine/contratos-arquitectonicos.md`
- **Flujo**: `documentacion/bootstrap-engine/BOOTSTRAP_SEQUENCE.md`
- **Componentes congelados**: Ver `CURRENT_STATE.md`
- **Principios**: Regla de Oro, 1 commit = 1 responsabilidad

## Notas

Este sprint mantiene el patrón de iteraciones pequeñas y verificables. La meta es que el orquestador consuma el DTO y devuelva el estado finalizado, completando el flujo:

```
Usuario → BootstrapRequest → New-BootstrapStateFromRequest → BootstrapOrchestrador → BootstrapState final
```
