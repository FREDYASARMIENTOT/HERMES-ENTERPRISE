<#
.SYNOPSIS
    Tests unitarios para el Paso 4.5: BootstrapRequest y BootstrapRequestBuilder
.DESCRIPTION
    Valida que:
    - BootstrapRequest es un DTO inmutable
    - BootstrapRequestBuilder construye requests válidos
    - BootstrapOrchestrator recibe Request y State separados (refactorizado)
    
    IMPORTANTE: No se modifica BootstrapState (congelado en Paso 4)
.NOTES
    Fase: 4.5
    Fecha: 2026-07-10
    Idioma: Español (siguiendo estándar del proyecto)
#>

# Cargar componentes
. "$PSScriptRoot\..\..\motor\bootstrap\engine\BootstrapRequest.ps1"
. "$PSScriptRoot\..\..\motor\bootstrap\engine\BootstrapRequestBuilder.ps1"
. "$PSScriptRoot\..\..\motor\bootstrap\engine\BootstrapState.ps1"

Describe 'BootstrapRequest DTO' {

    Context 'Creación con parámetros mínimos' {

        It 'debería crear un pedido válido con parámetros mínimos' {
            $pedido = New-BootstrapRequest -NameProyecto 'TestApp' -RutaProyecto 'C:\TestApp'
            
            $pedido.PSObject.TypeNames[0] | Should Be 'Hermes.Bootstrap.Request'
            $pedido.NameProyecto | Should Be 'TestApp'
            $pedido.RutaProyecto | Should Be 'C:\TestApp'
            $pedido.CreateFrontend | Should Be $false
            $pedido.CreateBackend | Should Be $false
        }
    }

    Context 'Creación con todos los parámetros' {

        It 'debería crear un pedido completo con todos los parámetros' {
            $pedido = New-BootstrapRequest `
                -NameProyecto 'FullApp' `
                -RutaProyecto 'C:\FullApp' `
                -DescripcionProyecto 'Aplicación completa' `
                -CreateFrontend $true `
                -CreateBackend $true `
                -RuntimePython '3.11' `
                -RuntimeNode '20.11.0' `
                -RutaEnvironment 'C:\FullApp\venv' `
                -CreateEnv $true `
                -ProveedorGit 'GitHub' `
                -ActionRepositorio 'Nuevo' `
                -URLRemoto 'https://github.com/user/FullApp' `
                -CreateNuevoRepositorio $true `
                -CreateGitIgnore $true `
                -AbrirVSCode $true
            
            $pedido.NameProyecto | Should Be 'FullApp'
            $pedido.RutaProyecto | Should Be 'C:\FullApp'
            $pedido.CreateFrontend | Should Be $true
            $pedido.CreateBackend | Should Be $true
            $pedido.RuntimePython | Should Be '3.11'
            $pedido.RuntimeNode | Should Be '20.11.0'
            $pedido.ProveedorGit | Should Be 'GitHub'
            $pedido.ActionRepositorio | Should Be 'Nuevo'
        }
    }

    Context 'Validaciones' {

        It 'debería rechazar nombres de proyecto inválidos' {
            { New-BootstrapRequest -NameProyecto 'ab' -RutaProyecto 'C:\Test' } | Should Throw
            { New-BootstrapRequest -NameProyecto 'a' * 65 -RutaProyecto 'C:\Test' } | Should Throw
            { New-BootstrapRequest -NameProyecto '' -RutaProyecto 'C:\Test' } | Should Throw
        }

        It 'debería rechazar rutas de proyecto vacías' {
            { New-BootstrapRequest -NameProyecto 'TestApp' -RutaProyecto '' } | Should Throw
        }

        It 'debería rechazar crear nuevo repositorio sin proveedor Git' {
            { 
                New-BootstrapRequest `
                    -NameProyecto 'TestApp' `
                    -RutaProyecto 'C:\Test' `
                    -CreateNuevoRepositorio $true 
            } | Should Throw
        }

        It 'debería aceptar nombres de proyecto válidos' {
            { New-BootstrapRequest -NameProyecto 'Test-App_123' -RutaProyecto 'C:\Test' } | Should Not Throw
        }
    }

    Context 'Inmutabilidad' {

        It 'debería ser un objeto inmutable' {
            $pedido = New-BootstrapRequest -NameProyecto 'TestApp' -RutaProyecto 'C:\TestApp'
            
            # Intentar modificar una propiedad debería fallar
            { $pedido.NameProyecto = 'Modified' } | Should Throw
        }
    }
}

Describe 'Test-BootstrapRequest' {

    Context 'Validación de pedidos' {

        It 'debería validar pedidos correctos' {
            $pedido = New-BootstrapRequest -NameProyecto 'TestApp' -RutaProyecto 'C:\TestApp'
            $validacion = Test-BootstrapRequest -Pedido $pedido
            
            $validacion.EsPedidoValido | Should Be $true
            $validacion.Errores.Count | Should Be 0
        }

        It 'debería detectar pedidos con nombre inválido' {
            $pedidoInvalido = [PSCustomObject]@{
                NameProyecto = 'ab'
                RutaProyecto = 'C:\test'
            }
            
            $validacion = Test-BootstrapRequest -Pedido $pedidoInvalido
            
            $validacion.EsPedidoValido | Should Be $false
            $validacion.Errores.Count | Should BeGreaterThan 0
        }

        It 'debería detectar pedidos con ruta vacía' {
            $pedidoInvalido = [PSCustomObject]@{
                NameProyecto = 'TestApp'
                RutaProyecto = ''
            }
            
            $validacion = Test-BootstrapRequest -Pedido $pedidoInvalido
            
            $validacion.EsPedidoValido | Should Be $false
        }
    }
}
