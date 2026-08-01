<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Diagnostics.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Diagnóstico del Kernel Enterprise — validación de dependencias, rutas y subsistemas.
====================================================================================================
#>

Set-StrictMode -Version Latest

function Test-HermesEnterpriseKernelDiagnostics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$KernelEnterprise
    )

    $issues = [System.Collections.ArrayList]@()
    $warnings = [System.Collections.ArrayList]@()

    # Verificar existencia de archivos de configuración
    $configPaths = @(
        @{ Path = Join-Path (Get-Location).Path 'Hermes.config.json'; Label = 'Hermes.config.json (root)' },
        @{ Path = Join-Path (Get-Location).Path 'configuracion/kernel.enterprise.json'; Label = 'kernel.enterprise.json (config)' },
        @{ Path = Join-Path (Get-Location).Path 'configuracion/bootstrap.enterprise.json'; Label = 'bootstrap.enterprise.json (config)' }
    )

    foreach ($cp in $configPaths) {
        if (-not (Test-Path $cp.Path)) {
            $null = $warnings.Add("Configuration file not found: $($cp.Label)")
        }
    }

    # Verificar subsistemas del kernel
    $checks = @(
        @{ Name = 'ConfigurationManager'; Object = $KernelEnterprise.AdministradorConfiguracion; Critical = $true },
        @{ Name = 'ModuleRegistry';      Object = $KernelEnterprise.RegistroModulos;          Critical = $true },
        @{ Name = 'Logger';              Object = $KernelEnterprise.Logger;                    Critical = $false },
        @{ Name = 'EventBus';            Object = $KernelEnterprise.EventBus;                  Critical = $true },
        @{ Name = 'Runtime';             Object = $KernelEnterprise.Runtime;                   Critical = $true },
        @{ Name = 'PluginManager';       Object = $KernelEnterprise.PluginManager;            Critical = $false },
        @{ Name = 'DependencyContainer'; Object = $KernelEnterprise.ContenedorDependencias;    Critical = $true }
    )

    foreach ($chk in $checks) {
        if ($null -eq $chk.Object) {
            $msg = "Subsystem missing: $($chk.Name)"
            if ($chk.Critical) {
                $null = $issues.Add("CRITICAL: $msg")
            } else {
                $null = $warnings.Add("WARNING: $msg")
            }
        }
    }

    # Verificar errores de arranque
    if ($KernelEnterprise.ErroresArranque.Count -gt 0) {
        foreach ($err in $KernelEnterprise.ErroresArranque) {
            $null = $issues.Add("Boot error: $($err.Subsistema) -> $($err.Error)")
        }
    }

    return [pscustomobject][ordered]@{
        FechaDiagnostico = (Get-Date).ToString('o')
        EstadoKernel     = $KernelEnterprise.EstadoKernel
        IssuesCriticos   = $issues.Count
        Advertencias     = $warnings.Count
        DetalleIssues    = $issues
        DetalleWarnings  = $warnings
    }
}

function Repair-HermesEnterpriseKernelIssue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$DiagnosticoKernel,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $repaired = [System.Collections.ArrayList]@()

    foreach ($issue in $DiagnosticoKernel.DetalleIssues) {
        if ($issue -match 'CRITICAL: Subsystem missing:') {
            $null = $repaired.Add("Cannot auto-repair subsystem: $issue")
        } else {
            $null = $repaired.Add("Manual intervention required: $issue")
        }
    }

    return [pscustomobject][ordered]@{
        FechaReparacion = (Get-Date).ToString('o')
        Reparados       = $repaired.Count
        Detalle         = $repaired
    }
}

Export-ModuleMember -Function Test-HermesEnterpriseKernelDiagnostics, Repair-HermesEnterpriseKernelIssue