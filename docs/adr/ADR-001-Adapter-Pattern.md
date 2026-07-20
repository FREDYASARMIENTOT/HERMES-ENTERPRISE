# ADR-001: Implementación de Patrón Adaptador para el Engine

## Contexto
El Entrypoint `Start-HermesProject.ps1` buscaba `EnterprisePipeline.ps1`, archivo inexistente tras la refactorización a `BootstrapOrchestrator` y `Scheduler`.

## Decisión
Se implementó `tools/EnterprisePipeline.ps1` como un adaptador para preservar la interfaz del Entrypoint sin modificar su lógica de invocación.

## Consecuencias
- **Positivas:** Preserva compatibilidad hacia atrás, desacopla el Entrypoint de la implementación del motor.
- **Negativas:** Añade un pequeño nivel de indirección (shim).
