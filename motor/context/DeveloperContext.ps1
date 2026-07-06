<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : DeveloperContext.ps1
Propósito:
    Objeto raíz que representa el contexto completo del desarrollador. Contiene la Session,
    no al revés. No almacena secretos, solo referencias.
====================================================================================================
#>
Set-StrictMode -Version Latest

function New-HermesEnterpriseDeveloperContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [psobject]$Workspace = $null,

        [Parameter(Mandatory = $false)]
        [psobject]$Proyecto = $null,

        [Parameter(Mandatory = $false)]
        [psobject]$Git = $null,

        [Parameter(Mandatory = $false)]
        [psobject]$GitHub = $null,

        [Parameter(Mandatory = $false)]
        [psobject]$Provider = $null,

        [Parameter(Mandatory = $false)]
        [string]$Modelo = "ur-hermes-mini",

        [Parameter(Mandatory = $false)]
        [string[]]$Plugins = @(),

        [Parameter(Mandatory = $false)]
        [psobject]$Session = $null,

        [Parameter(Mandatory = $false)]
        [hashtable]$Preferencias = @{},

        [Parameter(Mandatory = $false)]
        [psobject]$VariablesEntorno = $null,

        [Parameter(Mandatory = $false)]
        [psobject]$EstadoKernel = $null
    )

    return [pscustomobject][ordered]@{
        Workspace        = $Workspace
        Proyecto         = $Proyecto
        Git              = $Git
        GitHub           = $GitHub
        Provider         = $Provider
        Modelo           = $Modelo
        Plugins          = $Plugins
        Session          = $Session
        Preferencias     = $Preferencias
        VariablesEntorno = $VariablesEntorno
        EstadoKernel     = $EstadoKernel
    }
}
