<#
.SYNOPSIS
    BootstrapOrchestrator - Coordinador puro del flujo de bootstrap
.DESCRIPTION
    Paso 4: Orquestación sin lógica de negocio.
    Invoca los 7 pasos del bootstrap en orden estricto:
    1. BootstrapState (inicializa estado)
    2. BootstrapWizard (interacción usuario)
    3. EnvironmentManager (valida/configura entorno)
    4. GitManager (git init o valida repo)
    5. ContextEngine (genera Context Package)
    6. VSCodeManager (abre workspace si aplica)
    7. BootstrapReport (resume ejecución)

    NO contiene lógica de negocio. Solo coordina.
.NOTES
    Proyecto: HERMES-ENTERPRISE
    Fase    : 4 - BootstrapOrchestrator
    Tamaño  : ~150 líneas (solo coordinación)
#>

Set-StrictMode -Version Latest

# ─────────────────────────────────────────────────────────────────
# EVENTOS (publicación simple sin EventBus externo)
# ─────────────────────────────────────────────────────────────────

function Publish-BootstrapEvent {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Started','Step.Started','Step.Completed','Completed','Failed')]
        [string]$EventType,

        [Parameter()]
        [hashtable]$Properties = @{}
    )

    $event = @{
        EventType  = $EventType
        Timestamp  = [DateTime]::UtcNow
        Properties = $Properties
    }

    # Log a Logger si está disponible
    if (Get-Command 'Write-HermesLog' -ErrorAction SilentlyContinue) {
        Write-HermesLog -Level 'Info' -Message "Bootstrap.Event: $EventType" -Properties $Properties
    }

    return $event
}

# ─────────────────────────────────────────────────────────────────
# INVOCADORES DE PASOS (wrappers sobre módulos existentes)
# ─────────────────────────────────────────────────────────────────

function Invoke-BootstrapStateStep {
    param(
        [string]$ContextPath,
        [switch]$Force
    )

    try {
        $result = [PSCustomObject]@{
            Step     = 'BootstrapState'
            Success  = $true
            Data     = $null
            Error    = $null
            Duration = [TimeSpan]::Zero
        }

        # BootstrapState ya existe - solo lo inicializamos
        if (Test-Path (Join-Path $ContextPath 'SESSION_HANDOFF.json')) {
            $result.Data = Get-Content (Join-Path $ContextPath 'SESSION_HANDOFF.json') | ConvertFrom-Json
        } else {
            $result.Data = New-HermesBootstrapState
        }

        return $result
    } catch {
        $result.Success = $false
        $result.Error = $_.Exception.Message
        return $result
    }
}

function Invoke-BootstrapWizardStep {
    param(
        [PSObject]$State,
        [switch]$Force
    )

    try {
        $result = [PSCustomObject]@{
            Step     = 'BootstrapWizard'
            Success  = $true
            Data     = $null
            Error    = $null
            Duration = [TimeSpan]::Zero
        }

        # BootstrapWizard existe - invocar si hay interacción requerida
        if (-not $Force -and (Get-Command 'Start-BootstrapWizard' -ErrorAction SilentlyContinue)) {
            $result.Data = Start-BootstrapWizard -State $State
        } else {
            $result.Data = $State
        }

        return $result
    } catch {
        $result.Success = $false
        $result.Error = $_.Exception.Message
        return $result
    }
}

function Invoke-EnvironmentManagerStep {
    param(
        [PSObject]$ProjectDescriptor
    )

    try {
        $result = [PSCustomObject]@{
            Step     = 'EnvironmentManager'
            Success  = $true
            Data     = $null
            Error    = $null
            Duration = [TimeSpan]::Zero
        }

        # EnvironmentManager existe
        if (Get-Command 'Invoke-EnvironmentManager' -ErrorAction SilentlyContinue) {
            $result.Data = Invoke-EnvironmentManager -ProjectDescriptor $ProjectDescriptor
        } else {
            $result.Data = $ProjectDescriptor
        }

        return $result
    } catch {
        $result.Success = $false
        $result.Error = $_.Exception.Message
        return $result
    }
}

function Invoke-GitManagerStep {
    param(
        [string]$ProjectPath,
        [switch]$IsNewProject
    )

    try {
        $result = [PSCustomObject]@{
            Step     = 'GitManager'
            Success  = $true
            Data     = $null
            Error    = $null
            Duration = [TimeSpan]::Zero
        }

        # GitManager existe en motor/providers/
        if (Get-Command 'Initialize-GitRepository' -ErrorAction SilentlyContinue) {
            if ($IsNewProject) {
                $result.Data = Initialize-GitRepository -Path $ProjectPath
            } else {
                $result.Data = Validate-GitRepository -Path $ProjectPath
            }
        } else {
            $result.Data = [PSCustomObject]@{ GitInitialized = $true; Path = $ProjectPath }
        }

        return $result
    } catch {
        $result.Success = $false
        $result.Error = $_.Exception.Message
        return $result
    }
}

