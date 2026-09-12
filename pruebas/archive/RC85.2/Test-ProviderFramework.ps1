<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ProviderFramework.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Tests unitarios para el Provider Framework (IProvider, ProviderBase, ProviderFactory, ProviderRegistry, ProviderResolver).
====================================================================================================
#>

Set-StrictMode -Version Latest

BeforeAll {
    $basePath = Split-Path -Parent $PSCommandPath | Split-Path -Parent | Split-Path -Parent
    . (Join-Path $basePath 'motor\kernel\Contracts\IProvider.ps1')
    . (Join-Path $basePath 'motor\kernel\Providers\ProviderBase.ps1')
    . (Join-Path $basePath 'motor\kernel\Providers\ProviderFactory.ps1')
    . (Join-Path $basePath 'motor\kernel\Providers\ProviderRegistry.ps1')
    . (Join-Path $basePath 'motor\kernel\Providers\ProviderResolver.ps1')
}

Describe 'Provider Framework Tests' {
    Context 'ProviderFactory' {
        It 'Should create provider from ProviderBase' {
            $provider = New-HermesEnterpriseProvider -ProviderName 'TestProvider' -ProviderType 'infra'
            $provider | Should -Not -BeNullOrEmpty
            $provider.Name | Should -Be 'TestProvider'
            $provider.ProviderType | Should -Be 'infra'
        }

        It 'Should fail provider creation without name' {
            { New-HermesEnterpriseProvider -ProviderName '' -ProviderType 'infra' } | Should -Throw
        }

        It 'Should fail provider creation without type' {
            { New-HermesEnterpriseProvider -ProviderName 'TestProvider' -ProviderType '' } | Should -Throw
        }
    }

    Context 'ProviderRegistry' {
        It 'Should create empty provider registry' {
            $registry = New-HermesEnterpriseProviderRegistry
            $registry | Should -Not -BeNullOrEmpty
            $registry.Providers.Count | Should -Be 0
        }

        It 'Should register provider successfully' {
            $registry = New-HermesEnterpriseProviderRegistry
            $provider = New-HermesEnterpriseProvider -ProviderName 'TestProvider' -ProviderType 'infra'
            $result = Register-HermesEnterpriseProvider -ProviderRegistry $registry -Provider $provider
            $result | Should -BeTrue
        }
    }

    Context 'ProviderResolver' {
        It 'Should create provider execution context' {
            $context = New-HermesEnterpriseProviderContext
            $context | Should -Not -BeNullOrEmpty
        }
    }
}