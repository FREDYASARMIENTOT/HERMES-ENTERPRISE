---
capability: AzureDataFactory
tipo: secuencia
status: diseño
sprint: 6.1
navegacion:
  - documento_relacionado: ADF_CAPABILITY_CONTRACT.md
  - documento_relacionado: sprint-6-start-hermesproject.md
---

# Secuencia de Descubrimiento — Azure Data Factory

## Índice

1. [Propósito de la Secuencia](#proposito)
2. [Modelo C4 — Contexto](#c4-contexto)
3. [Flujo Completo](#flujo-completo)
4. [Detalle de Pasos](#detalle-de-pasos)
5. [Matriz de Validaciones](#matriz-de-validaciones)
6. [Condiciones de Detención](#condiciones-de-detencion)
7. [Estado Final del Discovery](#estado-final)
8. [Referencias](#referencias)

---

## Propósito

Describir el orden exacto en que `AzureDataFactoryCapability` descubre y
valida los recursos de Azure necesarios para construir un contrato de
ejecución. Esta secuencia **exclusivamente lee**. No ejecuta pipelines, no
modifica recursos, no genera efectos secundarios sobre el tenant.

Cada paso tiene tres propiedades:

- **Entrada**: qué datos necesita del usuario o del paso anterior.
- **Salida**: qué produce y deja disponible para el siguiente paso.
- **Validación**: qué condición debe cumplirse para continuar.

---

## C4 Contexto

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            USUARIO                                     │
│     (Correo Azure, Selections: Subscription, RG, Factory, Branch, etc.)│
└───────────────────────────────┬─────────────────────────────────────────┘
                                │  selecciona / provee datos
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       Start-HermesProject                              │
│                  Entry Point del Bootstrap Engine                      │
│         motor/bootstrap/Start-HermesProject.ps1                        │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │  delega
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        ProviderManager                                 │
│        Resuelve Provider por nombre ("Azure")                          │
│         motor/providers/ProviderManager.ps1                            │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │  invoca
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         AzureProvider                                  │
│    Orquesta capacidades (Auth, Discovery, Execution)                   │
│    motor/providers/azure/AzureProvider.ps1                             │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │  delega a capacidad
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                AzureDataFactoryCapability                             │
│             (este documento define su discovery)                      │
│             motor/providers/azure/capabilities/                       │
│                      AzureDataFactoryCapability.ps1                   │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │  delega llamadas az
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      Azure REST API / az CLI                           │
│             (fuera del proceso, remoto)                                │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Flujo Completo

```
Usuario            Capability           AzureProvider            Azure
  │                    │                      │                    │
  │──(1) auth──────────│─────────────────────▶│──az login────────▶│
  │                    │◀─(sesion-ok)─────────│◀──────────────────│
  │                    │                      │                    │
  │──(2) subs list────▶│─────────────────────▶│──account list────▶│
  │                    │◀─────────────────────│◀──(array subs)────│
  │──(3) elige sub────▶│──seleccion──────────│                    │
  │                    │──(4) account set────▶│──account set──────▶│
  │                    │◀──(ok)──────────────│◀───────────────────│
  │                    │                      │                    │
  │──(5) RG list──────▶│─────────────────────▶│──group list──────▶│
  │                    │◀─────────────────────│◀──(array RG)──────│
  │──(6) elige RG─────▶│──seleccion──────────│                    │
  │                    │                      │                    │
  │──(7) ADF list─────▶│─────────────────────▶│──factory list────▶│
  │                    │◀─────────────────────│◀──(array ADF)─────│
  │──(8) elige ADF────▶│──seleccion──────────│                    │
  │                    │                      │                    │
  │                   (9) repositorio configurado (az datafactory show)
  │                    │──descubre repo─────▶│──show──────────────▶│
  │                    │◀─────────────────────│◀──(repo config)────│
  │                    │                      │                    │
  │                   (10) branches
  │                    │──list branches─────▶│────────────────────▶│
  │                    │◀─────────────────────│◀──(array branch)───│
  │──(11) elige branch▶│──seleccion──────────│                    │
  │                    │                      │                    │
  │                   (12) pipelines
  │                    │──pipeline list─────▶│────────────────────▶│
  │                    │◀─────────────────────│◀──(array pipes)────│
  │──(13) elige pipe──▶│──seleccion──────────│                    │
  │                    │                      │                    │
  │                   (14) parámetros del pipeline
  │                    │──pipeline show─────▶│────────────────────▶│
  │                    │◀─────────────────────│◀──(param schema)───│
  │──(15) values──────▶│                      │                    │
  │                    │                      │                    │
  │                   Contrato ejecucion ←──────────────┐         │
  │◀──(16) contrato────────────────────────────────────┘         │
  │                                                                │
```

---

## Detalle de Pasos

### Paso 1 — Autenticación

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | `CorreoAzure` |
| Salida       | Sesión activa de Azure CLI |
| Validación   | `az login` exitoso + `az account show` retorna cuenta |
| Error si falla | `ERR_AZ_AUTH_FAILED` |

### Paso 2 — Listado de Suscripciones

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | Sesión activa |
| Salida       | Array `{id, nombre, estado, tenantId}` |
| Validación   | Al menos una subscription accesible |
| Error si falla | `ERR_AZ_SUB_NOT_FOUND` |

### Paso 3 — Selección de Subscription (usuario)

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | Lista del Paso 2 |
| Salida       | `IdentificadorSuscripcion` |
| Validación   | Usuario selecciona una opción válida |
| Acción       | Se mantiene en memoria de Capability |

### Paso 4 — Activación de Subscription

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | `IdentificadorSuscripcion` |
| Salida       | Suscripción activa en sessão |
| Validación   | `az account set` exitoso + `account show` refleja la suscripción |
| Error si falla | `ERR_AZ_SUB_NOT_FOUND` |

### Paso 5 — Listado de Resource Groups

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | Suscripción activa |
| Salida       | Array `{nombre, ubicacion, tags}` |
| Validación   | Al menos un Resource Group visible |
| Error si falla | `ERR_AZ_RG_NOT_FOUND` |

### Paso 6 — Selección de Resource Group (usuario)

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | Lista del Paso 5 |
| Salida       | `NombreResourceGroup` |
| Validación   | Usuario selecciona una opción válida |

### Paso 7 — Listado de Data Factories

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | `NombreResourceGroup` |
| Salida       | Array `{nombre, ubicacion, provisioningState}` dentro del RG |
| Validación   | Al menos una Data Factory existente |
| Error si falla | `ERR_AZ_ADF_NOT_FOUND` |

### Paso 8 — Selección de Data Factory (usuario)

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | Lista del Paso 7 |
| Salida       | `NombreDataFactory` |
| Validación   | Usuario selecciona una opción válida |

### Paso 9 — Descubrimiento de Repositorio

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | `NombreDataFactory` |
| Salida       | `{tipoRepo, nombreRepo, accountName, projectName}` |
| Validación   | La Data Factory tiene repositorio configurado (collaboration) |
| Error si falla | `ERR_AZ_REPO_NOT_CONFIGURED` |

### Paso 10 — Listado de Branches

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | Repositorio del Paso 9 |
| Salida       | Array `[{nombre, esDefault}]` |
| Validación   | Al menos una branch disponible |
| Error si falla | `ERR_AZ_BRANCH_NOT_FOUND` |

### Paso 11 — Selección de Branch (usuario)

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | Lista del Paso 10 |
| Salida       | `NombreBranch` |
| Validación   | Usuario selecciona una opción válida |

### Paso 12 — Listado de Pipelines

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | `NombreDataFactory` + `NombreBranch` |
| Salida       | Array `{nombre, descripcion, folder}` |
| Validación   | Al menos un pipeline en esa branch |
| Error si falla | `ERR_AZ_PIPELINE_NOT_FOUND` |

### Paso 13 — Selección de Pipeline (usuario)

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | Lista del Paso 12 |
| Salida       | `NombrePipeline` |
| Validación   | Usuario selecciona una opción válida |

### Paso 14 — Extracción de Parámetros del Pipeline

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | `NombrePipeline` |
| Salida       | `[{nombre, tipo, defaultValue?, isRequired}]` |
| Validación   | Esquema completo retornado por el backend |
| Error si falla | `ERR_AZ_PIPELINE_PARAMS_MISSING` (solo si hay requeridos sin default) |
| Warning      | `WRN_AZ_PIPELINE_NO_PARAMS` si no hay parámetros |

### Paso 15 — Provisión de Valores por el Usuario

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | Esquema de parámetros del Paso 14 |
| Salida       | `ParametrosResueltos = {nombre1: valor1, ...}` |
| Validación   | Cada parámetro requerido tiene valor + tipo compatible |
| Error si falla | `ERR_AZ_PIPELINE_PARAMS_MISSING` |

### Paso 16 — Construcción del Contrato de Ejecución

| Propiedad    | Valor |
|--------------|-------|
| Entrada      | Todos los pasos previos |
| Salida       | `ContratoEjecucionADF` (ver [`ADF_CAPABILITY_CONTRACT.md`](./ADF_CAPABILITY_CONTRACT.md)) |
| Validación   | Invariantes I1–I5 cumplidas |
| Error si falla | `ERR_CONTRACTO_INVALIDO` |

---

## Matriz de Validaciones

| Paso | Valida existencia | Valida acceso | Valida integridad |
|------|-------------------|---------------|-------------------|
| 1    | —                 | ✅ sesion      | —                 |
| 2    | ✅ subs           | ✅              | —                 |
| 3    | —                 | —             | ✅ selección      |
| 4    | ✅ activa         | ✅              | —                 |
| 5    | ✅ RG             | ✅              | —                 |
| 6    | —                 | —             | ✅ selección      |
| 7    | ✅ ADF            | ✅              | —                 |
| 8    | —                 | —             | ✅ selección      |
| 9    | ✅ repo config    | ✅              | —                 |
| 10   | ✅ branches       | ✅              | —                 |
| 11   | —                 | —             | ✅ selección      |
| 12   | ✅ pipelines      | ✅              | —                 |
| 13   | —                 | —             | ✅ selección      |
| 14   | ✅ schema         | ✅              | —                 |
| 15   | —                 | —             | ✅ valores        |
| 16   | —                 | —             | ✅ invariantes    |

---

## Condiciones de Detención

El discovery se **detiene inmediatamente** cuando ocurre cualquiera de:

1. Un `ERR_*` no tiene estrategia de retry definida.
2. El usuario cancela una selección (Paso 3, 6, 8, 11, 13, 15).
3. Se alcanza un límite de tiempo configurado (default = 120 segundos por paso).
4. Se excede el número máximo de reintentos de autenticación (default = 3).

Al detenerse:

- El `Estado` se marca como `ValidationFailed`.
- El paso que causó la detención se registra con su código de error.
- Los pasos previos exitosos **no se descartan** (sirven para diagnóstico).

---

## Estado Final

Al completar los 16 pasos sin errores, la capacidad produce:

| Campo | Valor |
|-------|-------|
| `SuscripcionValidada` | `$true` |
| `ResourceGroupValidado` | `$true` |
| `DataFactoryValidada` | `$true` |
| `RepositorioDescubierto` | hash con `{tipo, nombre, cuenta, proyecto}` |
| `BranchesDisponibles` | array (ya no vacío) |
| `PipelineSeleccionado` | string con el nombre |
| `ParametrosDeclarados` | esquema completo |
| `ParametrosResueltos` | hash K/V |
| `Estado` | `ReadyToExecute` |
| `Errores` | `[]` |
| `Warnings` | `[]` (o populated según Paso 14) |

Si cualquier paso falla parcialmente (con advertencias pero sin error),
`Estado = ReadyToExecute` + `Warnings` populated.

---

## Referencias

- [`ADF_CAPABILITY_CONTRACT.md`](./ADF_CAPABILITY_CONTRACT.md)
- [Contratos Arquitectónicos Bootstrap](../documentacion/bootstrap-engine/contratos-arquitectonicos.md)
