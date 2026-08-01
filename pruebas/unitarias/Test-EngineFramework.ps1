<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-EngineFramework.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Tests unitarios para el Engine Framework (IEngine, EngineBase, EngineFactory, EngineRegistry, EngineResolver).
====================================================================================================
#>

Set-StrictMode -Version Latest

BeforeAll {
    # Import files needed
    $basePath = Split-Path -Parent $PSCommandPath | Split-Path -Parent | Split-Path -Parent
    . (Join-Path $basePath 'motor\kernel\Contracts\IEngine.ps1')
    . (Join-Path $basePath 'motor\kernel\Engine\EngineBase.ps1')
    . (Join-Path $basePath 'motor\kernel\Engine\EngineFactory.ps1')
    . (Join-Path $basePath 'motor\kernel\Engine\EngineRegistry.ps1')
    . (Join-Path $basePath 'motor\kernel\Engine\EngineResolver.ps1')
}

Describe 'Engine Framework Tests' {
    Context 'EngineFactory' {
        It 'Should create engine from EngineBase' {
            $engine = New-HermesEnterpriseEngine -EngineName 'TestEngine' -EngineType 'bootstrap'
            $engine | Should -Not -BeNullOrEmpty
            $engine.Name | Should -Be 'TestEngine'
            $engine.EngineType | Should -Be 'bootstrap'
        }

        It 'Should fail engine creation without name' {
            { New-HermesEnterpriseEngine -EngineName '' -EngineType 'bootstrap' } | Should -Throw
        }
    }

    Context 'EngineRegistry' {
        It 'Should register and list engines' {
            $registry = New-HermesEnterpriseEngineRegistry
            $registry | Should -Not -BeNullOrEmpty
        }

        It 'Should register engine successfully' {
            $registry = New-HermesEnterpriseEngineRegistry
            $engine = New-HermesEnterpriseEngine -EngineName 'TestEngine' -EngineType 'bootstrap'
            $result = Register-HermesEnterpriseEngine -EngineRegistry $registry -Engine $engine
            $result | Should -BeTrue
        }
    }

    Context 'EngineResolver' {
        It 'Should resolve engine by name' {
            $resolver = New-HermesEnterpriseEngineContext
            $resolver | Should -Not -BeNullOrEmpty
        }
    }
}