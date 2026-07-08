<#
.SYNOPSIS
    CurrentStateBuilder - Genera CURRENT_STATE.md con estado actual del proyecto
.DESCRIPTION
    Crea un snapshot del estado actual del proyecto, incluyendo versión, fase,
    paso, componentes completados y pendientes. Solo contiene estado, NO memoria.
.BUDGET
    Maximo 200 lineas.
.INPUTS
    - BootstrapState: Estado actual del bootstrap con ProjectName, Fase, Step
    - OutputPath: Ruta donde se generará CURRENT_STATE.md
.OUTPUTS
    PSCustomObject con Path, Tokens, IsValid
.EXAMPLE
    $state = Get-BootstrapState
    $result = Build-CurrentState -BootstrapState $state -OutputPath "D:\HERMES-ENTERPRISE\.hermes\context"
#>
function Build-CurrentState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$BootstrapState,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    # Validar BootstrapState
    if (-not $BootstrapState.ProjectName) {
        throw "BootstrapState debe contener ProjectName"
    }
    
    # Obtener información de Git
    $commitHash = Get-GitCommitHash -OutputPath $OutputPath
    $branch = Get-GitBranch -OutputPath $OutputPath
    
    # Obtener última verificación
    $lastVerification = Get-LastVerification -OutputPath $OutputPath
    
    # Construir contenido de CURRENT_STATE.md
    $content = @"
---
contextVersion: 1
bootstrapVersion: $($BootstrapState.BootstrapVersion)
generatedAt: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
generator: CurrentStateBuilder
commit: $commitHash
---

# Estado Actual del Proyecto

## Información General
- **Proyecto:** $($BootstrapState.ProjectName)
- **Versión:** $($BootstrapState.BootstrapVersion)
- **Commit Actual:** $commitHash
- **Rama Git:** $branch
- **Fase Actual:** Fase $($BootstrapState.FaseActual)
- **Paso Actual:** Paso $($BootstrapState.StepActual)

## Componentes Implementados
"@

    # Agregar componentes completados
    if ($BootstrapState.ComponentesCompletados.Count -gt 0) {
        $BootstrapState.ComponentesCompletados | ForEach-Object {
            $content += "`n- $_"
        }
    } else {
        $content += "`n- (Ninguno)"
    }
    
    $content += "`n`n## Componentes Pendientes"
    
    # Agregar componentes pendientes
    if ($BootstrapState.ComponentesPendientes.Count -gt 0) {
        $BootstrapState.ComponentesPendientes | ForEach-Object {
            $content += "`n- $_"
        }
    } else {
        $content += "`n- (Ninguno)"
    }
    
    $content += @"


## Archivos Modificables
- \`motor\` - Módulos del motor
- \`pruebas\unitarias\` - Tests unitarios
- \`documentacion\` - Documentación técnica
- \`configuracion\` - Archivos de configuración

## Archivos Prohibidos
- \`motor\bootstrap\engine\BootstrapState.ps1\` - NO MODIFICAR
- \`motor\bootstrap\engine\BootstrapWizard.ps1\` - NO MODIFICAR
- \`motor\bootstrap\engine\EnvironmentManager.ps1\` - NO MODIFICAR

## Última Verificación
- **Fecha:** $($lastVerification.Fecha)
- **Resultado:** $($lastVerification.Resultado)
- **Script:** $($lastVerification.Script)

## Próximo Objetivo
$($BootstrapState.ProximoObjetivo)
"@
    
    # Escribir archivo con encabezado YAML
    $filePath = Join-Path $OutputPath "CURRENT_STATE.md"
    
    # Asegurar que el directorio existe
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    $content | Set-Content -Path $filePath -Encoding UTF8
    
    # Calcular tokens estimados
    $tokens = Estimate-Tokens -FilePath $filePath
    
    return [PSCustomObject]@{
        Path = $filePath
        Tokens = $tokens
        IsValid = (Test-Path $filePath)
    }
}

function Get-GitCommitHash {
    param([string]$OutputPath)
    
    try {
        $projectRoot = Split-Path $OutputPath -Parent
        $hash = git -C $projectRoot rev-parse HEAD 2>$null
        return if ($hash) { $hash } else { "unknown" }
    } catch {
        return "unknown"
    }
}

function Get-GitBranch {
    param([string]$OutputPath)
    
    try {
        $projectRoot = Split-Path $OutputPath -Parent
        $branch = git -C $projectRoot rev-parse --abbrev-ref HEAD 2>$null
        return if ($branch) { $branch } else { "unknown" }
    } catch {
        return "unknown"
    }
}

function Get-LastVerification {
    param([string]$OutputPath)
    
    $verificationFile = Join-Path $OutputPath "last-verification.json"
    if (Test-Path $verificationFile) {
        return (Get-Content $verificationFile | ConvertFrom-Json)
    }
    
    return [PSCustomObject]@{
        Fecha = "N/A"
        Resultado = "N/A"
        Script = "N/A"
    }
}

function Estimate-Tokens {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw
    # Estimación: 1 token ~= 4 caracteres (aproximación conservadora)
    return [math]::Ceiling($content.Length / 4)
}

Export-ModuleMember -Function Build-CurrentState
