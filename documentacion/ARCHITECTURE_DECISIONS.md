# Architecture Decisions HERMES-ENTERPRISE

| Campo | Valor |
|---|---|
| Proyecto | HERMES-ENTERPRISE |
| AutorPrincipal | Fredy Alejandro Sarmiento Torres |
| Estado | Registro vivo de decisiones arquitectónicas |

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
