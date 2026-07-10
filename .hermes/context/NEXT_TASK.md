---
project: HERMES-ENTERPRISE
version: 0.19.0
phase: 5
step: StartHermesProject
commit: 4f08222
branch: main
generated_at: 2026-07-10
---

# Paso 5 — Start-HermesProject.ps1

## Objetivo
Entry point público del framework. Invoca BootstrapOrchestrator.

## Entry point
motor/bootstrap/Start-HermesProject.ps1

## Input
Parámetros de línea de comandos:
  -ProjectPath  : string (obligatorio)
  -Force        : switch (opcional)

## Cadena de invocación
Start-HermesProject → BootstrapOrchestrator → todos los managers

## Salida
Reporte de ejecución con métricas y estado final.
