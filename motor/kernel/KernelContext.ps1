<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : KernelContext.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Construye el contexto compartido del Kernel Enterprise. El contexto concentra rutas,
    metadatos de ejecución y valores base que serán utilizados por Bootstrap, Runtime,
    configuración, logging, eventos y registro de módulos.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseKernelContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RutaRaizRepositorio,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$NombreEntorno = "Desarrollo",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$VersionKernel = "0.3.0"
    )

    # Normalizar la ruta raíz permite que todos los componentes trabajen con rutas absolutas.
    $RutaRaizNormalizada = [System.IO.Path]::GetFullPath($RutaRaizRepositorio)

    # El contexto es un objeto ordenado para que serializaciones y diagnósticos sean estables.
    $ContextoKernel = [ordered]@{
        NombreProyecto       = "HERMES-ENTERPRISE"
        VersionKernel        = $VersionKernel
        NombreEntorno        = $NombreEntorno
        RutaRaizRepositorio  = $RutaRaizNormalizada
        RutaMotor            = Join-Path $RutaRaizNormalizada "motor"
        RutaConfiguracion    = Join-Path $RutaRaizNormalizada "configuracion"
        RutaLogs             = Join-Path $RutaRaizNormalizada "logs"
        FechaCreacion        = (Get-Date).ToString("o")
        IdentificadorContexto = [guid]::NewGuid().ToString()
    }

    return [pscustomobject]$ContextoKernel
}
