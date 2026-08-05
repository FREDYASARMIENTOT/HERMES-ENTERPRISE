<#
.SYNOPSIS
    Establece un valor de configuración de Hermes.
.DESCRIPTION
    Configura parámetros del sistema Hermes en el archivo de configuración JSON.
    Función canónica (RC63) — PRIORITY COMMAND.
.PARAMETER Key
    Nombre de la clave de configuración.
.PARAMETER Value
    Valor a establecer. Acepta strings, números y booleanos.
.PARAMETER Scope
    'Global' (permanente) o 'Session' (solo para la sesión actual).
.PARAMETER ConfigPath
    Ruta al archivo de configuración. Por defecto: Hermes.config.json en el directorio actual.
.EXAMPLE
    Set-HermesConfiguration -Key "theme.mode" -Value "dark"
.EXAMPLE
    Set-HermesConfiguration -Key "autoSave" -Value $true -Scope Global
#>
function Set-HermesConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Key,

        [Parameter(Mandatory = $true, Position = 1)]
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Global', 'Session')]
        [string]$Scope = 'Global',

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath
    )

    if ($PSCmdlet.ShouldProcess($Key, "Set Hermes configuration")) {
        # Session scope — store in module-scoped variable
        if ($Scope -eq 'Session') {
            if (-not $script:HermesSessionConfig) {
                $script:HermesSessionConfig = @{}
            }
            $script:HermesSessionConfig[$Key] = $Value
            Write-Host "[OK] Configuration '$Key' set to '$Value' (Session)" -ForegroundColor Green
            return
        }

        # Global scope — write to config file
        if (-not $ConfigPath) {
            $ConfigPath = Join-Path (Get-Location).Path 'Hermes.config.json'
        }

        # Load or create config
        if (Test-Path $ConfigPath) {
            $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            if ($config -isnot [PSCustomObject]) { $config = @{} }
        } else {
            $config = @{}
        }

        # Set nested key (e.g., "theme.mode" -> $config.theme.mode)
        $keys = $Key -split '\.'
        $current = $config
        for ($i = 0; $i -lt $keys.Count - 1; $i++) {
            if (-not $current.$($keys[$i])) {
                $current | Add-Member -MemberType NoteProperty -Name $keys[$i] -Value @{}
            }
            $current = $current.$($keys[$i])
        }
        $current | Add-Member -MemberType NoteProperty -Name $keys[-1] -Value $Value -Force

        # Save
        $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
        Write-Host "[OK] Configuration '$Key' set to '$Value' (Global)" -ForegroundColor Green
    }
}