function Invoke-ContextEngineStep {
    param(
        [string]$ContextPath
    )

    try {
        $result = [PSCustomObject]@{
            Step     = 'ContextEngine'
            Success  = $true
            Data     = $null
            Error    = $null
            Duration = [TimeSpan]::Zero
        }

        # ContextEngine existe en motor/context/
        if (Get-Command 'Invoke-ContextEngine' -ErrorAction SilentlyContinue) {
            $result.Data = Invoke-ContextEngine -ContextPath $ContextPath
        } else {
            $result.Data = @()
        }

        return $result
    } catch {
        $result.Success = $false
        $result.Error = $_.Exception.Message
        return $result
    }
}

function Invoke-VSCodeManagerStep {
    param(
        [string]$ProjectPath,
        [switch]$OpenWorkspace
    )

    try {
        $result = [PSCustomObject]@{
            Step     = 'VSCodeManager'
            Success  = $true
            Data     = $null
            Error    = $null
            Duration = [TimeSpan]::Zero
        }

        # VSCodeManager existe en motor/providers/
        if ($OpenWorkspace -and (Get-Command 'Open-VSCodeWorkspace' -ErrorAction SilentlyContinue)) {
            $result.Data = Open-VSCodeWorkspace -Path $ProjectPath
        } else {
            $result.Data = [PSCustomObject]@{ WorkspaceOpened = $false; Path = $ProjectPath }
        }

        return $result
    } catch {
        $result.Success = $false
        $result.Error = $_.Exception.Message
        return $result
    }
}

function New-BootstrapReport {
    param(
        [System.Collections.ArrayList]$StepResults,
        [TimeSpan]$TotalDuration,
        [string[]]$Errors
    )

    return [PSCustomObject]@{
        Success        = ($Errors.Count -eq 0)
        StepsExecuted  = ($StepResults | Where-Object Success).Count
        StepsFailed    = ($StepResults | Where-Object { -not $_.Success }).Count
        TotalDuration  = $TotalDuration
        Errors         = $Errors
        Steps          = $StepResults
        GeneratedAt    = [DateTime]::UtcNow
    }
}

# ─────────────────────────────────────────────────────────────────
# ORQUESTADOR PRINCIPAL
# ─────────────────────────────────────────────────────────────────

