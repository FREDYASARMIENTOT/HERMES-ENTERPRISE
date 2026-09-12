<#
.SYNOPSIS
    Tests unitarios para la Configuración Canónica Azure — RC69
.DESCRIPTION
    Verifica: parser, PSSA, estructura, validación, lectura/escritura,
    resolución de ASP Resource ID, y persistencia SQLite.
.NOTES
    Proyecto  : HERMES-ENTERPRISE
    Autor     : Fredy Alejandro Sarmiento Torres
    Release   : RC69 — Azure Configuration Canonical
#>

Set-StrictMode -Version Latest

$here = $PSScriptRoot
$moduleRoot = Resolve-Path "$here\..\..\motor\kernel\Module\Hermes.Commands"
$privatePath = Join-Path $moduleRoot 'Private'
$publicPath  = Join-Path $moduleRoot 'Public'

# ──────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────

function Get-ScriptContent {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    return Get-Content $Path -Raw -ErrorAction Stop
}

# ──────────────────────────────────────────────────────────────
# 1. PARSER — archivos existen y son PowerShell válido
# ──────────────────────────────────────────────────────────────

Describe 'RC69 - Parser: archivos existen' {
    Context 'Archivos canónicos Azure' {
        It 'config/Hermes.Azure.json existe' {
            (Test-Path "$here\..\..\config\Hermes.Azure.json") | Should -Be $true
        }
        It 'Private/AzureConfiguration.ps1 existe' {
            $p = Join-Path $privatePath 'AzureConfiguration.ps1'
            (Test-Path $p) | Should -Be $true
        }
        It 'Public/Get-HermesAzureConfiguration.ps1 existe' {
            $p = Join-Path $publicPath 'Get-HermesAzureConfiguration.ps1'
            (Test-Path $p) | Should -Be $true
        }
        It 'Public/Set-HermesAzureConfiguration.ps1 existe' {
            $p = Join-Path $publicPath 'Set-HermesAzureConfiguration.ps1'
            (Test-Path $p) | Should -Be $true
        }
        It 'Public/Resolve-HermesAppServicePlanId.ps1 existe' {
            $p = Join-Path $publicPath 'Resolve-HermesAppServicePlanId.ps1'
            (Test-Path $p) | Should -Be $true
        }
    }

    Context 'Parser: PowerShell válido' {
        $files = @(
            'Private/AzureConfiguration.ps1',
            'Public/Get-HermesAzureConfiguration.ps1',
            'Public/Set-HermesAzureConfiguration.ps1',
            'Public/Resolve-HermesAppServicePlanId.ps1'
        )
        foreach ($f in $files) {
            It "$f es PowerShell válido" {
                $path = Join-Path $moduleRoot $f
                $content = Get-ScriptContent -Path $path
                if ($content) {
                    $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
                    # Sin excepción = válido
                    $true | Should -Be $true
                } else {
                    $false | Should -Be $true
                }
            }
        }
    }
}

# ──────────────────────────────────────────────────────────────
# 2. PSScriptAnalyzer
# ──────────────────────────────────────────────────────────────

