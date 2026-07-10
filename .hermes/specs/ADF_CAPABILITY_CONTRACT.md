---
capability: AzureDataFactory
provider: Azure
status: diseño
sprint: 6.1
navegacion:
  - documento_relacionado: ADF_DISCOVERY_SEQUENCE.md
  - documento_relacionado: sprint-6-start-hermesproject.md
  - documento_relacionado: documentacion/bootstrap-engine/contratos-arquitectonicos.md
---

# Contrato de Capacidad — Azure Data Factory

## Índice

1. [Propósito](#proposito)
2. [Responsabilidad](#responsabilidad)
3. [No-Responsabilidad](#no-responsabilidad)
4. [Entradas](#entradas)
5. [Salidas](#salidas)
6. [Dependencias](#dependencias)
7. [Restricciones](#restricciones)
8. [Invariantes](#invariantes)
9. [Errores Esperados](#errores-esperados)
10. [Warnings](#warnings)

---

## Propósito

Permitir que el `AzureProvider` exponga una **capabilidad aislada** cuyo único
propósito es interactuar con Azure Data Factory: autenticar, descubrir
recursos, validar existencia de artefactos, y construir un contrato de
ejecución. Esta capacidad nunca ejecuta pipelines; solo prepara el terreno
para que otro componente los ejecute.

---

## Responsabilidad

| # | Responsabilidad |
|---|-----------------|
| R1 | Validar la autenticación del usuario en Azure |
| R2 | Validar la existencia de una Subscription |
| R3 | Validar la existencia de un Resource Group dentro de la Subscription |
| R4 | Validar la existencia de una Data Factory dentro del Resource Group |
| R5 | Descubrir la configuración de repositorio Git asociada a Data Factory |
| R6 | Descubrir las branches disponibles en el repositorio |
| R7 | Listar los pipelines disponibles en una branch específica |
| R8 | Obtener los parámetros declarativos de un pipeline |
| R9 | Construir un contrato de ejecución que contenga todos los artefactos necesarios |
| R10 | Reportar errores ywarnings de forma estructurada |

---

## No-Responsabilidad

| No debe |
|---------|
| Ejecutar pipelines (create-run) |
| Monitorear estados de ejecución (query-by-factory) |
| Cancelar ejecuciones en curso |
| Consultar historial de runs |
| Almacenar parámetros del pipeline entre sesiones |
| Modificar la Data Factory, pipelines, datasets o linked services |
| Gestionar Storage Account, ADLS, Blob ni Parquet (otra capacidad) |
| Invocar comandos `az` directamente (lo hace el `AzureProvider` padre) |
| Poseer estado persistente (cada invocación es idempotente sobre la Discovery) |

---

## Entradas

### 1. Identificación de Conexión

| Campo | Tipo | Obligatoria | Descripción |
|-------|------|-------------|-------------|
| `CorreoAzure` | string | ✅ | Correo del usuario autenticado |
| `IdentificadorSuscripcion` | string | ✅ | GUID de la suscripción Azure |
| `IdentificadorInquilino` | string | ⬚ | Opcional; deducido por `az account show` |

### 2. Contexto del Recurso

| Campo | Tipo | Obligatoria | Descripción |
|-------|------|-------------|-------------|
| `NombreResourceGroup` | string | ✅ | Grupo de recursos donde vive la Data Factory |
| `NombreDataFactory` | string | ✅ | Nombre exacto de la instancia ADF |

### 3. Contexto de Repositorio

| Campo | Tipo | Obligatoria | Descripción |
|-------|------|-------------|-------------|
| `NombreRepositorioGit` | string | ✅ | Nombre del repositorio configurado en ADF |
| `NombreBranch` | string | ✅ | Branch activa de los artefactos ADF |

### 4. Contexto de Pipeline

| Campo | Tipo | Obligatoria | Descripción |
|-------|------|-------------|-------------|
| `NombrePipeline` | string | ✅ | Nombre del pipeline seleccionado |
| `ParametrosUsuario` | hash | ⬚ | Valores que el usuario provee para los parámetros declarados |

> **Nota**: `NombrePipeline` entra vacío la primera vez y se completa cuando el
> usuario lo selecciona en el menú de descubrimiento. Ver
> [`ADF_DISCOVERY_SEQUENCE.md`](./ADF_DISCOVERY_SEQUENCE.md).

---

## Salidas

### Salida de Discovery (sin ejecución)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `SuscripcionValidada` | bool | Existe y es accesible |
| `ResourceGroupValidado` | bool | Existe dentro de la suscripción |
| `DataFactoryValidada` | bool | Existe dentro del Resource Group |
| `RepositorioDescubierto` | hash | Configuración Git de la Data Factory |
| `BranchesDisponibles` | array | Branches del repositorio |
| `PipelineSeleccionado` | string | Nombre resuelto |
| `ParametrosDeclarados` | hash | Parámetros que el pipeline espera |
| `ParametrosResueltos` | hash | Valores proveídos por el usuario |

### Salida de Contrato de Ejecución

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `Inquilino` | string | GUID del tenant |
| `Suscripcion` | string | Nombre y GUID de la suscripción |
| `ResourceGroup` | string | Nombre del Resource Group |
| `DataFactory` | string | Nombre de la instancia ADF |
| `Repositorio` | hash | `{nombre, tipo, urlBase}` |
| `Branch` | string | Nombre de la branch resuelta |
| `Pipeline` | hash | `{nombre, parametros}` |
| `ParametrosResueltos` | hash | K/V listos para la ejecución |
| `Estado` | string | `ReadyToExecute \\| ValidationFailed` |
| `Errores` | array | Lista estructurada de fallos |
| `Warnings` | array | Lista estructurada de advertencias |

---

## Dependencias

| Dependencia | Proveedor | Motivo |
|-------------|-----------|--------|
| `AzureProvider` | `motor/providers/azure/` | Ejecuta comandos `az` delegados |
| `AzureAuthenticationCapability` | `motor/providers/azure/` | Provee sesión autenticada |
| `BootstrapState` | `motor/bootstrap/engine/` | Contexto global del proyecto |
| `AzurePluginContract` | `motor/contracts/` | Formato canónico de entrada/salida |

---

## Restricciones

| # | Restricción |
|---|-------------|
| R1 | No puede invocar `az` de forma directa. Toda llamada debe pasar por `AzureProvider`. |
| R2 | No puede almacenar secretos, credenciales ni tokens en disco. |
| R3 | No puede asumir una Data Factory por defecto (ni siquiera la del caso de uso del usuario). |
| R4 | Todos los parámetros que el pipeline declare deben ser resueltos antes de marcar `ReadyToExecute`. |
| R5 | No puede producir efectos secundarios sobre Azure (lectura única). |
| R6 | Todos los nombres de función, variable y parámetro deben estar en español. |
| R7 | La capacidad debe ser intercambiable por otra (ej: `SynapseDataFactoryCapability`) sin tocar `AzureProvider`. |

---

## Invariantes

Durante toda la ejecución de la capacidad, estas afirmaciones deben ser ciertas:

| # | Invariante |
|---|----------|
| I1 | Si `Estado = Ready`, entonces `SuscripcionValidada = ResourceGroupValidado = DataFactoryValidada = $true`. |
| I2 | Si el pipeline declara `N` parámetros requeridos sin default, `ParametrosResueltos` debe contener exactamente esos `N` parámetros. |
| I3 | Si existe al menos un error, entonces `Estado ≠ ReadyToExecute`. |
| I4 | `NombreDataFactory` nunca se completa desde valores hardcoded; siempre proviene de la entrada del usuario o del discovery. |
| I5 | Los `Warnings` no modifican el `Estado`, solo lo enriquecen. |

---

## Errores Esperados

| Código | Descripción | Acción Sugerida |
|--------|------------|------------------|
| `ERR_AZ_AUTH_FAILED` | La autenticación `az login` falló | Re-autenticarse |
| `ERR_AZ_SUB_NOT_FOUND` | La Subscription no existe o no es accesible | Verificar GUID |
| `ERR_AZ_RG_NOT_FOUND` | El Resource Group no existe | Verificar nombre |
| `ERR_AZ_ADF_NOT_FOUND` | La Data Factory no existe | Verificar nombre |
| `ERR_AZ_REPO_NOT_CONFIGURED` | La Data Factory no tiene repositorio configurado | Configurar Git en ADF |
| `ERR_AZ_BRANCH_NOT_FOUND` | La branch no existe en el repositorio | Verificar nombre de branch |
| `ERR_AZ_PIPELINE_NOT_FOUND` | El pipeline no existe en esa branch | Verificar nombre |
| `ERR_AZ_PIPELINE_PARAMS_MISSING` | Faltan parámetros requeridos sin default | Solicitarlos al usuario |
| `ERR_CONTRACTO_INVALIDO` | La estructura del contrato viola invariantes | Rechazar construcción |

---

## Warnings

| Código | Condición | Significado |
|--------|-----------|-------------|
| `WRN_AZ_PIPELINE_NO_PARAMS` | Pipeline sin parámetros declarados | No requiere interacción adicional |
| `WRN_AZ_PARQUET_NOT_FOUND` | No se detecta Parquet en la salida (solo lectura) | Verificar tras ejecución |
| `WRN_AZ_BRANCH_DETACHED` | Branch no coincide con default del repositorio | Confirmar intención |

---

## Referencias

- [`ADF_DISCOVERY_SEQUENCE.md`](./ADF_DISCOVERY_SEQUENCE.md)
- [Contratos Arquitectónicos Bootstrap](../documentacion/bootstrap-engine/contratos-arquitectonicos.md)
- [`AzurePluginContract`](../motor/contracts/AzurePluginContract.ps1) ← *pendiente de Fase 6.0*
