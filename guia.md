# GUIA.md
# Hermes Enterprise
## Guía de navegación para Agentes IA

Versión: 1.0
Autor: Fredy Alejandro Sarmiento Torres
Organización: Universidad del Rosario
Proyecto: Hermes Enterprise

---

# Objetivo

Este documento proporciona a cualquier agente IA el contexto necesario para comprender la arquitectura, configuración y flujo de trabajo del proyecto Hermes Enterprise.

Debe leerse antes de modificar archivos, ejecutar comandos o cambiar configuraciones.

---

# Estructura del proyecto

D:\
│
├── HERMES-ENTERPRISE
│   ├── infra
│   ├── docs
│   ├── scripts
│   ├── prompts
│   ├── tools
│   ├── tests
│   ├── patches
│   ├── backups
│   └── logs
│
└── hermes-ai-agent
    ├── config.yaml
    ├── .env
    ├── memory
    ├── plugins
    ├── skills
    └── ...

---

# Carpetas

## /infra

Infraestructura Azure

Deployment

PowerShell

Bicep

Terraform

ARM

Configuración Azure AI Foundry

---

## /docs

Documentación técnica

Arquitectura

Diagramas

Investigación

Notas

---

## /patches

Parches aplicados al agente Hermes

Nunca modificar sin generar respaldo.

---

## /logs

Logs de ejecución.

Analizar primero antes de modificar código.

---

# Configuración principal

Archivo:

```
D:\hermes-ai-agent\config.yaml
```

Variables sensibles:

```
D:\hermes-ai-agent\.env
```

Nunca escribir API Keys en commits.

---

# Azure

Resource Group

```
RG-Datamining-IA-UR
```

AI Service

```
Modelo-UR-Hermes
```

Proyecto

```
Proyecto-UR-Hermes
```

Deployment GPT-5 Mini

```
IMP-UR-Hermes-GPT5Mini-Coding
```

Deployment GPT-5.3 Codex

```
IMP-UR-Hermes-GPT53Codex-Coding
```

---

# Endpoint

OpenAI Compatible

```
https://modelo-ur-hermes.openai.azure.com/openai/v1
```

---

# Modelos

GPT-5 Mini

Uso general

GPT-5.3 Codex

Ingeniería de Software

DeepSeek V4 Flash

Codificación masiva

Kimi K2.7

Compresión de contexto

---

# Objetivos del proyecto

Construir un agente empresarial capaz de:

- escribir código

- modificar proyectos

- ejecutar terminal

- navegar

- usar herramientas

- operar sobre Microsoft Fabric

- administrar Azure

- conectarse con GitHub

- trabajar sobre repositorios completos

---

# Reglas

Nunca borrar información.

Siempre crear backup.

Nunca sobrescribir config.yaml sin copia.

Registrar cambios importantes.

---

# Flujo recomendado

1.

Leer config.yaml

2.

Leer .env

3.

Leer logs

4.

Validar Azure

5.

Validar deployment

6.

Ejecutar cambios

7.

Verificar

---

# Azure CLI

Ver deployments

```
az cognitiveservices account deployment list \
    --resource-group RG-Datamining-IA-UR \
    --name Modelo-UR-Hermes
```

Mostrar deployment

```
az cognitiveservices account deployment show \
    --resource-group RG-Datamining-IA-UR \
    --name Modelo-UR-Hermes \
    --deployment-name IMP-UR-Hermes-GPT5Mini-Coding
```

---

# PowerShell

Detener Hermes

```
hermes gateway stop
```

Cerrar procesos

```
taskkill /F /IM python.exe
```

Iniciar

```
hermes chat
```

---

# Diagnóstico

401

Revisar API Key.

404

Deployment inexistente.

429

Límite TPM/RPM.

Nunca asumir que Hermes está mal configurado sin verificar Azure.

---

# Estrategia de depuración

1.

Validar Azure mediante Invoke-RestMethod.

2.

Si Azure responde correctamente:

El problema está en Hermes.

3.

Buscar cambios recientes.

4.

Verificar provider.

5.

Verificar endpoint.

6.

Verificar modelo.

---

# Convenciones

Todo deployment comienza por

IMP-

Todo modelo lógico comienza por

Modelo-

Todo proyecto

Proyecto-

Todo script PowerShell

Patch-

---

# Buenas prácticas

No usar credenciales embebidas.

Preferir variables de entorno.

Usar Azure Foundry antes que Azure OpenAI Legacy.

Usar OpenAI Compatible API.

Evitar modificar archivos dentro del entorno virtual.

---

# Misión del agente

Antes de responder:

- comprender el problema

- validar configuración

- revisar logs

- proponer solución

- aplicar solución mínima

- validar funcionamiento

- documentar el cambio

Nunca improvisar configuraciones.
Siempre fundamentar las recomendaciones en evidencia del proyecto.
