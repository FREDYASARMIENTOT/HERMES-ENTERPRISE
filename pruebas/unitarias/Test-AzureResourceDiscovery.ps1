$ErrorActionPreference = 'Stop'
$RepoRoot = 'D:\HERMES-ENTERPRISE'
Write-Host "`n[PRUEBA UNITARIA] Sprint 6.3 - AzureResourceDiscovery" -ForegroundColor Cyan
Write-Host ("=" * 72)

$p = 0; $f = 0
function Pass($n){ $script:p++; Write-Host "[PASS] $n" -ForegroundColor Green }
function Fail($n,$m){ $script:f++; Write-Host "[FAIL] $n :: $m" -ForegroundColor Red }

try {
    # Dot-source del componente
    . "$RepoRoot\motor\providers\azure\AzureResourceDiscovery.ps1"
    
    # T1: Función pública existe
    if (Get-Command Get-HermesAzureResourceDiscovery -ErrorAction SilentlyContinue) {
        Pass "Get-HermesAzureResourceDiscovery existe"
    } else {
        Fail "función pública" "no encontrada"
    }
    
    # T2: AzureContext obligatorio
    $cmd = Get-Command Get-HermesAzureResourceDiscovery
    $param = $cmd.Parameters['AzureContext']
    if ($param -and $param.ParameterSets['__AllParameterSets'].IsMandatory) {
        Pass "AzureContext es obligatorio"
    } else {
        Fail "parámetro" "AzureContext no es obligatorio"
    }
    
    # T3: AzureContext no autenticado lanza error
    $contextoInvalido = [PSCustomObject]@{
        EstaAutenticado = $false
        Usuario = "test@test.com"
        IdentificadorInquilino = "tenant-123"
        IdentificadorSuscripcion = "sub-123"
    }
    
    try {
        $null = Get-HermesAzureResourceDiscovery -AzureContext $contextoInvalido
        Fail "validación contexto" "debería lanzar error con EstaAutenticado=false"
    } catch {
        if ($_.Exception.Message -match "no esta autenticado") {
            Pass "rechaza AzureContext no autenticado"
        } else {
            Fail "validación contexto" "mensaje incorrecto: $($_.Exception.Message)"
        }
    }
    
    # T4: AzureContext sin campos requeridos lanza error
    $contextoIncompleto = [PSCustomObject]@{
        EstaAutenticado = $true
        Usuario = "test@test.com"
        # Faltan IdentificadorInquilino e IdentificadorSuscripcion
    }
    
    try {
        $null = Get-HermesAzureResourceDiscovery -AzureContext $contextoIncompleto
        Fail "validación campos" "debería lanzar error con campos faltantes"
    } catch {
        if ($_.Exception.Message -match "no contiene el campo requerido") {
            Pass "rechaza AzureContext con campos faltantes"
        } else {
            Fail "validación campos" "mensaje incorrecto: $($_.Exception.Message)"
        }
    }
    
    # T5: Funciones privadas existen
    $funciones = @('ValidarAzureContext','ObtenerSuscripciones','ObtenerGruposRecursos','ObtenerRecursos','ConstruirResultadoDiscovery')
    $funciones | ForEach-Object {
        if (Get-Command $_ -ErrorAction SilentlyContinue) {
            Pass "función privada $_ existe"
        } else {
            Fail "función privada" "$_ no encontrada"
        }
    }
    
    # T6: ValidarAzureContext acepta contexto válido
    $contextoValido = [PSCustomObject]@{
        EstaAutenticado = $true
        Usuario = "test@test.com"
        IdentificadorInquilino = "tenant-123"
        IdentificadorSuscripcion = "sub-123"
    }
    
    try {
        ValidarAzureContext -AzureContext $contextoValido
        Pass "ValidarAzureContext acepta contexto válido"
    } catch {
        Fail "ValidarAzureContext" "rechazó contexto válido: $($_.Exception.Message)"
    }
    
    # T7: ConstruirResultadoDiscovery devuelve estructura correcta
    $suscripciones = @([PSCustomObject]@{id="sub-123";name="Test Sub";tenantId="tenant-123"})
    $grupos = @([PSCustomObject]@{name="RG-Test";location="eastus"})
    $recursos = @([PSCustomObject]@{name="VM-Test";type="Microsoft.Compute/virtualMachines"})
    $fecha = [datetime]::UtcNow
    
    $resultado = ConstruirResultadoDiscovery -AzureContext $contextoValido -Suscripciones $suscripciones -GruposRecursos $grupos -Recursos $recursos -FechaConsulta $fecha
    
    if ($resultado.Usuario -eq "test@test.com" -and
        $resultado.IdentificadorInquilino -eq "tenant-123" -and
        $resultado.SuscripcionesDisponibles.Count -eq 1 -and
        $resultado.GruposRecursos.Count -eq 1 -and
        $resultado.RecursosEncontrados.Count -eq 1 -and
        $resultado.TotalRecursos -eq 1 -and
        $resultado.EstaAutenticado -eq $true) {
        Pass "ConstruirResultadoDiscovery devuelve estructura correcta"
    } else {
        Fail "estructura resultado" "campos incorrectos"
    }
    
    # T8: TiposRecursos extrae tipos únicos
    if ($resultado.TiposRecursos.Count -eq 1 -and $resultado.TiposRecursos[0] -eq "Microsoft.Compute/virtualMachines") {
        Pass "TiposRecursos extrae tipos únicos correctamente"
    } else {
        Fail "TiposRecursos" "$($resultado.TiposRecursos -join ',')"
    }
    
} catch {
    Fail "error general" $_.Exception.Message
}

Write-Host "`n$("-"*72)" -ForegroundColor Cyan
$total = $p + $f
$color = if ($f -eq 0) { 'Green' } else { 'Red' }
Write-Host "RESULTADO: $p/$total passed, $f failed" -ForegroundColor $color
exit $f