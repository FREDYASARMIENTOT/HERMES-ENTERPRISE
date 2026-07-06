# First Run Experience

## Propósito

Cuando el usuario ejecuta `Start-HermesEnterprise` y no existe una sesión previa, HERMES Enterprise inicia automáticamente el Session Wizard para crear una sesión funcional.

## Flujo

```text
Start-HermesEnterprise
¿Existe sesión?
  SI → Cargar sesión
  NO → Ejecutar Session Wizard
         → Detectar herramientas
         → Seleccionar workspace
         → Crear proyecto
         → Inicializar Git
         → Crear README
         → Configurar modelo por defecto
         → Guardar Session Descriptor
```

## Herramientas detectadas

- PowerShell
- Git
- VS Code
- Azure CLI
- GitHub CLI
- Python
- Docker
- Node

## Configuración por defecto

- Modelo: `ur-hermes-mini`
- Proveedor: `AzureFoundryProvider`
- Rama: `main`

## Resultado

Al finalizar el wizard, el usuario tiene una sesión persistida y el sistema continúa con el arranque del Kernel.

## Punto de entrada

`scripts/Start-HermesEnterprise.ps1`
