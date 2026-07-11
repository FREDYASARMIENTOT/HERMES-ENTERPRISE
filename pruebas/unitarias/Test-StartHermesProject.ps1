<#
.SYNOPSIS
    Test unitario de Start-HermesProject (Pester 3.x).
.DESCRIPTION
    Valida:
    - Parametros obligatorios.
    - Flujo no interactivo (NonInteractive).
    - Construye correctamente ProjectArchitecture.
    - Invoca New-BootstrapRequestFromProjectArchitecture.
    - No modifica componentes congelados.
.NOTES
    Sprint 5.6 | HERMES-ENTERPRISE | 2026-07-10
#>

Set-StrictMode -Version Latest

# Dot-source archivos necesarios (ruta absoluta)
$rootDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

. "$rootDir\motor\bootstrap\engine\BootstrapState.ps1"
. "$rootDir\motor\bootstrap\engine\New-BootstrapStateFromRequest.ps1"
. "$rootDir\motor\bootstrap\engine\BootstrapOrchestrator.ps1"
. "$rootDir\motor\bootstrap\request\BootstrapRequest.ps1"
. "$rootDir\motor\bootstrap\request\New-BootstrapRequestFromProjectArchitecture.ps1"
. "$rootDir\motor\bootstrap\Start-HermesProject.ps1"

Describe 'Start-HermesProject - Parametros Obligatorios' {

    It 'Debe fallar si falta NombreProyecto en modo NonInteractive' {
        $threw = $false
        try {
            Start-HermesProject -TipoProyecto 'API' -LenguajePrincipal 'PowerShell' -NonInteractive -ErrorAction Stop
        } catch {
            $threw = $_.Exception.Message -match 'NombreProyecto es obligatorio'
        }
        $threw | Should Be $true
    }

    It 'Debe fallar si falta TipoProyecto en modo NonInteractive' {
        $threw = $false
        try {
            Start-HermesProject -NombreProyecto 'MiApp' -LenguajePrincipal 'PowerShell' -NonInteractive -ErrorAction Stop
        } catch {
            $threw = $_.Exception.Message -match 'TipoProyecto es obligatorio'
        }
        $threw | Should Be $true
    }

    It 'Debe fallar si falta LenguajePrincipal en modo NonInteractive' {
        $threw = $false
        try {
            Start-HermesProject -NombreProyecto 'MiApp' -TipoProyecto 'API' -NonInteractive -ErrorAction Stop
        } catch {
            $threw = $_.Exception.Message -match 'LenguajePrincipal es obligatorio'
        }
        $threw | Should Be $true
    }

    It 'Debe fallar si NombreProyecto tiene longitud invalida' {
        $threw = $false
        try {
            Start-HermesProject -NombreProyecto 'ab' -TipoProyecto 'API' -LenguajePrincipal 'PowerShell' -NonInteractive -ErrorAction Stop
        } catch {
            $threw = $_.Exception.Message -match '3-64 caracteres'
        }
        $threw | Should Be $true
    }

    It 'Debe fallar si NombreProyecto tiene caracteres invalidos' {
        $threw = $false
        try {
            Start-HermesProject -NombreProyecto 'Mi App' -TipoProyecto 'API' -LenguajePrincipal 'PowerShell' -NonInteractive -ErrorAction Stop
        } catch {
            $threw = $_.Exception.Message -match 'solo acepta letras'
        }
        $threw | Should Be $true
    }
}

