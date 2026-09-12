<#
.SYNOPSIS
    Tests unitarios para New-BootstrapRequestFromProjectArchitecture (Sprint 5.5)

.DESCRIPTION
    Valida que:
    - La función existe y tiene AST válido
    - Recibe un objeto ProjectArchitecture
    - Devuelve un BootstrapRequest válido
    - No ejecuta comandos del sistema operativo
    - No modifica componentes congelados
    - Scope Lock respetado

.NOTES
    Sprint: 5.5
    Fecha: 2026-07-10
#>

# Cargar dependencias
. "$PSScriptRoot\..\motor\bootstrap\request\BootstrapRequest.ps1"
. "$PSScriptRoot\..\motor\bootstrap\request\New-BootstrapRequestFromProjectArchitecture.ps1"

# ─── Helper: crear ProjectArchitecture mock ───
function New-MockProjectArchitecture {
    param(
        [string]$NombreProyecto = 'TestProject',
        [string]$Descripcion = 'Test description',
        [bool]$RequiereFrontend = $false,
        [bool]$RequiereBackend = $false,
        [string]$FrameworkFrontend = '',
        [string]$FrameworkBackend = '',
        [bool]$RequiereGitHub = $false
    )

    $architecture = [PSCustomObject]@{
        PSTypeName = 'Hermes.Project.Architecture'
        NombreProyecto = $NombreProyecto
        Descripcion = $Descripcion
        TipoProyecto = 'WebApp'
        LenguajePrincipal = 'PowerShell'
        FrameworkFrontend = $FrameworkFrontend
        FrameworkBackend = $FrameworkBackend
        RequiereFrontend = $RequiereFrontend
        RequiereBackend = $RequiereBackend
        RequiereAzure = $false
        RequiereGitHub = $RequiereGitHub
        CapacidadesSeleccionadas = @()
    }
    return $architecture
}

