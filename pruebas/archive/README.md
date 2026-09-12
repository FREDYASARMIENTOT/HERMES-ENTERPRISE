# ARCHIVO DE PRUEBAS HISTÓRICAS — HERMES ENTERPRISE

## Propósito

Este directorio contiene pruebas unitarias históricas que **ya no forman parte
del CI vigente**. Se conservan exclusivamente como registro documental de
contratos anteriores de la arquitectura.

## ¿Por qué fueron archivadas?

| Archivo | RC | Fecha | Motivo | Reemplazada por |
|---------|----|-------|--------|-----------------|
| `RC62/Hermes.Commands.RC62.Tests.ps1` | RC62 | 2026-08-03 | Sustituida por suite RC63. Validaba 22 comandos del módulo Hermes.Commands con contratos obsoletos. | `pruebas/unitarias/Hermes.Commands.RC63.Tests.ps1` |

## Reglas

1. **NO** modificar estos archivos.
2. **NO** incluirlos en CI.
3. **NO** borrarlos sin autorización expresa.
4. Si una prueba archivada contiene lógica útil para una prueba canónica,
   **copiar** el fragmento, no mover el archivo.

## Suite canónica vigente

El CI actual (`ci.yml`) ejecuta exclusivamente:

1. **Validación Python**: importaciones críticas, entrypoint FastAPI.
2. **Validación PowerShell**: sintaxis de 8 módulos + Factory.
3. **Validación de módulos**: importación, exportación de comandos, aliases.
4. **Detección de deriva**: verifica que todos los workflows contengan
   capacidades obligatorias (readiness polling, evidencia, artefactos).
5. **Pruebas canónicas**: `pruebas/unitarias/Test-ChildTemplateRendering.ps1`
   (validación determinista del template renderizado).

Estas son las únicas pruebas que **bloquean CI**.

## Historial

- `RC62`: Suite original de 22 comandos (archivada).
- `RC63`: Suite de 25 comandos con Pester 3.x (activa en HEAD).
- `RC69`: Suite de configuración Azure con Pester 3.x (activa en HEAD).
- `RC73`: Suite del Guardian con Pester 3.x (activa en HEAD).
- `RC80`: Intento de migración a Pester 5.x (NO completado, archivado como head.txt referencial).
- `RC84`: Canonical suite definida; pruebas históricas NO bloquean CI.