Describe 'Start-HermesProject - Flujo No Interactivo' {

    It 'Debe construir ProjectArchitecture con parametros minimos' {
        $resultado = Start-HermesProject `
            -NombreProyecto 'MiApp' `
            -DescripcionProyecto 'Aplicacion de prueba' `
            -TipoProyecto 'API' `
            -LenguajePrincipal 'PowerShell' `
            -NonInteractive

        $resultado.ProyectoArquitectura.NombreProyecto          | Should Be 'MiApp'
        $resultado.ProyectoArquitectura.Descripcion             | Should Be 'Aplicacion de prueba'
        $resultado.ProyectoArquitectura.TipoProyecto            | Should Be 'API'
        $resultado.ProyectoArquitectura.LenguajePrincipal       | Should Be 'PowerShell'
        $resultado.ProyectoArquitectura.RequiereFrontend        | Should Be $false
        $resultado.ProyectoArquitectura.RequiereBackend         | Should Be $false
    }

    It 'Debe construir ProjectArchitecture con frontend y backend' {
        $resultado = Start-HermesProject `
            -NombreProyecto 'FullApp' `
            -DescripcionProyecto 'Aplicacion completa' `
            -TipoProyecto 'FullStack' `
            -LenguajePrincipal 'TypeScript' `
            -FrameworkFrontend 'React' `
            -FrameworkBackend 'Node.js' `
            -RequiereFrontend $true `
            -RequiereBackend $true `
            -NonInteractive

        $resultado.ProyectoArquitectura.NombreProyecto      | Should Be 'FullApp'
        $resultado.ProyectoArquitectura.TipoProyecto        | Should Be 'FullStack'
        $resultado.ProyectoArquitectura.LenguajePrincipal   | Should Be 'TypeScript'
        $resultado.ProyectoArquitectura.FrameworkFrontend   | Should Be 'React'
        $resultado.ProyectoArquitectura.FrameworkBackend    | Should Be 'Node.js'
        $resultado.ProyectoArquitectura.RequiereFrontend    | Should Be $true
        $resultado.ProyectoArquitectura.RequiereBackend     | Should Be $true
    }

    It 'Debe invocar New-BootstrapRequestFromProjectArchitecture' {
        $resultado = Start-HermesProject `
            -NombreProyecto 'TestBootstrap' `
            -DescripcionProyecto 'Test' `
            -TipoProyecto 'API' `
            -LenguajePrincipal 'PowerShell' `
            -NonInteractive

        $resultado.SolicitudBootstrap                       | Should Not Be $null
        $resultado.SolicitudBootstrap.PSObject.TypeNames[0] | Should Be 'Hermes.Bootstrap.Request'
        $resultado.SolicitudBootstrap.NombreProyecto        | Should Be 'TestBootstrap'
    }

    It 'Debe retornar estructura ResultadoEntrada correcta' {
        $resultado = Start-HermesProject `
            -NombreProyecto 'TestEstructura' `
            -DescripcionProyecto 'Test' `
            -TipoProyecto 'API' `
            -LenguajePrincipal 'PowerShell' `
            -NonInteractive

        $resultado.PSObject.TypeNames[0]      | Should Be 'Hermes.Project.ResultadoEntrada'
        $resultado.ProyectoArquitectura       | Should Not Be $null
        $resultado.SolicitudBootstrap         | Should Not Be $null
    }
}

Describe 'Start-HermesProject - Validaciones Adicionales' {

    It 'Debe fallar si RequiereFrontend es true pero no se indica FrameworkFrontend' {
        $threw = $false
        try {
            Start-HermesProject `
                -NombreProyecto 'TestValidacion' `
                -DescripcionProyecto 'Test' `
                -TipoProyecto 'FullStack' `
                -LenguajePrincipal 'TypeScript' `
                -RequiereFrontend $true `
                -RequiereBackend $false `
                -NonInteractive -ErrorAction Stop
        } catch {
            $threw = $_.Exception.Message -match 'FrameworkFrontend'
        }
        $threw | Should Be $true
    }

    It 'Debe fallar si RequiereBackend es true pero no se indica FrameworkBackend' {
        $threw = $false
        try {
            Start-HermesProject `
                -NombreProyecto 'TestValidacion2' `
                -DescripcionProyecto 'Test' `
                -TipoProyecto 'FullStack' `
                -LenguajePrincipal 'TypeScript' `
                -RequiereFrontend $false `
                -RequiereBackend $true `
                -NonInteractive -ErrorAction Stop
        } catch {
            $threw = $_.Exception.Message -match 'FrameworkBackend'
        }
        $threw | Should Be $true
    }

    It 'Debe aceptar todos los tipos de proyecto validos' {
        $tiposValidos = @('API','Web','FullStack','IA','Automatizacion','Otro')
        foreach ($tipo in $tiposValidos) {
            $resultado = Start-HermesProject `
                -NombreProyecto 'TestTipo' `
                -DescripcionProyecto 'Test' `
                -TipoProyecto $tipo `
                -LenguajePrincipal 'PowerShell' `
                -NonInteractive

            $resultado.ProyectoArquitectura.TipoProyecto | Should Be $tipo
        }
    }
}

Describe 'Start-HermesProject - No Modifica Componentes Congelados' {

    It 'No debe modificar BootstrapState.ps1' {
        $bootstrapStatePath = "$rootDir\motor\bootstrap\engine\BootstrapState.ps1"
        $antes = Get-FileHash $bootstrapStatePath -Algorithm SHA256

        Start-HermesProject `
            -NombreProyecto 'TestCongelado' `
            -DescripcionProyecto 'Test' `
            -TipoProyecto 'API' `
            -LenguajePrincipal 'PowerShell' `
            -NonInteractive | Out-Null

        $despues = Get-FileHash $bootstrapStatePath -Algorithm SHA256
        $antes.Hash | Should Be $despues.Hash
    }

    It 'No debe modificar BootstrapOrchestrator.ps1' {
        $bootstrapOrchPath = "$rootDir\motor\bootstrap\engine\BootstrapOrchestrator.ps1"
        $antes = Get-FileHash $bootstrapOrchPath -Algorithm SHA256

        Start-HermesProject `
            -NombreProyecto 'TestCongelado2' `
            -DescripcionProyecto 'Test' `
            -TipoProyecto 'API' `
            -LenguajePrincipal 'PowerShell' `
            -NonInteractive | Out-Null

        $despues = Get-FileHash $bootstrapOrchPath -Algorithm SHA256
        $antes.Hash | Should Be $despues.Hash
    }
}