Describe 'New-BootstrapRequestFromProjectArchitecture' {

    Context 'Validación del AST' {

        It 'debería tener AST sintácticamente válido' {
            $scriptPath = Join-Path $PSScriptRoot '..\motor\bootstrap\request\New-BootstrapRequestFromProjectArchitecture.ps1'
            $scriptPath = (Resolve-Path $scriptPath).Path
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $scriptPath,
                [ref]$null,
                [ref]$null
            )
            $ast | Should Not BeNullOrEmpty
        }

        It 'debería contener la función pública New-BootstrapRequestFromProjectArchitecture' {
            $functionExists = Get-Command -Name 'New-BootstrapRequestFromProjectArchitecture' -ErrorAction SilentlyContinue
            $functionExists | Should Not BeNullOrEmpty
            $functionExists.CommandType | Should Be 'Function'
        }
    }

    Context 'Entrada: ProjectArchitecture' {

        It 'debería aceptar un objeto ProjectArchitecture válido' {
            $architecture = New-MockProjectArchitecture -NombreProyecto 'MyProject'
            $request = New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $architecture
            $request | Should Not BeNullOrEmpty
        }

        It 'debería rechazar objetos que no sean ProjectArchitecture' {
            $invalidObject = [PSCustomObject]@{
                PSTypeName = 'Invalid.Type'
                NombreProyecto = 'Test'
            }
            {
                New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $invalidObject
            } | Should Throw
        }

        It 'debería rechazar objetos nulos' {
            {
                New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $null
            } | Should Throw
        }
    }

    Context 'Salida: BootstrapRequest' {

        It 'debería devolver un objeto de tipo Hermes.Bootstrap.Request' {
            $architecture = New-MockProjectArchitecture -NombreProyecto 'TestApp'
            $request = New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $architecture
            $request.PSObject.TypeNames[0] | Should Be 'Hermes.Bootstrap.Request'
        }

        It 'debería mapear NombreProyecto correctamente' {
            $architecture = New-MockProjectArchitecture -NombreProyecto 'MappTest'
            $request = New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $architecture
            $request.NombreProyecto | Should Be 'MappTest'
        }

        It 'debería mapear Descripcion a DescripcionProyecto' {
            $architecture = New-MockProjectArchitecture -NombreProyecto 'MapTest' -Descripcion 'Test description'
            $request = New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $architecture
            $request.DescripcionProyecto | Should Be 'Test description'
        }

        It 'debería generar RutaProyecto automáticamente' {
            $architecture = New-MockProjectArchitecture -NombreProyecto 'AutoPath'
            $request = New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $architecture
            $request.RutaProyecto | Should Not BeNullOrEmpty
            $request.RutaProyecto | Should Match 'AutoPath$'
        }

        It 'debería mapear RequiereFrontend a CrearFrontend' {
            $architecture = New-MockProjectArchitecture -NombreProyecto 'FrontTest' -RequiereFrontend $true
            $request = New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $architecture
            $request.CrearFrontend | Should Be $true
        }

        It 'debería mapear RequiereBackend a CrearBackend' {
            $architecture = New-MockProjectArchitecture -NombreProyecto 'BackTest' -RequiereBackend $true
            $request = New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $architecture
            $request.CrearBackend | Should Be $true
        }

        It 'debería setear RuntimeNode cuando requiere Frontend' {
            $architecture = New-MockProjectArchitecture -NombreProyecto 'RuntimeTest' -RequiereFrontend $true
            $request = New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $architecture
            $request.RuntimeNode | Should Be '20.11.0'
        }

        It 'debería setear RuntimePython cuando requiere Backend' {
            $architecture = New-MockProjectArchitecture -NombreProyecto 'PyTest' -RequiereBackend $true
            $request = New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $architecture
            $request.RuntimePython | Should Be '3.11'
        }

        It 'debería mapear RequiereGitHub a ProveedorGit GitHub' {
            $architecture = New-MockProjectArchitecture -NombreProyecto 'GitTest' -RequiereGitHub $true
            $request = New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $architecture
            $request.ProveedorGit | Should Be 'GitHub'
        }

        It 'debería setear ProveedorGit a None cuando no requiere GitHub' {
            $architecture = New-MockProjectArchitecture -NombreProyecto 'NoGit' -RequiereGitHub $false
            $request = New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $architecture
            $request.ProveedorGit | Should Be 'None'
        }
    }

    Context 'Inmutabilidad y efectos secundarios' {

        It 'no debería invocar comandos del sistema operativo' {
            $scriptPath = Join-Path $PSScriptRoot '..\motor\bootstrap\request\New-BootstrapRequestFromProjectArchitecture.ps1'
            $scriptPath = (Resolve-Path $scriptPath).Path
            $content = Get-Content $scriptPath -Raw

            $forbiddenCmdlets = @(
                'Invoke-Expression',
                'Start-Process',
                'New-Item',
                'Set-Content',
                'Out-File',
                'Remove-Item',
                'Copy-Item',
                'Move-Item',
                'Install-Module',
                'git ',
                'az ',
                'docker '
            )

            foreach ($cmdlet in $forbiddenCommandslets) {
                $content.Contains($cmdlet) | Should Be $false -Because "no debe contener: $cmdlet"
            }
        }

        It 'no debería crear ni modificar carpetas ni archivos' {
            $scriptPath = Join-Path $PSScriptRoot '..\motor\bootstrap\request\New-BootstrapRequestFromProjectArchitecture.ps1'
            $scriptPath = (Resolve-Path $scriptPath).Path
            $content = Get-Content $scriptPath -Raw

            $content.Contains('New-Item') | Should Be $false
            $content.Contains('mkdir') | Should Be $false
            $content.Contains('Set-Content') | Should Be $false
            $content.Contains('Out-File') | Should Be $false
        }

        It 'no debería modificar el ProjectArchitecture original' {
            $architecture = New-MockProjectArchitecture -NombreProyecto 'Immut'
            $originalName = $architecture.NombreProyecto
            $request = New-BootstrapRequestFromProjectArchitecture -ProjectArchitecture $architecture
            $architecture.NombreProyecto | Should Be $originalName
        }
    }

    Context 'Scope Lock' {

        It 'no debería estar referenciando Sprint 6 o posterior' {
            $scriptPath = Join-Path $PSScriptRoot '..\motor\bootstrap\request\New-BootstrapRequestFromProjectArchitecture.ps1'
            $scriptPath = (Resolve-Path $scriptPath).Path
            $content = Get-Content $scriptPath -Raw

            $content.Contains('Sprint 6') | Should Be $false
            $content.Contains('Sprint 7') | Should Be $false
        }

        It 'no debería referenciar tecnologías prohibidas' {
            $scriptPath = Join-Path $PSScriptRoot '..\motor\bootstrap\request\New-BootstrapRequestFromProjectArchitecture.ps1'
            $scriptPath = (Resolve-Path $scriptPath).Path
            $content = Get-Content $scriptPath -Raw

            $forbidden = @('Data Factory', 'Storage', 'App Service', 'GitHub Actions', 'Docker', 'Terraform')
            foreach ($tech in $forbidden) {
                $content.Contains($tech) | Should Be $false -Because "no debe mencionar: $tech"
            }
        }
    }
}
