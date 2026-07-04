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
| FechaGeneracion | 2026-07-04 |
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

Documentar el núcleo operativo que coordina configuración, módulos, dependencias, eventos, logging y runtime.

## Alcance

Infraestructura base del Kernel; no incluye todavía Azure Foundry, MCP, memoria, agentes ni herramientas externas.

## Contenido inicial

El Kernel Enterprise se implementa en motor/kernel y se inicia mediante scripts/Start-HermesEnterprise.ps1.

## Referencias cruzadas

- Runtime: documentacion/RUNTIME.md
- Configuración: documentacion/CONFIGURATION.md
- Registro de módulos: documentacion/MODULE_REGISTRY.md
- EventBus: documentacion/EVENT_BUS.md
- Logger: documentacion/LOGGER.md
- Bootstrap: documentacion/BOOTSTRAP.md

---

> Documento generado automáticamente por el Motor Generador de Documentación Enterprise.
> No editar manualmente contenido generado; modificar plantillas o especificaciones.

