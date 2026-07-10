---
project: HERMES-ENTERPRISE
version: 0.18.0
phase: 4
step: BootstrapOrchestrator
commit: 3c91283
branch: main
generated_at: 2026-07-10
---

# Paso 4 — BootstrapOrchestrator.ps1

## Objetivo
Motor de orquestación completo del Bootstrap Engine.

## Entry point
motor/bootstrap/engine/BootstrapOrchestrator.ps1

## Input
Lectura lazy del Context Package:
  1. SESSION_HANDOFF.json (~100 tokens)
  2. CURRENT_STATE.md     (~120 tokens)
  3. PUBLIC_API.json      (~150 tokens) — solo si se necesita firma exacta

## Cadena de invocación
BootstrapOrchestrator → BootstrapWizard → EnvironmentManager → ContextEngine → Builders → Helpers
