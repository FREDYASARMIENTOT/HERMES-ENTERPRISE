# Kernel Enterprise

| Campo | Valor |
|---|---|
| NombreDocumento | Kernel Enterprise |
| Proyecto | HERMES-ENTERPRISE |
| Version | 1.0.0 |
| AutorPrincipal | Fredy Alejandro Sarmiento Torres |
| Licencia | MIT |
| RepositorioOficial | https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE |
| ArquitecturaBase | Hermes Agent + Azure AI Foundry + MCP + A2A |
| FechaGeneracion | 2026-07-05 |
| GeneradoPor | New-HermesEnterpriseDocumentation.ps1 |

## Tabla de contenido

- [Propósito](#proposito)
- [Alcance](#alcance)
- [Contenido inicial](#contenido-inicial)
- [Referencias cruzadas](#referencias-cruzadas)

---

## Navegación

- [Índice de documentación](README.md)

---

## Propósito

Documentar el núcleo operativo que coordina configuración, módulos, dependencias, eventos, logging, runtime, salud operativa y métricas internas.

## Alcance

Infraestructura base del Kernel; incluye Health Monitor y métricas internas mínimas almacenadas mediante Logger Enterprise. No incluye todavía Azure Foundry, MCP, memoria persistente, agentes ni herramientas externas.

## Contenido inicial

El Kernel Enterprise se implementa en motor/kernel y se inicia mediante scripts/Start-HermesEnterprise.ps1.

Componentes de observabilidad agregados en Fase 1:

- Health Monitor: motor/kernel/KernelHealth.ps1 expone Get-HermesEnterpriseKernelHealth para consultar EstadoRuntime, EstadoPlugins, EstadoLogger, EstadoEventBus, EstadoConfiguracion y EstadoMemoria.
- Kernel Metrics: motor/kernel/KernelMetrics.ps1 expone Write-HermesEnterpriseKernelMetric para registrar HoraInicio, HoraFin, TiempoEjecucionMilisegundos, CantidadErrores, CantidadAdvertencias, UsoMemoriaBytes y Estado mediante Logger Enterprise.
- Registro automático: Kernel registra KernelHealth y KernelMetrics en el contenedor de dependencias sin modificar contratos públicos existentes.
- Métrica inicial: durante Start-HermesEnterpriseKernel se registra Kernel.Start como MetricaKernel.

## Referencias cruzadas

- Runtime: documentacion/RUNTIME.md
- Configuración: documentacion/CONFIGURATION.md
- Registro de módulos: documentacion/MODULE_REGISTRY.md
- EventBus: documentacion/EVENT_BUS.md
- Logger: documentacion/LOGGER.md
- Bootstrap: documentacion/BOOTSTRAP.md
- Health Monitor: motor/kernel/KernelHealth.ps1
- Kernel Metrics: motor/kernel/KernelMetrics.ps1
- Pruebas Health: pruebas/unitarias/Test-KernelHealth.ps1
- Pruebas Metrics: pruebas/unitarias/Test-KernelMetrics.ps1

---

> Documento generado automáticamente por el Motor Generador de Documentación Enterprise.
> No editar manualmente contenido generado; modificar plantillas o especificaciones.

