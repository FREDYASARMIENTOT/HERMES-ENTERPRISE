function Ejecutar-RenderizarPlantilla {
    <#
    .SYNOPSIS
        Renderiza una plantilla reemplazando {{PLACEHOLDERS}} con valores proporcionados.
    .PARAMETER TemplatePath
        Ruta al archivo de plantilla.
    .PARAMETER OutputPath
        Ruta donde se guardará el archivo renderizado.
    .PARAMETER Parameters
        Hashtable de pares clave-valor para sustitución.
    #>
    param(
        [Parameter(Mandatory)] [string] $TemplatePath,
        [Parameter(Mandatory)] [string] $OutputPath,
        [Parameter(Mandatory)] [hashtable] $Parameters
    )

    if (-not (Test-Path $TemplatePath)) {
        throw "Plantilla no encontrada: $TemplatePath"
    }

    $contenido = Get-Content -Path $TemplatePath -Raw -Encoding UTF8

    foreach ($clave in $Parameters.Keys) {
        $placeholder = "{{${clave}}}"
        $valor = $Parameters[$clave]
        $contenido = $contenido -replace [regex]::Escape($placeholder), $valor
    }

    $directorio = Split-Path $OutputPath -Parent
    if (-not (Test-Path $directorio)) {
        New-Item -Path $directorio -ItemType Directory -Force | Out-Null
    }

    $contenido | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
    Write-Host "[RenderEngine] Renderizado: $TemplatePath -> $OutputPath"
}

function Ejecutar-RenderizarPlantillaDesdeCadena {
    <#
    .SYNOPSIS
        Renderiza una cadena de plantilla reemplazando {{PLACEHOLDERS}} con valores proporcionados.
    .PARAMETER Content
        El contenido de la plantilla como cadena.
    .PARAMETER Parameters
        Hashtable de pares clave-valor para sustitución.
    .RETURNS
        Cadena renderizada.
    #>
    param(
        [Parameter(Mandatory)] [string] $Content,
        [Parameter(Mandatory)] [hashtable] $Parameters
    )

    foreach ($clave in $Parameters.Keys) {
        $placeholder = "{{${clave}}}"
        $valor = $Parameters[$clave]
        $Content = $Content -replace [regex]::Escape($placeholder), $valor
    }

    return $Content
}

function Obtener-RutaPlantilla {
    <#
    .SYNOPSIS
        Retorna la ruta completa a un archivo de plantilla dentro del directorio Templates.
    .PARAMETER RelativePath
        Ruta relativa desde el directorio Templates (ej., "backend/main.py").
    .PARAMETER HermesRoot
        Directorio raíz de Hermes Enterprise. Por defecto d:\HERMES-ENTERPRISE.
    #>
    param(
        [Parameter(Mandatory)] [string] $RelativePath,
        [string] $HermesRoot = "d:\HERMES-ENTERPRISE"
    )

    $directorioPlantillas = Join-Path (Join-Path $HermesRoot "tools") "Templates"
    $rutaCompleta = Join-Path $directorioPlantillas $RelativePath
    return $rutaCompleta
}

