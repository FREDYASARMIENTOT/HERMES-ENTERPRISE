# Fase 6 — Provider Framework

## Objetivo

Diseñar e implementar el Provider Framework que permita a BootstrapOrchestrator consumir providers específicos (Azure, AWS, Local, etc.) en lugar de ejecutar lógica hardcoded.

## Componentes a diseñar

1. **ProviderContract.ps1**
   - DTO que define la interfaz de cualquier Provider
   - Métodos: Inicializar, Validar, Ejecutar, ObtenerResultado

2. **ProviderRegistry.ps1**
   - Registra providers disponibles
   - Resuelve provider por nombre/tipo

3. **AzureProvider.ps1** (primer provider)
   - Implementa ProviderContract
   - Conecta con Azure Data Factory, Storage, etc.

4. **BootstrapOrchestrator V2**
   - Adaptar para consumir providers en lugar de managers hardcoded
   - Mantener BootstrapRequest + BootstrapState como entrada/salida

## Flujo esperado

```
BootstrapRequest (con tipo de provider: Azure | AWS | Local)
  ↓
ProviderRegistry.Resolver
  ↓
Provider específico (ej: AzureProvider)
  ↓
Provider.Ejecutar
  ↓
BootstrapState actualizado con resultados del provider
```

## Restricciones de diseño

- NO modificar BootstrapRequest, BootstrapState, New-BootstrapStateFromRequest
- NO crear código en Fase 6 hasta tener diseño completo congelado
- Un provider = una responsabilidad
- Providers deben ser intercambiables sin modificar orquestador

## Criterios de éxito

- ProviderContract definido y documentado
- AzureProvider implementa contrato completo
- BootstrapOrchestrator consume providers dinámicamente
- Tests unitarios validan intercambio de providers