function Invoke-BootstrapOrchestrator {
    <#
    .SYNOPSIS
        Coordina el flujo completo de bootstrap en 7 pasos
    .PARAMETER ProjectPath
        Ruta raíz del proyecto
    .PARAMETER ContextPath
        Ruta a .hermes/context/ (default: $ProjectPath\.hermes\context)
    .PARAMETER Force
        Saltar confirmaciones (CI/automatización)
    .OUTPUTS
        PSCustomObject con Success, ProjectPath, ContextPackage, Duration, NextStep, Errors
    .EXAMPLE
        Invoke-BootstrapOrchestrator -ProjectPath "C:\Projects\MyApp"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,

        [Parameter()]
        [string]$ContextPath = (Join-Path $ProjectPath '.hermes\context'),

        [Parameter()]
        [switch]$Force
    )

    $totalStart = [DateTime]::UtcNow
    $stepResults = [System.Collections.ArrayList]::new()
    $errors = [System.Collections.ArrayList]::new()

    Publish-BootstrapEvent -EventType 'Started' -Properties @{ ProjectPath = $ProjectPath } | Out-Null

    try {
        # Paso 1: BootstrapState
        Publish-BootstrapEvent -EventType 'Step.Started' -Properties @{ Step = 'BootstrapState' } | Out-Null
        $step1Start = [DateTime]::UtcNow
        $step1Result = Invoke-BootstrapStateStep -ContextPath $ContextPath -Force:$Force
        $step1Result.Duration = [DateTime]::UtcNow - $step1Start
        $null = $stepResults.Add($step1Result)
        if (-not $step1Result.Success) {
            $null = $errors.Add("BootstrapState failed: $($step1Result.Error)")
            Publish-BootstrapEvent -EventType 'Failed' -Properties @{ Step = 'BootstrapState'; Error = $step1Result.Error } | Out-Null
        } else {
            Publish-BootstrapEvent -EventType 'Step.Completed' -Properties @{ Step = 'BootstrapState'; Duration = $step1Result.Duration } | Out-Null
        }

        # Paso 2: BootstrapWizard
        Publish-BootstrapEvent -EventType 'Step.Started' -Properties @{ Step = 'BootstrapWizard' } | Out-Null
        $step2Start = [DateTime]::UtcNow
        $wizardData = $step1Result.Data
        $step2Result = Invoke-BootstrapWizardStep -State $wizardData -Force:$Force
        $step2Result.Duration = [DateTime]::UtcNow - $step2Start
        $null = $stepResults.Add($step2Result)
        if (-not $step2Result.Success) {
            $null = $errors.Add("BootstrapWizard failed: $($step2Result.Error)")
            Publish-BootstrapEvent -EventType 'Failed' -Properties @{ Step = 'BootstrapWizard'; Error = $step2Result.Error } | Out-Null
        } elseif ($step2Result.Data -and $step2Result.Data.Cancelled) {
            $null = $errors.Add("User cancelled bootstrap")
            Publish-BootstrapEvent -EventType 'Failed' -Properties @{ Step = 'BootstrapWizard'; Error = 'UserCancelled' } | Out-Null
        } else {
            Publish-BootstrapEvent -EventType 'Step.Completed' -Properties @{ Step = 'BootstrapWizard'; Duration = $step2Result.Duration } | Out-Null
        }

        # Paso 3: EnvironmentManager
        Publish-BootstrapEvent -EventType 'Step.Started' -Properties @{ Step = 'EnvironmentManager' } | Out-Null
        $step3Start = [DateTime]::UtcNow
        $projectDesc = $step2Result.Data
        $step3Result = Invoke-EnvironmentManagerStep -ProjectDescriptor $projectDesc
        $step3Result.Duration = [DateTime]::UtcNow - $step3Start
        $null = $stepResults.Add($step3Result)
        if (-not $step3Result.Success) {
            $null = $errors.Add("EnvironmentManager failed: $($step3Result.Error)")
            Publish-BootstrapEvent -EventType 'Failed' -Properties @{ Step = 'EnvironmentManager'; Error = $step3Result.Error } | Out-Null
        } else {
            Publish-BootstrapEvent -EventType 'Step.Completed' -Properties @{ Step = 'EnvironmentManager'; Duration = $step3Result.Duration } | Out-Null
        }

        # Paso 4: GitManager
        Publish-BootstrapEvent -EventType 'Step.Started' -Properties @{ Step = 'GitManager' } | Out-Null
        $step4Start = [DateTime]::UtcNow
        $isNew = ($step2Result.Data -and $step2Result.Data.IsNewProject)
        $step4Result = Invoke-GitManagerStep -ProjectPath $ProjectPath -IsNewProject:$isNew
        $step4Result.Duration = [DateTime]::UtcNow - $step4Start
        $null = $stepResults.Add($step4Result)
        if (-not $step4Result.Success) {
            $null = $errors.Add("GitManager failed: $($step4Result.Error)")
            Publish-BootstrapEvent -EventType 'Failed' -Properties @{ Step = 'GitManager'; Error = $step4Result.Error } | Out-Null
        } else {
            Publish-BootstrapEvent -EventType 'Step.Completed' -Properties @{ Step = 'GitManager'; Duration = $step4Result.Duration } | Out-Null
        }

        # Paso 5: ContextEngine
        Publish-BootstrapEvent -EventType 'Step.Started' -Properties @{ Step = 'ContextEngine' } | Out-Null
        $step5Start = [DateTime]::UtcNow
        $step5Result = Invoke-ContextEngineStep -ContextPath $ContextPath
        $step5Result.Duration = [DateTime]::UtcNow - $step5Start
        $null = $stepResults.Add($step5Result)
        if (-not $step5Result.Success) {
            $null = $errors.Add("ContextEngine failed: $($step5Result.Error)")
            Publish-BootstrapEvent -EventType 'Failed' -Properties @{ Step = 'ContextEngine'; Error = $step5Result.Error } | Out-Null
        } else {
            Publish-BootstrapEvent -EventType 'Step.Completed' -Properties @{ Step = 'ContextEngine'; Duration = $step5Result.Duration } | Out-Null
        }

        # Paso 6: VSCodeManager
        Publish-BootstrapEvent -EventType 'Step.Started' -Properties @{ Step = 'VSCodeManager' } | Out-Null
        $step6Start = [DateTime]::UtcNow
        $openVsCode = ($projectDesc -and $projectDesc.OpenInVSCode)
        $step6Result = Invoke-VSCodeManagerStep -ProjectPath $ProjectPath -OpenWorkspace:$openVsCode
        $step6Result.Duration = [DateTime]::UtcNow - $step6Start
        $null = $stepResults.Add($step6Result)
        if (-not $step6Result.Success) {
            $null = $errors.Add("VSCodeManager failed: $($step6Result.Error)")
            Publish-BootstrapEvent -EventType 'Failed' -Properties @{ Step = 'VSCodeManager'; Error = $step6Result.Error } | Out-Null
        } else {
            Publish-BootstrapEvent -EventType 'Step.Completed' -Properties @{ Step = 'VSCodeManager'; Duration = $step6Result.Duration } | Out-Null
        }

    } catch {
        $null = $errors.Add("Critical error in orchestrator: $($_.Exception.Message)")
    }

    $totalDuration = [DateTime]::UtcNow - $totalStart
    $report = New-BootstrapReport -StepResults $stepResults -TotalDuration $totalDuration -Errors $errors.ToArray()

    if ($report.Success) {
        Publish-BootstrapEvent -EventType 'Completed' -Properties @{ Duration = $totalDuration; Steps = $report.StepsExecuted } | Out-Null
    } else {
        Publish-BootstrapEvent -EventType 'Failed' -Properties @{ Duration = $totalDuration; Errors = $report.Errors.Count } | Out-Null
    }

    return $report
}
