# Plugin Contracts

| Campo | Valor |
|---|---|
| NombreDocumento | Plugin Contracts |
| Proyecto | HERMES-ENTERPRISE |
| Version | 1.0.0 |
| AutorPrincipal | Fredy Alejandro Sarmiento Torres |
| Licencia | MIT |
| RepositorioOficial | https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE |
| ArquitecturaBase | Hermes Agent + Azure AI Foundry + MCP + A2A |
| FechaGeneracion | 2026-07-07 |
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

Documentar contratos lógicos IPlugin, IProvider, ITool, IAgent e IExtension en PowerShell.

## Alcance

Validación basada en funciones requeridas porque PowerShell no define interfaces clásicas para scripts.

## Contenido inicial

El contrato IPlugin exige Install, Initialize, Start, Pause, Resume, Stop y Dispose por convención de nombres.

## Referencias cruzadas

- Lifecycle: documentacion/PLUGIN_LIFECYCLE.md
- Contracts: motor/contracts/PluginContracts.ps1

---

> Documento generado automáticamente por el Motor Generador de Documentación Enterprise.
> No editar manualmente contenido generado; modificar plantillas o especificaciones.