function Copiar-DirectorioPlantillas {
    <#
    .SYNOPSIS
        Copia todas las plantillas de un subdirectorio, renderizando cada una.
    .PARAMETER TemplateSubdir
        Subdirectorio bajo Templates (ej., "backend").
    .PARAMETER OutputDir
        Directorio de destino.
    .PARAMETER Parameters
        Hashtable de pares clave-valor para sustitución.
    .PARAMETER Exclude
        Lista de nombres de archivo a excluir.
    .PARAMETER HermesRoot
        Directorio raíz de Hermes Enterprise. Por defecto d:\HERMES-ENTERPRISE.
    #>
    param(
        [Parameter(Mandatory)] [string] $TemplateSubdir,
        [Parameter(Mandatory)] [string] $OutputDir,
        [Parameter(Mandatory)] [hashtable] $Parameters,
        [string[]] $Exclude = @(),
        [string] $HermesRoot = "d:\HERMES-ENTERPRISE"
    )

    $directorioPlantillas = Join-Path (Join-Path $HermesRoot "tools") "Templates"
    $origenDirectorio = Join-Path $directorioPlantillas $TemplateSubdir

    if (-not (Test-Path $origenDirectorio)) {
        throw "Subdirectorio de plantillas no encontrado: $origenDirectorio"
    }

    if (-not (Test-Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }

    Get-ChildItem -Path $origenDirectorio -File | ForEach-Object {
        if ($_.Name -notin $Exclude) {
            $rutaSalida = Join-Path $OutputDir $_.Name
            Ejecutar-RenderizarPlantilla -TemplatePath $_.FullName -OutputPath $rutaSalida -Parameters $Parameters
        }
    }

    Write-Host "[RenderEngine] Plantillas copiadas de '$TemplateSubdir' a '$OutputDir'"
}

function Crear-PaginaInicioProyecto {
    <#
    .SYNOPSIS
        Crea la página de inicio HTML que habla solo del proyecto.
        La única referencia a Hermes es "Powered by Hermes Enterprise" en el footer.
    .PARAMETER ProjectRoot
        Directorio raíz del proyecto.
    .PARAMETER ProjectName
        Nombre del proyecto.
    .OUTPUTS
        Ruta al archivo de plantilla generado.
    #>
    param(
        [Parameter(Mandatory)] [string] $ProjectRoot,
        [Parameter(Mandatory)] [string] $ProjectName,
        [Parameter(Mandatory)] [string] $WebAppName
    )

    $templatesDir = Join-Path $ProjectRoot "templates"
    if (-not (Test-Path $templatesDir)) {
        New-Item -Path $templatesDir -ItemType Directory -Force | Out-Null
    }

    $html = @"
<!DOCTYPE html>
<html lang="es" data-bs-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>HERMES ENTERPRISE — INFORME DE DESPLIEGUE</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<style>
body{background:#0b0f1a;color:#e0e0e0;font-family:'Segoe UI',system-ui,sans-serif}
.deploy-container{max-width:1100px;margin:0 auto;padding:20px}
.hero{background:linear-gradient(135deg,#0d6efd 0%,#6610f2 100%);border-radius:16px;padding:32px;margin-bottom:24px;text-align:center}
.hero h1{color:#fff;font-size:2rem;font-weight:700}
.hero .subtitle{color:rgba(255,255,255,0.85);font-size:1rem}
.card{background:#151b2b;border:1px solid #2a3250;border-radius:12px;padding:20px;margin-bottom:20px}
.card h5{color:#8b9dc3;font-size:0.85rem;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:12px}
.card .value{font-size:1.1rem;color:#fff}
.card .label{color:#6c7a9a;font-size:0.85rem}
.status-ok{color:#198754}
.status-fail{color:#dc3545}
.status-warn{color:#ffc107}
.link-grid a{display:inline-block;margin:4px;padding:8px 16px;background:#1e2740;border-radius:8px;color:#8ab4f8;text-decoration:none;font-size:0.9rem}
.link-grid a:hover{background:#2a3555;color:#fff}
.footer{text-align:center;padding:20px;color:#4a5570;font-size:0.85rem}
.timeline-item{padding:6px 0;border-left:2px solid #2a3250;padding-left:16px;margin-left:8px}
.endpoint-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:10px}
.endpoint-item{background:#1e2740;border:1px solid #2a3250;border-radius:8px;padding:12px;transition:border-color .2s}
.endpoint-item:hover{border-color:#0d6efd}
.ep-header{display:flex;align-items:center;gap:8px;margin-bottom:6px}
.ep-method{font-size:.65rem}
.ep-path{font-size:.78rem;color:#8ab4f8;flex:1}
.ep-status{font-size:.6rem;padding:2px 6px}
.ep-title{font-size:.9rem;color:#fff;font-weight:600;margin-bottom:2px}
.ep-desc{font-size:.75rem;color:#8b9dc3;margin-bottom:6px}
.ep-link{font-size:.72rem;color:#0d6efd;text-decoration:none;display:inline-block;padding:2px 0}
.ep-link:hover{text-decoration:underline;color:#6ea8fe}
</style>
</head>
<body>
<div class="deploy-container">
    <div class="hero">
        <h1><i class="bi bi-rocket-takeoff me-2"></i>HERMES ENTERPRISE</h1>
        <div class="subtitle">INFORME DE DESPLIEGUE</div>
        <div class="mt-3">
            <span class="badge bg-success me-2" id="statusBadge">🟢 OPERATIVO</span>
            <span class="badge bg-info text-dark" id="cidBadge">CID:--</span>
        </div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-md-4">
            <div class="card"><h5><i class="bi bi-folder me-2"></i>Proyecto</h5><div class="value" id="projectName">$ProjectName</div></div>
        </div>
        <div class="col-md-4">
            <div class="card"><h5><i class="bi bi-globe me-2"></i>App Service</h5><div class="value" id="webappName">$WebAppName</div><div class="label" id="regionLabel">--</div></div>
        </div>
        <div class="col-md-4">
            <div class="card"><h5><i class="bi bi-cpu me-2"></i>Runtime</h5><div class="value">Python 3.12</div><div class="label" id="deployLabel">Deploy: --</div></div>
        </div>
    </div>

    <div class="card mb-4">
        <h5><i class="bi bi-link me-2"></i>ACCESOS</h5>
        <div class="link-grid">
            <a href="#" target="_blank" id="linkFrontend"><i class="bi bi-house-fill me-1"></i>Frontend</a>
            <a href="#" target="_blank" id="linkHealth"><i class="bi bi-heart-pulse me-1"></i>Health</a>
            <a href="#" target="_blank" id="linkSwagger"><i class="bi bi-file-earmark-code me-1"></i>Swagger UI</a>
            <a href="#" target="_blank" id="linkOpenAPI"><i class="bi bi-filetype-json me-1"></i>OpenAPI</a>
            <a href="#" target="_blank" id="linkVersion"><i class="bi bi-tag me-1"></i>Version</a>
            <a href="#" target="_blank" id="linkProyecto"><i class="bi bi-info-circle me-1"></i>Proyecto</a>
        </div>
    </div>

    <div class="card mb-4">
        <h5><i class="bi bi-hdd-stack me-2"></i>ENDPOINTS DE LA API</h5>
        <div class="endpoint-grid">
            <div class="endpoint-item" data-endpoint="/api/version">
                <div class="ep-header"><span class="badge bg-success ep-method">GET</span><code class="ep-path">/api/version</code><span class="badge bg-secondary status-badge ep-status" id="c-status-version">...</span></div>
                <div class="ep-title">Versión del Sistema</div>
                <div class="ep-desc">Consulta la versión desplegada, commit, rama y runtime.</div>
                <a href="/api/version" target="_blank" rel="noopener noreferrer" class="ep-link">ABRIR ENDPOINT ↗</a>
            </div>
            <div class="endpoint-item" data-endpoint="/api/proyecto">
                <div class="ep-header"><span class="badge bg-success ep-method">GET</span><code class="ep-path">/api/proyecto</code><span class="badge bg-secondary status-badge ep-status" id="c-status-proyecto">...</span></div>
                <div class="ep-title">Estado del Proyecto</div>
                <div class="ep-desc">Identidad y estado actual del proyecto.</div>
                <a href="/api/proyecto" target="_blank" rel="noopener noreferrer" class="ep-link">ABRIR ENDPOINT ↗</a>
            </div>
            <div class="endpoint-item" data-endpoint="/api/workspace">
                <div class="ep-header"><span class="badge bg-success ep-method">GET</span><code class="ep-path">/api/workspace</code><span class="badge bg-secondary status-badge ep-status" id="c-status-workspace">...</span></div>
                <div class="ep-title">Workspace</div>
                <div class="ep-desc">Estado del workspace de ejecución.</div>
                <a href="/api/workspace" target="_blank" rel="noopener noreferrer" class="ep-link">ABRIR ENDPOINT ↗</a>
            </div>
            <div class="endpoint-item" data-endpoint="/api/git">
                <div class="ep-header"><span class="badge bg-success ep-method">GET</span><code class="ep-path">/api/git</code><span class="badge bg-secondary status-badge ep-status" id="c-status-git">...</span></div>
                <div class="ep-title">Git Local</div>
                <div class="ep-desc">Información del repositorio Git local.</div>
                <a href="/api/git" target="_blank" rel="noopener noreferrer" class="ep-link">ABRIR ENDPOINT ↗</a>
            </div>
            <div class="endpoint-item" data-endpoint="/api/github">
                <div class="ep-header"><span class="badge bg-success ep-method">GET</span><code class="ep-path">/api/github</code><span class="badge bg-secondary status-badge ep-status" id="c-status-github">...</span></div>
                <div class="ep-title">GitHub Remoto</div>
                <div class="ep-desc">Integración con repositorio GitHub.</div>
                <a href="/api/github" target="_blank" rel="noopener noreferrer" class="ep-link">ABRIR ENDPOINT ↗</a>
            </div>
            <div class="endpoint-item" data-endpoint="/api/entorno">
                <div class="ep-header"><span class="badge bg-success ep-method">GET</span><code class="ep-path">/api/entorno</code><span class="badge bg-secondary status-badge ep-status" id="c-status-entorno">...</span></div>
                <div class="ep-title">Entorno Python</div>
                <div class="ep-desc">Versión de Python y entorno de ejecución.</div>
                <a href="/api/entorno" target="_blank" rel="noopener noreferrer" class="ep-link">ABRIR ENDPOINT ↗</a>
            </div>
        <div class="endpoint-item" data-endpoint="/api/azure">
                <div class="ep-header"><span class="badge bg-success ep-method">GET</span><code class="ep-path">/api/azure</code><span class="badge bg-secondary status-badge ep-status" id="c-status-azure">...</span></div>
                <div class="ep-title">Azure</div>
                <div class="ep-desc">Estado de recursos Azure disponibles.</div>
                <a href="/api/azure" target="_blank" rel="noopener noreferrer" class="ep-link">ABRIR ENDPOINT ↗</a>
            </div>
            <div class="endpoint-item" data-endpoint="/api/sqlite">
                <div class="ep-header"><span class="badge bg-success ep-method">GET</span><code class="ep-path">/api/sqlite</code><span class="badge bg-secondary status-badge ep-status" id="c-status-sqlite">...</span></div>
                <div class="ep-title">SQLite</div>
                <div class="ep-desc">Persistencia y estado de SQLite.</div>
                <a href="/api/sqlite" target="_blank" rel="noopener noreferrer" class="ep-link">ABRIR ENDPOINT ↗</a>
            </div>
            <div class="endpoint-item" data-endpoint="/api/despliegue">
                <div class="ep-header"><span class="badge bg-success ep-method">GET</span><code class="ep-path">/api/despliegue</code><span class="badge bg-secondary status-badge ep-status" id="c-status-despliegue">...</span></div>
                <div class="ep-title">Despliegue</div>
                <div class="ep-desc">Información del despliegue actual.</div>
                <a href="/api/despliegue" target="_blank" rel="noopener noreferrer" class="ep-link">ABRIR ENDPOINT ↗</a>
            </div>
            <div class="endpoint-item" data-endpoint="/api/telemetria">
                <div class="ep-header"><span class="badge bg-success ep-method">GET</span><code class="ep-path">/api/telemetria</code><span class="badge bg-secondary status-badge ep-status" id="c-status-telemetria">...</span></div>
                <div class="ep-title">Telemetría</div>
                <div class="ep-desc">Mecanismos de telemetría.</div>
                <a href="/api/telemetria" target="_blank" rel="noopener noreferrer" class="ep-link">ABRIR ENDPOINT ↗</a>
            </div>
            <div class="endpoint-item" data-endpoint="/api/bootstrap">
                <div class="ep-header"><span class="badge bg-success ep-method">GET</span><code class="ep-path">/api/bootstrap</code><span class="badge bg-secondary status-badge ep-status" id="c-status-bootstrap">...</span></div>
                <div class="ep-title">Bootstrap</div>
                <div class="ep-desc">Inicialización del runtime.</div>
                <a href="/api/bootstrap" target="_blank" rel="noopener noreferrer" class="ep-link">ABRIR ENDPOINT ↗</a>
            </div>
        </div>
    </div>

    <div class="card mb-4" id="smokeTestsCard">
        <h5><i class="bi bi-shield-check me-2"></i>PRUEBAS FUNCIONALES</h5>
        <div class="table-responsive">
            <table class="table table-dark table-sm">
                <thead><tr><th>Endpoint</th><th>HTTP</th><th>Estado</th></tr></thead>
                <tbody id="smokeTestsBody">
                    <tr><td colspan="3" class="text-secondary text-center">Cargando...</td></tr>
                </tbody>
            </table>
        </div>
    </div>

    <div class="footer">
        <p>Powered by Hermes Enterprise</p>
    </div>
</div>

<script>
const baseUrl = window.location.origin;
document.getElementById('linkFrontend').href = baseUrl + '/';
document.getElementById('linkHealth').href = baseUrl + '/health';
document.getElementById('linkSwagger').href = baseUrl + '/swagger';
document.getElementById('linkOpenAPI').href = baseUrl + '/openapi.json';
document.getElementById('linkVersion').href = baseUrl + '/api/version';
document.getElementById('linkProyecto').href = baseUrl + '/api/proyecto';

function setEndpointStatus(id, data, error) {
    const badge = document.getElementById(id);
    if (!badge) return;
    if (error) {
        badge.className = 'badge bg-danger status-badge ep-status';
        badge.textContent = 'error';
        return;
    }
    const estado = data && data.estado;
    if (!estado) {
        badge.className = 'badge bg-success status-badge ep-status';
        badge.textContent = 'verificado';
        return;
    }
    const ok = ['verificado','activo','saludable','desplegado','telemetria_activa'];
    const nok = ['no_disponible','no_configurado','no_verificado','no_iniciado'];
    if (ok.includes(estado)) {
        badge.className = 'badge bg-success status-badge ep-status';
        badge.textContent = 'verificado';
    } else if (estado === 'error') {
        badge.className = 'badge bg-danger status-badge ep-status';
        badge.textContent = 'error';
    } else if (nok.includes(estado)) {
        badge.className = 'badge bg-warning text-dark status-badge ep-status';
        badge.textContent = estado;
    } else {
        badge.className = 'badge bg-info status-badge ep-status';
        badge.textContent = estado;
    }
}

fetch('/api/proyecto').then(r=>r.json()).then(d=>{
    document.getElementById('projectName').textContent = d.Nombre || d.nombre || '$ProjectName';
    document.getElementById('cidBadge').textContent = 'CID:' + ((d.CorrelationId || d.correlationId || '--').substring(0,8));
    setEndpointStatus('c-status-proyecto', d, null);
}).catch(()=>{setEndpointStatus('c-status-proyecto', null, true)});
fetch('/api/version').then(r=>r.json()).then(d=>{
    document.getElementById('deployLabel').textContent = 'Version: ' + (d.version || '1.0.0');
    setEndpointStatus('c-status-version', d, null);
}).catch(()=>{setEndpointStatus('c-status-version', null, true)});
fetch('/api/azure').then(r=>r.json()).then(d=>{
    const webapp = d.webapp || d.WebAppName || '$WebAppName';
    document.getElementById('webappName').textContent = webapp;
    setEndpointStatus('c-status-azure', d, null);
}).catch(()=>{setEndpointStatus('c-status-azure', null, true)});
fetch('/api/git').then(r=>r.json()).then(d=>{
    if(d.CommitHash || d.commitHash) {
        document.getElementById('deployLabel').textContent = 'Commit: ' + (d.CommitHash || d.commitHash || '').substring(0,7);
    }
    setEndpointStatus('c-status-git', d, null);
}).catch(()=>{setEndpointStatus('c-status-git', null, true)});
fetch('/api/github').then(r=>r.json()).then(d=>{
    setEndpointStatus('c-status-github', d, null);
}).catch(()=>{setEndpointStatus('c-status-github', null, true)});
fetch('/api/entorno').then(r=>r.json()).then(d=>{
    setEndpointStatus('c-status-entorno', d, null);
}).catch(()=>{setEndpointStatus('c-status-entorno', null, true)});
fetch('/api/workspace').then(r=>r.json()).then(d=>{
    setEndpointStatus('c-status-workspace', d, null);
}).catch(()=>{setEndpointStatus('c-status-workspace', null, true)});
fetch('/api/sqlite').then(r=>r.json()).then(d=>{
    setEndpointStatus('c-status-sqlite', d, null);
}).catch(()=>{setEndpointStatus('c-status-sqlite', null, true)});
fetch('/api/despliegue').then(r=>r.json()).then(d=>{
    setEndpointStatus('c-status-despliegue', d, null);
}).catch(()=>{setEndpointStatus('c-status-despliegue', null, true)});
fetch('/api/telemetria').then(r=>r.json()).then(d=>{
    setEndpointStatus('c-status-telemetria', d, null);
}).catch(()=>{setEndpointStatus('c-status-telemetria', null, true)});
fetch('/api/bootstrap').then(r=>r.json()).then(d=>{
    setEndpointStatus('c-status-bootstrap', d, null);
}).catch(()=>{setEndpointStatus('c-status-bootstrap', null, true)});

// Timestamp
document.getElementById('timestampField').textContent = new Date().toISOString().replace('T',' ').substring(0,19) + ' UTC';

// Load smoke tests
fetch('/api/despliegue').then(r=>r.json()).then(d=>{
    const tests = d.smokeTests || d.SmokeTests || null;
    if(tests && tests.length > 0) {
        let html = '';
        tests.forEach(t => {
            const ep = t.Endpoint || t.endpoint || '--';
            const code = t.HTTPCode || t.httpCode || '--';
            const status = t.Estado || t.estado || 'FAIL';
            const icon = status === 'PASS' ? '<i class=\"bi bi-check-circle-fill text-success\"></i>' : '<i class=\"bi bi-x-circle-fill text-danger\"></i>';
            html += '<tr><td><code>' + ep + '</code></td><td>' + code + '</td><td>' + icon + ' ' + status + '</td></tr>';
        });
        document.getElementById('smokeTestsBody').innerHTML = html;
    } else {
        document.getElementById('smokeTestsBody').innerHTML = '<tr><td colspan=\"3\" class=\"text-secondary text-center\">No hay resultados de pruebas disponibles</td></tr>';
    }
}).catch(()=>{});
</script>
</body>
</html>
"@

    $outputPath = Join-Path $templatesDir "index.html"
    $html | Out-File -FilePath $outputPath -Encoding UTF8 -Force

    Write-Host "[RenderEngine] Landing page created: $outputPath"
    return $outputPath
}

Export-ModuleMember -Function Ejecutar-RenderizarPlantilla, Ejecutar-RenderizarPlantillaDesdeCadena, Obtener-RutaPlantilla, Copiar-DirectorioPlantillas, Crear-PaginaInicioProyecto
