# First Run Experience

## Propósito

La primera vez que el usuario ejecuta HERMES Enterprise, el sistema configura las preferencias globales mediante el **First Run Wizard**. Este wizard **no crea proyectos**; su única responsabilidad es establecer el entorno base del desarrollador.

## Flujo

```text
Start-HermesEnterprise
├── ¿Primera ejecución?
│   └── FirstRunWizard
│       → Idioma
│       → Proveedor IA
│       → Modelo por defecto
│       → Preferencias
│       → Ubicación por defecto
│       → GitHub
└── Continuar con Developer Context
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
- Idioma: `es`
- Ubicación por defecto: `%USERPROFILE%\HermesProjects`

## Project Wizard

Cuando no existe un proyecto, HERMES ejecuta el **Project Wizard** independiente. Este wizard pregunta:

1. Crear proyecto
2. Abrir proyecto existente
3. Clonar repositorio

## Resultado

Al finalizar los wizards, HERMES construye el `DeveloperContext` y continúa con el arranque del Kernel.

## Punto de entrada

`scripts/Start-HermesEnterprise.ps1`

## Archivos relacionados

- `motor/wizards/FirstRunWizard.ps1`
- `motor/wizards/ProjectWizard.ps1`
- `documentacion/DEVELOPER_CONTEXT.md`
