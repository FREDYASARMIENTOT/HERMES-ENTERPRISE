function Invoke-RenderTemplate {
    <#
    .SYNOPSIS
        Renders a template file replacing {{PLACEHOLDERS}} with provided values.
    .PARAMETER TemplatePath
        Path to the template file.
    .PARAMETER OutputPath
        Path where the rendered file will be saved.
    .PARAMETER Parameters
        Hashtable of key-value pairs for substitution.
    #>
    param(
        [Parameter(Mandatory)] [string] $TemplatePath,
        [Parameter(Mandatory)] [string] $OutputPath,
        [Parameter(Mandatory)] [hashtable] $Parameters
    )

    if (-not (Test-Path $TemplatePath)) {
        throw "Template not found: $TemplatePath"
    }

    $content = Get-Content -Path $TemplatePath -Raw -Encoding UTF8

    foreach ($key in $Parameters.Keys) {
        $placeholder = "{{${key}}}"
        $value = $Parameters[$key]
        $content = $content -replace [regex]::Escape($placeholder), $value
    }

    $dir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }

    $content | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
    Write-Host "[RenderEngine] Rendered: $TemplatePath -> $OutputPath"
}

function Invoke-RenderTemplateFromString {
    <#
    .SYNOPSIS
        Renders a template string replacing {{PLACEHOLDERS}} with provided values.
    .PARAMETER Content
        The template content as a string.
    .PARAMETER Parameters
        Hashtable of key-value pairs for substitution.
    .RETURNS
        Rendered string.
    #>
    param(
        [Parameter(Mandatory)] [string] $Content,
        [Parameter(Mandatory)] [hashtable] $Parameters
    )

    foreach ($key in $Parameters.Keys) {
        $placeholder = "{{${key}}}"
        $value = $Parameters[$key]
        $Content = $Content -replace [regex]::Escape($placeholder), $value
    }

    return $Content
}

function Get-TemplatePath {
    <#
    .SYNOPSIS
        Returns the full path to a template file within the Templates directory.
    .PARAMETER RelativePath
        Relative path from the Templates directory (e.g., "backend/main.py").
    .PARAMETER HermesRoot
        Root directory of Hermes Enterprise. Defaults to d:\HERMES-ENTERPRISE.
    #>
    param(
        [Parameter(Mandatory)] [string] $RelativePath,
        [string] $HermesRoot = "d:\HERMES-ENTERPRISE"
    )

    $templatesDir = Join-Path (Join-Path $HermesRoot "tools") "Templates"
    $fullPath = Join-Path $templatesDir $RelativePath
    return $fullPath
}

function Copy-TemplateDirectory {
    <#
    .SYNOPSIS
        Copies all templates from a subdirectory, rendering each one.
    .PARAMETER TemplateSubdir
        Subdirectory under Templates (e.g., "backend").
    .PARAMETER OutputDir
        Destination directory.
    .PARAMETER Parameters
        Hashtable of key-value pairs for substitution.
    .PARAMETER Exclude
        Array of filenames to exclude.
    .PARAMETER HermesRoot
        Root directory of Hermes Enterprise. Defaults to d:\HERMES-ENTERPRISE.
    #>
    param(
        [Parameter(Mandatory)] [string] $TemplateSubdir,
        [Parameter(Mandatory)] [string] $OutputDir,
        [Parameter(Mandatory)] [hashtable] $Parameters,
        [string[]] $Exclude = @(),
        [string] $HermesRoot = "d:\HERMES-ENTERPRISE"
    )

    $templatesDir = Join-Path (Join-Path $HermesRoot "tools") "Templates"
    $srcDir = Join-Path $templatesDir $TemplateSubdir

    if (-not (Test-Path $srcDir)) {
        throw "Template subdirectory not found: $srcDir"
    }

    if (-not (Test-Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }

    Get-ChildItem -Path $srcDir -File | ForEach-Object {
        if ($_.Name -notin $Exclude) {
            $outputPath = Join-Path $OutputDir $_.Name
            Invoke-RenderTemplate -TemplatePath $_.FullName -OutputPath $outputPath -Parameters $Parameters
        }
    }

    Write-Host "[RenderEngine] Copied templates from '$TemplateSubdir' to '$OutputDir'"
}

function New-ProyectoLanding {
    <#
    .SYNOPSIS
        Creates the landing page HTML that speaks only about the project.
        The only reference to Hermes is "Powered by Hermes Enterprise" in the footer.
    .PARAMETER ProjectRoot
        Root directory of the project.
    .PARAMETER ProjectName
        Name of the project.
    .OUTPUTS
        Path to the generated template file.
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
        <h5><i class="bi bi-calendar-event me-2"></i>Fecha/Hora</h5>
        <div class="value" id="timestampField">Cargando...</div>
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

fetch('/api/proyecto').then(r=>r.json()).then(d=>{
    document.getElementById('projectName').textContent = d.Nombre || d.nombre || '$ProjectName';
    document.getElementById('cidBadge').textContent = 'CID:' + ((d.CorrelationId || d.correlationId || '--').substring(0,8));
}).catch(()=>{});
fetch('/api/version').then(r=>r.json()).then(d=>{
    document.getElementById('deployLabel').textContent = 'Version: ' + (d.version || '1.0.0');
}).catch(()=>{});
fetch('/api/azure').then(r=>r.json()).then(d=>{
    const webapp = d.webapp || d.WebAppName || '$WebAppName';
    document.getElementById('webappName').textContent = webapp;
}).catch(()=>{});
fetch('/api/git').then(r=>r.json()).then(d=>{
    if(d.CommitHash || d.commitHash) {
        document.getElementById('deployLabel').textContent = 'Commit: ' + (d.CommitHash || d.commitHash || '').substring(0,7);
    }
}).catch(()=>{});

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

Export-ModuleMember -Function Invoke-RenderTemplate, Invoke-RenderTemplateFromString, Get-TemplatePath, Copy-TemplateDirectory, New-ProyectoLanding
