# consumirFoundry.md

# Guía Operativa: Integración de Microsoft Foundry con Hermes CLI

## Objetivo

Disponer de una guía reproducible para conectar Hermes CLI con Azure AI
Foundry evitando los errores más comunes (401, 404 y 429).

## Arquitectura objetivo

Azure Subscription → Resource Group → Azure AI Services (AIServices) →
Azure AI Foundry Project → Deployment → Hermes CLI

------------------------------------------------------------------------

# Fase 1. Prerrequisitos

-   Suscripción activa de Azure.
-   Permisos:
    -   Owner o Contributor sobre la suscripción.
    -   Cognitive Services Contributor.
    -   Azure AI Developer (recomendado).
-   Azure CLI actualizado.
-   Hermes CLI instalado.
-   PowerShell 7 recomendado.
-   Acceso saliente HTTPS.

Verificar:

``` powershell
az login
az account show
az version
hermes --version
```

------------------------------------------------------------------------

# Fase 2. Crear la infraestructura

1.  Crear Resource Group.
2.  Crear recurso AIServices.
3.  Crear Proyecto en Azure AI Foundry.
4.  Asociar el proyecto al recurso AIServices.

No continuar hasta comprobar que el proyecto aparece en el portal.

------------------------------------------------------------------------

# Fase 3. Crear Deployment

Seleccionar modelo (ej. GPT-5 Mini).

Nombre recomendado:

IMP-UR-Hermes-GPT5Mini-Coding

Tipo:

Global Standard

Esperar estado:

Succeeded

Verificar:

``` powershell
az cognitiveservices account deployment list \
 --resource-group RG \
 --name Modelo
```

------------------------------------------------------------------------

# Fase 4. Obtener credenciales

Obtener endpoint:

https://`<recurso>`{=html}.openai.azure.com/openai/v1

Obtener key1 o key2:

``` powershell
az cognitiveservices account keys list
```

------------------------------------------------------------------------

# Fase 5. Validar la API ANTES de Hermes

Nunca configurar Hermes sin validar primero.

``` powershell
Invoke-RestMethod ...
```

Debe responder correctamente.

Errores:

401 = API Key.

404 = Deployment inexistente.

429 = cuota insuficiente.

------------------------------------------------------------------------

# Fase 6. Configurar Hermes

config.yaml

``` yaml
model:
  provider: azure-foundry
  base_url: https://<recurso>.openai.azure.com/openai/v1
  default: IMP-UR-Hermes-GPT5Mini-Coding
  api_mode: chat_completions
  auth_mode: api_key
```

.env

AZURE_FOUNDRY_API_KEY=`<key>`{=html}

No duplicar configuraciones "custom" salvo necesidad.

------------------------------------------------------------------------

# Fase 7. Verificaciones

Comprobar:

``` powershell
hermes config show
```

Debe mostrar:

-   provider azure-foundry
-   endpoint correcto
-   deployment correcto

------------------------------------------------------------------------

# Fase 8. Reinicio limpio

``` powershell
hermes gateway stop
taskkill /F /IM python.exe
hermes chat
```

------------------------------------------------------------------------

# Fase 9. Diagnóstico

401 - key incorrecta - endpoint incorrecto

404 - deployment inexistente - nombre incorrecto

429 - revisar rateLimits

``` powershell
az cognitiveservices account deployment show \
 --query properties.rateLimits
```

------------------------------------------------------------------------

# Fase 10. Escalar capacidad

En Foundry:

Deployment → Editar → Tokens por minuto

Confirmar:

``` powershell
az cognitiveservices account deployment show
```

Verificar incremento de: - Requests/min - Tokens/min

------------------------------------------------------------------------

# Fase 11. Observabilidad

Registrar:

-   endpoint
-   deployment
-   modelo
-   contexto
-   prompt tokens
-   completion tokens
-   latencia
-   código HTTP

------------------------------------------------------------------------

# Buenas prácticas

-   Validar API antes de Hermes.
-   Mantener un único deployment por tarea.
-   Nombrar recursos consistentemente.
-   Versionar config.yaml y .env (sin claves).

------------------------------------------------------------------------

# Acciones que NO valen la pena

-   Cambiar repetidamente la API Key sin validar manualmente.
-   Editar el modelo por nombre público (ej. gpt-5-codex-2025-09-15)
    cuando Hermes debe usar el nombre del deployment.
-   Buscar errores en Hermes antes de probar Invoke-RestMethod.
-   Reinstalar Hermes por un 401/404/429.
-   Modificar el SDK OpenAI sin evidencia.
-   Crear múltiples proyectos Foundry para el mismo entorno.
-   Mantener providers "custom" y "azure-foundry" activos para el mismo
    deployment.
-   Diagnosticar 429 sin revisar rateLimits.
-   Suponer que el endpoint es incorrecto cuando la llamada manual
    funciona.

------------------------------------------------------------------------

# Checklist final

-   Login Azure OK
-   Proyecto creado
-   AIServices creado
-   Deployment Running
-   API responde con Invoke-RestMethod
-   config.yaml correcto
-   .env correcto
-   Hermes config show correcto
-   rateLimits adecuados
-   hermes chat responde correctamente
