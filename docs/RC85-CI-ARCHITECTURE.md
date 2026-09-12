# RC85.2 — Arquitectura del CI de HERMES-ENTERPRISE

## 1. ¿Qué valida CI?

El pipeline CI (`ci.yml`) ejecuta **4 trabajos deterministas**:

```
validate-python
    ↓
validate-powershell
    ↓
validate-documentation
    ↓
validate-actions
```

### validate-python (ubuntu-latest)

1. Checkout del repositorio.
2. Configura Python 3.12 con cache pip.
3. Instala dependencias desde `requirements.txt`.
4. Valida importaciones críticas: fastapi, uvicorn, jinja2, pydantic.
5. Valida entrypoint FastAPI: `from Hermes.Web.backend.main import app`.
6. Busca archivos `test_*.py` / `*_test.py`. Si no existen (caso normal), informa
   "no presente" sin bloquear CI.
7. Valida existencia de archivos canónicos: `Hermes.Python.json`,
   `Hermes.Web/__init__.py`, `Crear-HermesProyecto.ps1`, `Guardian config`.

### validate-powershell (windows-latest)

1. Checkout del repositorio.
2. Valida sintaxis de 8 módulos PowerShell + `Crear-HermesProyecto.ps1`
   mediante `PSParser.Tokenize`.
3. **Prueba canónica**: ejecuta `pruebas/unitarias/Test-ChildTemplateRendering.ps1`
   con `pwsh`. Verifica el renderizado determinista de plantillas Child.
   **BLOQUEA CI** si falla.

### validate-documentation (ubuntu-latest)

1. Verifica existencia de: `README.md`, `CURRENT_STATE.md`, `CHANGELOG.md`,
   `docs/ArchitectureState.md`.

### validate-actions (ubuntu-latest)

1. Instala PyYAML.
2. Valida que los 4 workflows YAML compilen: `ci.yml`, `deploy.yml`,
   `deploy-child.yml`, `tools/Templates/github/ci.yml`.
3. Detecta deriva de capacidades críticas:
   - readiness polling (no sleep)
   - generación de evidencia
   - subida de artefactos
   - comando de inicio
   - validación OpenAPI/Swagger
   - setup-python y validación de entrypoint
   ## 2. ¿Qué valida Factory?

La Factory (`tools/Crear-HermesProyecto.ps1`) es validada por:

- **Sintaxis PowerShell** en `validate-powershell`.
- **Prueba canónica** `Test-ChildTemplateRendering.ps1` que verifica que el
  template renderizado sea correcto.

No existe una suite de pruebas unitarias separada para la Factory.
La validación de la Factory es:

1. Sintaxis válida.
2. Template renderizado correcto (prueba canónica 47/47).
3. El repositorio Child generado tiene su propio CI.

## 3. ¿Qué valida Child CI?

Cada proyecto **Hermes Child** generado por la Factory recibe:

- `tools/Templates/github/ci.yml` como su pipeline CI.
- Este template es validado por `validate-actions` en el CI de la Factory
  (detección de deriva).

El Child CI incluye:
- Validación Python del Child.
- Pruebas del Child (plantilla, endpoints).
- Despliegue solo a través del Control Plane.

## 4. ¿Qué valida Control Plane?

El Control Plane (`control-plane/`) orquesta el despliegue de Child projects
a través de `deploy-child.yml`:

```
validate-inputs → oidc-login → checkout-child → provision-webapp
    → deploy → readiness → functional-tests → user-facing-validation → evidence
```

Es validado por:
- `validate-actions` en el CI (deriva de capacidades).
- Validación YAML en `validate-actions`.

## 5. ¿Qué valida E2E?

La validación E2E es realizada por `deploy-child.yml` en producción:

1. Readiness polling (no sleep).
2. Pruebas funcionales del Child desplegado.
3. Validación user-facing (HTML, identidad, error pages).
4. Generación de evidencia con resultados reales.

## 6. Pruebas canónicas

Actualmente existe UNA prueba canónica:

| Archivo | Propósito | Resultado |
|---------|-----------|-----------|
| `pruebas/unitarias/Test-ChildTemplateRendering.ps1` | Validar renderizado determinista de plantilla Child | 47/47 PASS |

Esta prueba:
- No depende de Pester.
- No depende de rutas absolutas.
- Usa `$PSScriptRoot` para descubrimiento dinámico de rutas.
- Es portátil entre Windows local y GitHub Actions.
## 7. Pruebas históricas retiradas

Todas las pruebas de las arquitecturas anteriores fueron archivadas en
`pruebas/archive/RC85.2/`. Incluyen:

- **Kernel**: Test-Kernel, Test-KernelHealth, Test-KernelMetrics (3)
- **Bootstrap**: Test-BootLoader, Test-BootstrapOrchestrator, Test-BootstrapRequest,
  Test-BootstrapState, Test-BootstrapWizard, Test-NewBootstrapRequestFromProjectArchitecture (6)
- **Plugins**: Test-PluginFaultPolicy, Test-PluginFrameworkMaturity, Test-PluginLoader,
  Test-PluginManager, Test-PluginObservability, Test-PluginSandbox (6)