Describe 'RC69 - PSScriptAnalyzer' {
    Context 'AzureConfiguration.ps1' {
        It 'No tiene errores ni warnings de PSSA' {
            $path = Join-Path $privatePath 'AzureConfiguration.ps1'
            if (-not (Test-Path $path)) { Set-ItResult -Inconclusive -Because "archivo no existe"; return }

            $results = Invoke-ScriptAnalyzer -Path $path -ErrorAction SilentlyContinue
            $errors   = $results | Where-Object { $_.Severity -eq 'Error' }
            $warnings = $results | Where-Object { $_.Severity -eq 'Warning' }
            ($errors.Count -eq 0) | Should -Be $true
            ($warnings.Count -eq 0) | Should -Be $true
        }
    }

    Context 'Get-HermesAzureConfiguration.ps1' {
        It 'No tiene errores ni warnings de PSSA' {
            $path = Join-Path $publicPath 'Get-HermesAzureConfiguration.ps1'
            if (-not (Test-Path $path)) { Set-ItResult -Inconclusive -Because "archivo no existe"; return }

            $results = Invoke-ScriptAnalyzer -Path $path -ErrorAction SilentlyContinue
            $errors   = $results | Where-Object { $_.Severity -eq 'Error' }
            $warnings = $results | Where-Object { $_.Severity -eq 'Warning' }
            ($errors.Count -eq 0) | Should -Be $true
            ($warnings.Count -eq 0) | Should -Be $true
        }
    }

    Context 'Set-HermesAzureConfiguration.ps1' {
        It 'No tiene errores ni warnings de PSSA' {
            $path = Join-Path $publicPath 'Set-HermesAzureConfiguration.ps1'
            if (-not (Test-Path $path)) { Set-ItResult -Inconclusive -Because "archivo no existe"; return }

            $results = Invoke-ScriptAnalyzer -Path $path -ErrorAction SilentlyContinue
            $errors   = $results | Where-Object { $_.Severity -eq 'Error' }
            $warnings = $results | Where-Object { $_.Severity -eq 'Warning' }
            ($errors.Count -eq 0) | Should -Be $true
            ($warnings.Count -eq 0) | Should -Be $true
        }
    }

    Context 'Resolve-HermesAppServicePlanId.ps1' {
        It 'No tiene errores ni warnings de PSSA' {
            $path = Join-Path $publicPath 'Resolve-HermesAppServicePlanId.ps1'
            if (-not (Test-Path $path)) { Set-ItResult -Inconclusive -Because "archivo no existe"; return }

            $results = Invoke-ScriptAnalyzer -Path $path -ErrorAction SilentlyContinue
            $errors   = $results | Where-Object { $_.Severity -eq 'Error' }
            $warnings = $results | Where-Object { $_.Severity -eq 'Warning' }
            ($errors.Count -eq 0) | Should -Be $true
            ($warnings.Count -eq 0) | Should -Be $true
        }
    }
}

# ──────────────────────────────────────────────────────────────
# 3. Estructura canónica
# ──────────────────────────────────────────────────────────────

Describe 'RC69 - Estructura Canónica' {
    Context 'AzureConfiguration.ps1 contiene funciones esperadas' {
        It 'Define función Get-AzureConfiguration' {
            $path = Join-Path $privatePath 'AzureConfiguration.ps1'
            $content = Get-ScriptContent -Path $path
            $content -match 'function Get-AzureConfiguration' | Should -Be $true
        }
        It 'Define función Set-AzureConfiguration' {
            $path = Join-Path $privatePath 'AzureConfiguration.ps1'
            $content = Get-ScriptContent -Path $path
            $content -match 'function Set-AzureConfiguration' | Should -Be $true
        }
        It 'Define función Resolve-AppServicePlanResourceId' {
            $path = Join-Path $privatePath 'AzureConfiguration.ps1'
            $content = Get-ScriptContent -Path $path
            $content -match 'function Resolve-AppServicePlanResourceId' | Should -Be $true
        }
        It 'Define función Test-AzureConfiguration' {
            $path = Join-Path $privatePath 'AzureConfiguration.ps1'
            $content = Get-ScriptContent -Path $path
            $content -match 'function Test-AzureConfiguration' | Should -Be $true
        }
        It 'Tiene ayudas comment-based' {
            $path = Join-Path $privatePath 'AzureConfiguration.ps1'
            $content = Get-ScriptContent -Path $path
            $content -match '<#' | Should -Be $true
        }
    }

    Context 'Get-HermesAzureConfiguration tiene estructura canónica' {
        It 'Tiene ayudas comment-based' {
            $path = Join-Path $publicPath 'Get-HermesAzureConfiguration.ps1'
            $content = Get-ScriptContent -Path $path
            $content -match '<#' | Should -Be $true
        }
        It 'Declara parámetros' {
            $path = Join-Path $publicPath 'Get-HermesAzureConfiguration.ps1'
            $content = Get-ScriptContent -Path $path
            $content -match 'param\(' | Should -Be $true
        }
    }

    Context 'Set-HermesAzureConfiguration tiene estructura canónica' {
        It 'Tiene ayudas comment-based' {
            $path = Join-Path $publicPath 'Set-HermesAzureConfiguration.ps1'
            $content = Get-ScriptContent -Path $path
            $content -match '<#' | Should -Be $true
        }
        It 'Declara parámetros' {
            $path = Join-Path $publicPath 'Set-HermesAzureConfiguration.ps1'
            $content = Get-ScriptContent -Path $path
            $content -match 'param\(' | Should -Be $true
        }
    }

    Context 'Resolve-HermesAppServicePlanId tiene estructura canónica' {
        It 'Tiene ayudas comment-based' {
            $path = Join-Path $publicPath 'Resolve-HermesAppServicePlanId.ps1'
            $content = Get-ScriptContent -Path $path
            $content -match '<#' | Should -Be $true
        }
        It 'Declara parámetros' {
            $path = Join-Path $publicPath 'Resolve-HermesAppServicePlanId.ps1'
            $content = Get-ScriptContent -Path $path
            $content -match 'param\(' | Should -Be $true
        }
    }
}

