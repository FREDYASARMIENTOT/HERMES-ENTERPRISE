# HERMES-ENTERPRISE

| Campo | Valor |
|---|---|
| NombreDocumento | HERMES-ENTERPRISE |
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
- [Documento siguiente](documentacion/PROJECT_CHARTER.md)

---

## Propósito

Presentar la plataforma empresarial de ingeniería para agentes inteligentes.

## Alcance

Este README es generado por el motor documental y será enriquecido progresivamente.

## Contenido inicial

La biblioteca documental de HERMES-ENTERPRISE será generada desde plantillas reutilizables,
metadatos centralizados y especificaciones declarativas. Esta fase crea únicamente la
infraestructura del generador; el contenido extenso se incorporará de forma controlada en fases
posteriores.

## Bootstrap & Provisioner

El bootstrap principal ahora es modular y se encuentra en:

- `motor/bootstrap/Start-HermesProject.ps1` (orquestador)
- `motor/bootstrap/functions/` (módulos de provisión: Git, Python, Validation, Templates, Reporting)

Uso rápido (modo local):

```
pwsh -NoProfile -File ./motor/bootstrap/Start-HermesProject.ps1 -NombreDeProyecto "MyProject"
```

Nota de seguridad: el repositorio fue marcado por GitHub secret-scanning. Antes de hacer push al remoto
rota cualquier clave expuesta y limpia el historial con `git-filter-repo` o usa la resolución de GitHub.

## Referencias cruzadas

- README principal: README.md
- Project Charter: documentacion/PROJECT_CHARTER.md
- Visión: documentacion/VISION.md
- SRS: documentacion/SRS_HERMES_ENTERPRISE.md
- Motor documental: builders/DocumentBuilder.ps1

---

> Documento generado automáticamente por el Motor Generador de Documentación Enterprise.
> No editar manualmente contenido generado; modificar plantillas o especificaciones.

