# ARCHIVO DE PRUEBAS HISTÓRICAS — HERMES ENTERPRISE

## Propósito

Este directorio contiene pruebas históricas que **ya no forman parte
del CI vigente**. Se conservan exclusivamente como registro documental de
contratos anteriores de la arquitectura.

NINGUNA de estas pruebas se ejecuta en CI.
NINGUNA de estas pruebas bloquea el pipeline de entrega.

## ¿Por qué fueron archivadas?

| Archivo | RC | Fecha | Motivo |
|---------|----|-------|--------|
| `RC62/Hermes.Commands.RC62.Tests.ps1` | RC62 | 2026-08-03 | Suite original de 22 comandos del módulo Hermes.Commands. Arquitectura kernel/plugins reemplazada. |
| `RC85.2/Hermes.Commands.RC63.Tests.ps1` | RC63 | 2026-09-12 | Suite de 25 comandos Hermes.Commands con Pester 3.x. Arquitectura kernel/plugins reemplazada. |
| `RC85.2/Hermes.Commands.Tests.ps1` | RC62 | 2026-09-12 | Suite de 21 comandos con rutas absolutas D:\. No portátil a GitHub Actions. |
| `RC85.2/Hermes.Installer.RC63.Tests.ps1` | RC63 | 2026-09-12 | Pruebas del instalador. Arquitectura de distribución reemplazada. |
| `RC85.2/Hermes.AzureConfiguration.RC69.Tests.ps1` | RC69 | 2026-09-12 | Pruebas de configuración Azure canónica. Arquitectura de configuración reemplazada. |
| `RC85.2/Hermes.InfrastructureGuardian.Tests.ps1` | RC73 | 2026-09-12 | Pruebas del Guardian con Pester 3.x. Guardian ya no es módulo activo de CI. |
| `RC85.2/Test-Kernel*.ps1` | Varias | 2026-09-12 | Pruebas del núcleo Kernel. Arquitectura kernel/plugins reemplazada por Factory→Child. |
| `RC85.2/Test-Boot*.ps1` | Varias | 2026-09-12 | Pruebas del Bootstrap. Arquitectura Bootstrap reemplazada. |
| `RC85.2/Test-Plugin*.ps1` | Varias | 2026-09-12 | Pruebas del framework de plugins. Arquitectura de plugins eliminada. |
| `RC85.2/Test-Provider*.ps1` | Varias | 2026-09-12 | Pruebas del framework de providers. Arquitectura de providers eliminada. |
| `RC85.2/Test-Context*.ps1` | Varias | 2026-09-12 | Pruebas del motor de contexto. Arquitectura de contexto reemplazada. |
| `RC85.2/Test-*Azure*.*` | Varias | 2026-09-12 | Pruebas de proveedores Azure heredados con rutas absolutas. |
| `RC85.2/aceptacion/` | Varias | 2026-09-12 | Pruebas de aceptación del flujo DeveloperWorkspace (arquitectura anterior). |
| `RC85.2/integracion/` | Varias | 2026-09-12 | Pruebas de integración de kernel, persistencia, sincronización Git (arquitectura anterior). |

Todas estas pruebas pertenecen a la arquitectura **Kernel / Plugins / Providers / Bootstrap**
que fue reemplazada por la arquitectura actual:

    Factory → Child → CI del Child → Control Plane → OIDC → Azure → Web App

## Reglas

1. **NO** modificar estos archivos.
2. **NO** incluirlos en CI.
3. **NO** borrarlos sin autorización expresa.
4. Si una prueba archivada contiene lógica útil para una prueba canónica actual,
   **copiar** el fragmento, no mover el archivo.

## Suite canónica vigente (RC85.2)

El CI actual (`ci.yml`) ejecuta exclusivamente:

1. **Validación Python**: importaciones críticas, entrypoint FastAPI.
2. **Validación PowerShell**: sintaxis de 8 módulos + Factory.
3. **Prueba canónica**: `pruebas/unitarias/Test-ChildTemplateRendering.ps1`
   (validación determinista del template renderizado — 47/47 PASS).
4. **Validación de documentación**: verifica existencia de README, CHANGELOG, ArchitectureState.
5. **Validación de GitHub Actions**: compila YAML, detecta deriva de capacidades.

Estas son las ÚNICAS pruebas que **bloquean CI**.
NO existe descubrimiento automático de tests.
NO existe ejecución de Pester legacy.

## Historial

- `RC62`: Suite original de 22 comandos (archivada).
- `RC63`: Suite de 25 comandos con Pester 3.x (archivada en RC85.2).
- `RC69`: Suite de configuración Azure con Pester 3.x (archivada en RC85.2).
- `RC73`: Suite del Guardian con Pester 3.x (archivada en RC85.2).
- `RC80`: Intento de migración a Pester 5.x (NO completado, archivado).
- `RC84`: Canonical suite definida; pruebas históricas NO bloquean CI.
- `RC85.2`: Limpieza arquitectónica. Se archivan ~68 pruebas legacy. Solo queda
  `Test-ChildTemplateRendering.ps1` como prueba canónica activa.
  Se elimina el descubrimiento automático `Get-ChildItem *.Tests.ps1`.
  CI ejecuta exclusivamente pasos explícitos y deterministas.