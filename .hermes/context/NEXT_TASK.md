# NEXT TASK

## Step
**Paso 4.5** — Capa de Solicitud de Bootstrap

## Goal
Implementar separación DTO/State para evitar mezcla de responsabilidades.

## Files to Create (in order)
1. `motor/bootstrap/engine/BootstrapRequest.ps1` — DTO inmutable
2. `motor/bootstrap/engine/BootstrapRequestBuilder.ps1` — pregunta al usuario, construye DTO
3. `motor/bootstrap/engine/ConvertToBootstrapState.ps1` — traduce DTO a estado
4. `pruebas/unitarias/bootstrap/Test-BootstrapRequest.ps1` — validación
5. `documentacion/bootstrap-engine/BootstrapRequest.spec.md` — documentación <200 líneas

## Verification
- Tests unitarios: PASS
- Working tree: clean
- Commit atómico
- Script temporal limpiado

## Constraints
- NO modificar componentes congelados
- Usar español en nombres
- Comentarios solo en lógica crítica
- Funciones con responsabilidad única

## Exit Criteria
- BootstrapRequest: DTO con propiedades inmutables
- BootstrapRequestBuilder: pregunta usuario, construye DTO
- ConvertToBootstrapState: traduce DTO a estado
- Tests: validación de DTO + conversión
- Spec: documentación técnica <200 líneas
- Git: commit limpio, working tree sin cambios
