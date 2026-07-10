---
sprint: "6"
nombre: Start-HermesProject
archivo: motor/bootstrap/Start-HermesProject.ps1
lineas_estimadas: ~80
---

# Sprint 6 — Start-HermesProject (spec)

## Propósito

Entry point público del motor de bootstrap.
Única función visible fuera del motor.

Responsabilidades:

1. Capturar datos del usuario (parámetros o wizard).
2. Construir BootstrapRequest.
3. Convertir Request → BootstrapState (via New-BootstrapStateFromRequest).
4. Delegar ejecución en BootstrapOrchestrator.
5. Retornar resultado final al usuario.

NO contiene lógica de negocio.

NO interactúa con managers directamente.

NO lee/escribe archivos (excepto retorno opcional de report).

## Entradas

### Modo parámetros (automatizado)

- NombreProyecto (string, obligatorio)
- RutaProyecto (string, obligatorio)
- AbrirVSCode (bool, default $true)
- CrearBackend (bool, default $false)
- CrearFrontend (bool, default $false)
- ProveedorGit (string, default 'None')
- Force (switch, salta wizard interactivo)

### Modo wizard (interactivo)

Si no se pasan parámetros obligatorios y -Force NO está:

→ invoca Start-BootstrapWizard para completar datos.

## Flujo de secuencia

```
Usuario
  ↓
Start-HermesProject
  ↓
[si faltan datos y no Force] Start-BootstrapWizard
  ↓
New-BootstrapRequest
  ↓
New-BootstrapStateFromRequest
  ↓
Invoke-BootstrapOrchestrator
  ↓
Retornar BootstrapReport + BootstrapState
```

## Salida

PSCustomObject con:

- Success (bool)
- BootstrapReport (objeto de BootstrapOrchestrator)
- BootstrapState (objeto final)
- ProximaAccion (string: "Workspace abierto", "Continuar en VSCode", etc.)

## Criterios de aceptación

1. Si se invocan con parámetros mínimos (NombreProyecto + RutaProyecto) → ejecuta flujo completo.
2. Si se invoca sin parámetros ni -Force → lanza wizard interactivo.
3. Si se invoca con -Force → salta wizard, usa datos proporcionados.
4. Retorna tipo de salida documentado (Success, BootstrapReport, BootstrapState, ProximaAccion).
5. NO invoca managers directamente.
6. NO modifica contratos congelados.
7. Maneja errores de validación con mensajes claros.
8. Verificación ad-hoc ≤ 40 líneas.

## Restricciones

NO modificar:

- BootstrapState.ps1
- BootstrapRequest.ps1
- New-BootstrapStateFromRequest.ps1
- BootstrapOrchestrator.ps1
- documentación del motor

NO crear:

- clases auxiliares
- managers nuevos
- DTOs adicionales

Commit único:

```
feat(6): Start-HermesProject como entry point público
```

## Dependencias

- motor/bootstrap/request/BootstrapRequest.ps1
- motor/bootstrap/engine/BootstrapState.ps1
- motor/bootstrap/engine/New-BootstrapStateFromRequest.ps1
- motor/bootstrap/engine/BootstrapOrchestrator.ps1

Las cuatro están congeladas tras Sprint 5.3.