- **Providers**: Test-ProviderAdapter, Test-ProviderCapabilityDescriptor,
  Test-ProviderConfigurationManager, Test-ProviderDescriptor, Test-ProviderDiagnostics,
  Test-ProviderFramework, Test-ProviderFrameworkMaturity, Test-ProviderManagerValidation,
  Test-ProviderObservability (9)
- **Context**: Test-Context, Test-ContextContracts, Test-DeveloperContext,
  Test-DeveloperContextManager (4)
- **Hermes.Commands**: Hermes.Commands.Tests.ps1 (RC62), Hermes.Commands.RC63.Tests.ps1 (2)
- **Instalador**: Hermes.Installer.RC63.Tests.ps1 (1)
- **Azure heredado**: Test-AzureProviderAuthentication, Test-AzureResourceDiscovery,
  Test-AzureFoundryProvider, Test-AzureFoundryProviderConnection,
  Test-AzureFoundryProviderTelemetry, Hermes.AzureConfiguration.RC69.Tests.ps1 (6)
- **Guardian**: Hermes.InfrastructureGuardian.Tests.ps1 (1)
- **Framework general**: ~20 archivos adicionales
- **Aceptación**: Test-DeveloperWorkspaceFlow.ps1 (1)
- **Integración**: Run-PersistenceTests, Test-FullKernel, Test-GitSynchronization,
  Test-HermesProvider, Test-ParamBinding, Test-PersistenceLayer (6)
- **Environment**: Test-EnvironmentManager.ps1 (1)

Total: **~68 pruebas archivadas**.

NINGUNA de estas pruebas se ejecuta en CI.
NINGUNA de estas pruebas bloquea la entrega.

## 8. ¿Por qué las pruebas históricas no bloquean el producto actual?

Porque prueban componentes que ya no forman parte de la arquitectura:

| Componente histórico | Estado actual | Reemplazo |
|---------------------|---------------|-----------|
| Hermes.Commands | No utilizado | N/A |
| Kernel / Plugins / Providers | Arquitectura eliminada | Factory→Child pipeline |
| Bootstrap | Reemplazado | Crear-HermesProyecto.ps1 |
| Context Engine | No utilizado | N/A |
| Infrastructure Guardian | No es módulo de CI | Validación directa en YAML |
## 9. Workflows

| Workflow | Estado | Propósito |
|----------|--------|-----------|
| `.github/workflows/ci.yml` | **ACTIVO** | CI de la Factory: Python, PowerShell, Docs, Actions |
| `.github/workflows/deploy-child.yml` | **ACTIVO** | Control Plane: despliegue de Child projects |
| `.github/workflows/deploy.yml` | **ACTIVO** | Despliegue de la app principal HERMES-ENTERPRISE |
| `tools/Templates/github/ci.yml` | **TEMPLATE** | Template CI que recibe cada Child generado |

## 10. Seguridad

- **OIDC**: Sin cambios. `UR-Fabrica-Proyectos-AR` con FIC existente.
- **FIC**: Sin cambios. Federated credential `repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production`.
- **RBAC**: Sin cambios. Contributor en `RG-Hermes-Proyectos`.
- **Secretos**: Sin cambios. `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.
- **Child sin privilegios**: Los proyectos Child NO reciben `id-token: write`.
  Solo el Control Plane (`deploy-child.yml`) tiene `id-token: write`.
- **ASP-IAUR**: Sin cambios. Reutilizado, no creado.

## 11. Arquitectura completa

```
HERMES-ENTERPRISE (Factory)
    │
    ├── tools/Crear-HermesProyecto.ps1
    ├── tools/Templates/backend/main.py
    ├── tools/Templates/github/ci.yml
    │
    ├── CI (ci.yml)
    │   ├── Validar Python Runtime
    │   ├── Validar PowerShell + Prueba canónica
    │   ├── Validar documentación
    │   └── Validate GitHub Actions
    │
    └── CD
        ├── deploy.yml → Azure Web App (main app)
        └── deploy-child.yml (Control Plane)
            ├── validate-inputs
            ├── oidc-login (FIC)
            ├── checkout-child
            ├── provision-webapp (ASP-IAUR)
            ├── deploy (zip deploy)
            ├── readiness polling
            ├── functional tests
            ├── user-facing validation
            └── evidence
```

## 12. Resumen

| Aspecto | Antes (RC84) | Después (RC85.2) |
|---------|-------------|-------------------|
| Pruebas en unitarias/ | ~68 archivos | 1 archivo canónico |
| Descubrimiento CI | `Get-ChildItem *.Tests.ps1` | Ejecución explícita |
| Pester en CI | Sí (bloqueo NO, ejecución SÍ) | NO |
| Referencias "68 tests" | Sí | No |
| Referencias "230/223" | Sí | No |
| Rutas absolutas D:\ | Sí (en pruebas legacy) | No |
| Framework de pruebas | Pester 3.x + scripts ad-hoc | Script canónico único |
| Resultado CI | Determinista + ruido legacy | Determinista puro |