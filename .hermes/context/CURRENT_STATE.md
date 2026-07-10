# CURRENT STATE

## Project Overview
HERMES Enterprise: PowerShell framework for autonomous AI software engineering.

## Current Phase
**Paso 4.5** (in progress) — Capa de Solicitud de Bootstrap

## Architecture Decision
Separación de responsabilidades:
- **BootstrapRequest** (DTO): captura datos del usuario
- **BootstrapState** (estado): estado interno del motor
- **ConvertToBootstrapState**: traduce DTO a estado

Esto permite múltiples interfaces (CLI, VS Code, API) sin modificar el motor.

## Components Status

### ✅ Frozen (Paso 4 completado)
- BootstrapState.ps1 (contrato puro)
- BootstrapWizard.ps1 (pregunta NombreProyecto)
- BootstrapOrchestrador.ps1 (coordinador)
- EnvironmentManager.ps1
- ContextEngine.ps1 + builders + helpers
- Session Handoff (6 archivos en .hermes/context/)

### 🚧 In Progress (Paso 4.5)
- BootstrapRequest.ps1 (por crear)
- BootstrapRequestBuilder.ps1 (por crear)
- ConvertToBootstrapState.ps1 (por crear)
- Test-BootstrapRequest.ps1 (por crear)
- BootstrapRequest.spec.md (por crear)

## Next Objective
Implementar Paso 4.5 siguiendo la arquitectura propuesta:
1. Crear BootstrapRequest.ps1 (DTO inmutable)
2. Crear BootstrapRequestBuilder.ps1 (pregunta al usuario, construye DTO)
3. Crear ConvertToBootstrapState.ps1 (DTO → estado)
4. Crear Test-BootstrapRequest.ps1 (validación)
5. Crear BootstrapRequest.spec.md (documentación <200 líneas)
6. Verificar: tests PASS, working tree clean, commit atómico

## Constraints
- NO modificar componentes congelados
- Usar español en nombres
- Comentarios solo en lógica crítica
- Funciones con responsabilidad única
- Reutilizar componentes existentes cuando sea posible

## Verification Required
- Tests unitarios: PASS
- Working tree: clean
- Commit atómico
- Script temporal limpiado