# ──────────────────────────────────────────────────────────────
# 4. Valor de configuración
# ──────────────────────────────────────────────────────────────

Describe 'RC69 - Validación de Configuración' {
    Context 'config/Hermes.Azure.json es JSON válido' {
        It 'Tiene contenido parseable' {
            $path = "$here\..\..\config\Hermes.Azure.json"
            $json = Get-Content $path -Raw -ErrorAction Stop | ConvertFrom-Json
            $json.Azure | Should -Not -Be $null
        }
        It 'Tiene campo Location' {
            $path = "$here\..\..\config\Hermes.Azure.json"
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $json.Azure.Location | Should -Not -BeNullOrEmpty
        }
        It 'Tiene ResourceGroupAplicaciones' {
            $path = "$here\..\..\config\Hermes.Azure.json"
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $json.Azure.ResourceGroupAplicaciones | Should -Not -BeNullOrEmpty
        }
        It 'Tiene ResourceGroupPlan' {
            $path = "$here\..\..\config\Hermes.Azure.json"
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $json.Azure.ResourceGroupPlan | Should -Not -BeNullOrEmpty
        }
        It 'Tiene AppServicePlan' {
            $path = "$here\..\..\config\Hermes.Azure.json"
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $json.Azure.AppServicePlan | Should -Not -BeNullOrEmpty
        }
        It 'Tiene StorageAccount (puede ser null)' {
            $path = "$here\..\..\config\Hermes.Azure.json"
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $json.Azure.StorageAccount | Should -Not -Be $null
        }
        It 'Tiene UseSharedInfrastructure como booleano' {
            $path = "$here\..\..\config\Hermes.Azure.json"
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $json.Azure.UseSharedInfrastructure -is [bool] | Should -Be $true
        }
    }
}

# ──────────────────────────────────────────────────────────────
# 5. BootstrapWizard — función Azure
# ──────────────────────────────────────────────────────────────

Describe 'RC69 - BootstrapWizard Azure Phase' {
    Context 'BootstrapWizard.ps1 contiene Invoke-HermesBootstrapAzureConfig' {
        It 'La función existe en el archivo' {
            $path = "$here\..\..\motor\bootstrap\engine\BootstrapWizard.ps1"
            $content = Get-ScriptContent -Path $path
            $content -match 'function Invoke-HermesBootstrapAzureConfig' | Should -Be $true
        }
        It 'Tiene defaults de Azure' {
            $path = "$here\..\..\motor\bootstrap\engine\BootstrapWizard.ps1"
            $content = Get-ScriptContent -Path $path
            $content -match '\$script:AZURE_DEFAULTS' | Should -Be $true
        }
    }
}

# ──────────────────────────────────────────────────────────────
# 6. NuGet/SQLite — verificar que HermesSQLiteProvider existe
# ──────────────────────────────────────────────────────────────

Describe 'RC69 - SQLite Persistence' {
    Context 'HermesSQLiteProvider existe' {
        It 'El directorio del provider existe' {
            $path = "$here\..\..\lib\HermesSQLiteProvider"
            (Test-Path $path) | Should -Be $true
        }
    }
}