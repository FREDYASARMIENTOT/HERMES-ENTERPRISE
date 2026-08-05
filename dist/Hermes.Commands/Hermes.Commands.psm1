<#
====================================================================================================
Hermes.Commands.psm1 — Módulo principal de comandos Hermes Enterprise
====================================================================================================
#>

Set-StrictMode -Version Latest

# ──────────────────────────────────────────────────────────────
# 1. Dot-source all Private modules (internal helpers)
# ──────────────────────────────────────────────────────────────
$moduleRoot = $PSScriptRoot
$privatePath = Join-Path $moduleRoot 'Private'
if (Test-Path $privatePath) {
    Get-ChildItem -Path $privatePath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# ──────────────────────────────────────────────────────────────
# 2. Dot-source ProjectManager (internal)
# ──────────────────────────────────────────────────────────────
$pmPath = Join-Path $moduleRoot 'ProjectManager'
if (Test-Path $pmPath) {
    Get-ChildItem -Path $pmPath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# ──────────────────────────────────────────────────────────────
# 3. Dot-source Providers (internal wrappers)
# ──────────────────────────────────────────────────────────────
$providersPath = Join-Path $moduleRoot 'Providers'
if (Test-Path $providersPath) {
    Get-ChildItem -Path $providersPath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# ──────────────────────────────────────────────────────────────
# 4. Dot-source all Public command files (exported functions)
# ──────────────────────────────────────────────────────────────
$publicPath = Join-Path $moduleRoot 'Public'
if (Test-Path $publicPath) {
    Get-ChildItem -Path $publicPath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# ──────────────────────────────────────────────────────────────
# 5. Export all public functions defined in Public/*.ps1
#    (Automatic — no manual list needed)
# ──────────────────────────────────────────────────────────────
$exportedFunctions = @()
$publicPs1Path = Join-Path $moduleRoot 'Public'
if (Test-Path $publicPs1Path) {
    Get-ChildItem -Path $publicPs1Path -Filter '*.ps1' | ForEach-Object {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null)
        $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        foreach ($func in $functions) {
            $exportedFunctions += $func.Name
        }
    }
}

Export-ModuleMember -Function $exportedFunctions

Write-Verbose "[Hermes.Commands] Module loaded with $($exportedFunctions.Count) exported commands."
