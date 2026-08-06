# Architecture Overview (RC70-D)

## High-Level Architecture

```
+--------------------------------------------------------------------+
|                        USER INTERFACE                               |
|              PowerShell CLI / VS Code Integration                   |
+--------------------------------------------------------------------+
                               |
+--------------------------------------------------------------------+
|                    PUBLIC API LAYER                                 |
|                Hermes.Commands (21 commands)                        |
|                                                                     |
|  Project Mgmt  |  Environment  |  Workspace  |  Utilities          |
|  (8 commands)  |  (6 commands)  |  (3 cmds)   |  (4 commands)       |
+--------------------------------------------------------------------+
                               |
+--------------------------------------------------------------------+
|                    KERNEL LAYER                                     |
|                                                                     |
|  +-------------------+  +-------------------+                       |
|  |   Provider        |  |   Pipeline        |                       |
|  |   Framework       |  |   Orchestrator    |                       |
|  |                   |  |                   |                       |
|  | - Environment     |  | - RC56 Pipeline   |                       |
|  | - FileSystem      |  | - Phase Execution |                       |
|  | - GitHub          |  | - Task Sequencer  |                       |
|  | - Capability      |  |                   |                       |
|  | - Configuration   |  +-------------------+                       |
|  | - Dependency      |                                              |
|  | - Runtime         |                                              |
|  | - Workspace       |                                              |
|  +-------------------+                                              |
+--------------------------------------------------------------------+
                               |
+--------------------------------------------------------------------+
|                    PERSISTENCE LAYER                                |
|                                                                     |
|  +-------------------+  +-------------------+                       |
|  |  HermesSQLite     |  |  SQLite Database  |                       |
|  |  Provider (C#)    |  |  (hermes.db)      |                       |
|  |                   |  |                   |                       |
|  | - Connection      |  | - ProjectHistory  |                       |
|  | - Commands        |  | - EnvironmentHist  |                       |
|  | - Transactions    |  | - WorkspaceHistory |                       |
|  | - Migrations      |  | - Configuration   |                       |
|  +-------------------+  +-------------------+                       |
+--------------------------------------------------------------------+
```

## Module Structure

```
motor/kernel/
  Hermes.Commands.psd1          -- Module manifest
  Hermes.Commands.psm1          -- Public command implementations
  Providers/
    ProviderBase.ps1            -- Base provider class
    EnvironmentProvider.ps1     -- venv environment management
    FileSystemProvider.ps1      -- File system operations
    GitHubProvider.ps1          -- GitHub API integration
    CapabilityProvider.ps1      -- Capability detection
    ConfigurationProvider.ps1   -- Configuration management
    DependencyProvider.ps1      -- Dependency resolution
    RuntimeProvider.ps1         -- Runtime context
    WorkspaceProvider.ps1       -- Workspace management
    ProviderFactory.ps1         -- Provider instantiation
    ProviderRegistry.ps1        -- Provider registration
    ProviderResolver.ps1        -- Provider dependency resolution
    ProviderExecutionContext.ps1-- Execution context management
  Pipeline/
    RC56-EnterprisePipeline.ps1 -- RC56 pipeline orchestration
    PipelineOrchestrator.ps1    -- Pipeline execution engine
```

## Python Runtime Architecture (RC70-D)

```
D:\HermesRuntime\                              ← Hermes Python Runtime root
└── Environments\
    └── HermesEnterprise\                      ← Único Runtime oficial
        ├── Scripts\                           ← python.exe, pip.exe, activate
        ├── Lib\                               ← site-packages (FastAPI, Uvicorn, etc.)
        ├── Include\                           ← C headers
        └── pyvenv.cfg                         ← Venv configuration

config/Hermes.Python.json                      ← Configuración canónica
{
    "VersionPython": "3.14",
    "RutaEntornoVirtual": "D:\\HermesRuntime\\Environments\\HermesEnterprise",
    "RutaPython": "D:\\HermesRuntime\\Environments\\HermesEnterprise\\Scripts\\python.exe",
    "RutaPip": "D:\\HermesRuntime\\Environments\\HermesEnterprise\\Scripts\\pip.exe",
    "ArchivoRequirements": "requirements.txt"
}
```

**Principios:**
- ✓ Único Runtime centralizado (no .venv por proyecto)
- ✓ Sin Conda, Sin Miniconda, Sin Anaconda
- ✓ Sin dependencia de Python global
- ✓ Sin búsqueda por PATH
- ✓ Todos los módulos leen `config/Hermes.Python.json`
- ✓ FastAPI/Uvicorn ejecutados con `RutaPython -m uvicorn`

## Key Design Principles

### 1. Provider Pattern
All capabilities are encapsulated as providers following a common base contract (ProviderBase). Each provider has:
- Standard initialization
- Error handling
- Status tracking
- Event logging

### 2. Pipeline Architecture
RC56 introduced a pipeline pattern for project creation:
1. Phase 1: Directory structure
2. Phase 2: Git initialization
3. Phase 3: Environment setup
4. Phase 4: GitHub integration
5. Phase 5: VS Code launch

### 3. Telemetry
All operations are logged to SQLite (hermes.db) with:
- ProjectHistory: Project-level operations
- EnvironmentHistory: Environment operations
- WorkspaceHistory: Workspace operations
- Configuration: Key-value settings

### 4. Public API
Hermes.Commands exports exactly 21 commands, each with:
- Pester tests
- Help documentation
- Parameter validation
- Return types
- Pipeline support (where applicable)

## Data Flow

```
User Command --> Hermes.Commands.psm1 --> Provider Layer --> SQLite DB
                    |                           |
                    v                           v
              Pipeline Orchestrator      File System / GitHub / Hermes Runtime
```

The Hermes Runtime (`python.exe`) is always resolved from `config/Hermes.Python.json`. All Python operations use:
- `$RutaPython -m pip install ...`
- `$RutaPython -m uvicorn ...`
- `$RutaPython -c "import ..."`

## Provider Contract

Each provider must implement:
```
- Id (string)
- Name (string)
- Version (string)
- ProviderType (string)
- ProviderConfig (hashtable)
- Status (string)
- IsConnected (bool)
- Errors (list)
- Events (list)
- LastConnection (datetime)
```

## Security

- No secrets stored in code
- GitHub tokens managed via `gh auth`
- Database access via parameterized SQL
- PowerShell execution policy respected
- Python Runtime isolated from system Python