# Architecture Decisions HERMES-ENTERPRISE

| Campo | Valor |
|---|---|
| Proyecto | HERMES-ENTERPRISE |
| AutorPrincipal | Fredy Alejandro Sarmiento Torres |
| Estado | Registro vivo de decisiones arquitectónicas |

---

## ADR-0008: Sandbox v1 de plugins por aislamiento lógico de errores

### Estado

Aceptada.

### Contexto

El Plugin Framework ya descubre, valida, ordena y ejecuta plugins. La Fase 2.3 requiere evitar que un plugin defectuoso detenga al PluginManager o al Kernel sin introducir todavía un sandbox pesado.

### Decisión

Agregar Sandbox v1 en `motor/lifecycle/LifecycleManager.ps1` mediante `try/catch` alrededor del ciclo de vida del plugin.

Cuando una etapa falla:

- El contexto del plugin queda con `EstadoActual = Faulted`.
- El contexto del plugin queda con `EstadoSandbox = Faulted`.
- El error se conserva en `ErroresSandbox` con etapa, tipo y mensaje.
- El PluginManager continúa con los demás plugins.

### Límites

- No se aíslan procesos.
- No se crean runspaces, jobs, AppDomains ni contenedores.
- No se ejecuta PowerShell separado.
- No se cambia `plugin.json`.
- No se modifican contratos públicos del Kernel.

### Verificación

- `pruebas/unitarias/Test-PluginSandbox.ps1`
- `pruebas/unitarias/Test-Lifecycle.ps1`
- `pruebas/unitarias/Test-PluginManager.ps1`

---

## ADR-0007: Validación SemVer estricta para plugins

### Estado

Aceptada.

### Contexto

El Enterprise Plugin Framework ya valida compatibilidad mínima contra el Kernel. La Fase 2.2 requiere hacer explícito que las versiones de plugins usan SemVer de tres segmentos sin cambiar el formato existente de `plugin.json`.

### Decisión

Agregar validación estricta `Major.Minor.Patch` en `motor/validation/VersionValidator.ps1` mediante una comprobación de formato previa y conversión tipada con `[version]`.

El `ManifestLoader` reutiliza la validación para los campos existentes:

- `Version`.
- `KernelMinimo`.

No se agrega ningún campo nuevo al manifiesto.

### Consecuencias positivas

- Los errores de versión son más descriptivos.
- Se evita aceptar versiones abreviadas ambiguas como `1.2`.
- Los manifiestos actuales siguen siendo compatibles.

### Límites

- No se implementa sandbox ni recovery en esta decisión.
- No se introduce proveedor externo ni IA.
- No se modifica el contrato público del Kernel.

### Verificación

- `pruebas/unitarias/Test-VersionValidator.ps1`
- `pruebas/unitarias/Test-Manifest.ps1`
- `pruebas/unitarias/Test-PluginManager.ps1`

---

## ADR-0006: Smoke Test Enterprise como certificado de madurez del Kernel

### Estado

Aceptada.

### Contexto

Después de consolidar Bootstrap, Kernel, Runtime, PluginManager, Logger, EventBus, Health Monitor y Metrics, HERMES-ENTERPRISE necesita demostrar que los componentes funcionan como sistema integrado antes de iniciar fases de robustez avanzada o proveedores de IA.

### Decisión

Crear una prueba de integración completa:

```powershell
pruebas/integracion/Test-FullKernel.ps1
```

Crear un script público de ejecución:

```powershell
scripts/Test-HermesEnterprise.ps1
```

Agregar funciones auxiliares no disruptivas en `motor/kernel/KernelValidator.ps1`:

```powershell
Test-HermesEnterpriseKernelReady
Get-HermesEnterpriseKernelSummary
```

La prueba integral valida arranque, servicios registrados, plugins, logger, eventos, health, métricas, documentación idempotente y shutdown.

### Consecuencias positivas

- HERMES-ENTERPRISE obtiene una línea base certificada del núcleo.
- Las fases futuras podrán detectar regresiones de integración rápidamente.
- Se mantiene la estrategia incremental sin introducir IA ni proveedores externos.

### Límites

- La prueba no reemplaza pruebas unitarias.
- La prueba no valida comportamiento de proveedores de IA.
- La prueba no agrega sandbox de plugins; eso queda para Fase 2.

### Verificación

- `pruebas/integracion/Test-FullKernel.ps1`
- `scripts/Test-HermesEnterprise.ps1`
- Suite completa en `pruebas/unitarias/Test-*.ps1`

---

## ADR-0005: Observabilidad interna incremental del Kernel

### Estado

Aceptada.

### Contexto

HERMES-ENTERPRISE requiere fortalecer el Kernel antes de incorporar inteligencia artificial, MCP distribuido, A2A o proveedores externos.

La línea base existente ya contiene Kernel, Runtime, Logger, EventBus, Configuration, Dependency Container, Service Locator y PluginManager. La evolución debe ser incremental y no debe romper compatibilidad.

### Decisión

Agregar observabilidad interna mínima al Kernel mediante dos componentes nuevos bajo `motor/kernel`:

- `KernelHealth.ps1`
- `KernelMetrics.ps1`

El Health Monitor expone:

```powershell
Get-HermesEnterpriseKernelHealth
```

Kernel Metrics expone:

```powershell
Write-HermesEnterpriseKernelMetric
```

Ambos componentes se cargan desde Bootstrap y se registran automáticamente en el contenedor de dependencias como servicios internos:

- KernelHealth.
- KernelMetrics.

Las métricas se almacenan mediante Logger Enterprise en formato JSONL, evitando introducir dependencias externas prematuras.

### Consecuencias positivas

- El Kernel gana introspección operativa sin rediseño.
- Se conserva compatibilidad con la arquitectura existente.
- Las métricas iniciales quedan disponibles para fases posteriores de telemetría.
- Las pruebas unitarias pueden validar observabilidad sin proveedores externos.

### Consecuencias y límites

- La observabilidad sigue siendo local y mínima.
- No existe todavía dashboard, exportador OpenTelemetry ni integración cloud.
- La memoria reportada corresponde a memoria administrada del proceso PowerShell mediante .NET GC.

### Alternativas descartadas

- Incorporar observabilidad externa desde esta fase: descartado por exceso de alcance.
- Modificar la estructura pública del Kernel para agregar propiedades nuevas permanentes: descartado para preservar compatibilidad.
- Registrar métricas en archivos separados: descartado porque Logger Enterprise ya es el contrato de persistencia local.

### Verificación

- `pruebas/unitarias/Test-KernelHealth.ps1`
- `pruebas/unitarias/Test-KernelMetrics.ps1`
- `pruebas/unitarias/Test-Kernel.ps1`
- `scripts/Start-HermesEnterprise.ps1`
