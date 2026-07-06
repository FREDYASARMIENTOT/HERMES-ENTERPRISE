# Developer Context Framework

## Propósito

A partir de la Fase 7.0, HERMES Enterprise se organiza alrededor del **Developer Context**. El Developer Context representa el entorno real del desarrollador: workspace, proyecto, Git, GitHub, proveedor de IA, plugins, sesión y preferencias.

La **Session deja de ser el objeto raíz** del sistema y pasa a ser un componente interno administrado automáticamente. El Developer Context es ahora el único punto de entrada al sistema.

## Principios

- **El Kernel consume un contexto**, no lo inicia.
- **La Session es interna**: el usuario nunca interactúa directamente con ella.
- **Solo lectura**: los inspectores nunca modifican el repositorio, el sistema de archivos ni el Kernel.
- **Sin persistencia de contexto**: el Developer Context siempre se reconstruye en memoria.
- **Sin secretos**: el contexto solo almacena referencias, nunca credenciales ni tokens.

## Arquitectura

```text
Start-HermesEnterprise
│
└── Developer Context
    │
    ├── Workspace
    ├── Project
    ├── Git
    ├── GitHub
    ├── Provider
    ├── Modelo
    ├── Plugins
    ├── Session  ← componente interno
    ├── Preferencias
    ├── VariablesEntorno
    └── EstadoKernel
```

Relación clave:

```text
DeveloperContext contiene Session
```

NO:

```text
Session contiene Workspace
```

## Componentes

### Inspectores (solo lectura)

| Archivo | Responsabilidad |
|---------|-----------------|
| `motor/context/WorkspaceInspector.ps1` | Descubre el workspace actual. |
| `motor/context/ProjectInspector.ps1` | Descubre el proyecto dentro del workspace. |
| `motor/context/GitInspector.ps1` | Detecta repositorio Git y rama actual. |
| `motor/context/GitHubInspector.ps1` | Expone información GitHub en modo MOCK. |
| `motor/context/EnvironmentInspector.ps1` | Descubre variables de entorno y preferencias locales. |

### Orquestadores

| Archivo | Responsabilidad |
|---------|-----------------|
| `motor/context/DeveloperContext.ps1` | Define el objeto raíz DeveloperContext. |
| `motor/context/ContextBuilder.ps1` | Orquesta inspectores para construir el contexto. |
| `motor/context/DeveloperContextManager.ps1` | Obtiene o crea un DeveloperContext, administrando la Session automáticamente. |

### Wizards

| Archivo | Responsabilidad |
|---------|-----------------|
| `motor/wizards/FirstRunWizard.ps1` | Configura preferencias globales la primera vez. No crea proyectos. |
| `motor/wizards/ProjectWizard.ps1` | Resuelve qué hacer cuando no hay proyecto: crear, abrir o clonar. |

## Contrato del DeveloperContext

```powershell
[pscustomobject][ordered]@{
    Workspace        = $Workspace
    Proyecto         = $Proyecto
    Git              = $Git
    GitHub           = $GitHub
    Provider         = $Provider
    Modelo           = $Modelo
    Plugins          = $Plugins
    Session          = $Session
    Preferencias     = $Preferencias
    VariablesEntorno = $VariablesEntorno
    EstadoKernel     = $EstadoKernel
}
```

## Flujo de inicio

### VS Code sin carpeta abierta

```text
Iniciar Hermes
→ No hay Workspace
→ Project Wizard
→ Elegir carpeta
→ Crear carpeta
→ Crear repo Git
→ Preguntar si desea crear repo GitHub
→ Si acepta: crear repo GitHub MOCK, asociar remoto
→ Crear Session automáticamente
→ Iniciar Kernel
```

### VS Code con carpeta abierta

```text
Iniciar Hermes
→ Detectar carpeta
→ Buscar .git
→ Buscar GitHub
→ Buscar Session
→ Construir DeveloperContext
→ Preguntar ¿Qué desea hacer aquí?
→ Iniciar Kernel
```

## Persistencia

NO se persiste DeveloperContext. Siempre se reconstruye a partir del entorno real.

La única persistencia continúa siendo la **Session** en `.hermes/sessions/<Identificador>.json`.

## Compatibilidad

- El Kernel permanece compatible: recibe el DeveloperContext a través de `EstadoKernel`.
- La Session sigue funcionando sin cambios funcionales.
- El Provider Framework no cambia; consume `DeveloperContext.Provider`.
- El Plugin Framework no cambia; los plugins reciben `DeveloperContext`.
- GitHub permanece en modo MOCK.

## Transición desde la Fase 6

| Fase 6 | Fase 7 |
|--------|--------|
| `Session` es raíz | `DeveloperContext` es raíz |
| `SessionWizard` configura todo | `FirstRunWizard` + `ProjectWizard` dividen responsabilidades |
| `Start-HermesEnterprise` gestiona sesión | `Start-HermesEnterprise` construye DeveloperContext |
| Session contiene Workspace | DeveloperContext contiene Session |
