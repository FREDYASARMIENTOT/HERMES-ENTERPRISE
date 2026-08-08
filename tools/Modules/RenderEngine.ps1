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
        [Parameter(Mandatory)] [string] $ProjectName
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
<title>$ProjectName</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<style>
:root{--accent:#00d4aa;--bg-card:#1a1d23}
body{background:#0d1117;color:#e6edf3;font-family:'Segoe UI',system-ui,sans-serif}
.hero-section{padding:4rem 0 2rem 0;text-align:center}
.hero-section h1{font-size:2.5rem;font-weight:700;color:#fff}
.hero-section .badge{font-size:0.9rem;padding:0.5rem 1rem}
.card{background:var(--bg-card);border:1px solid #30363d;border-radius:12px;margin-bottom:1rem}
.card-header{background:rgba(255,255,255,0.03);border-bottom:1px solid #30363d;font-weight:600}
.metric-value{font-size:1.8rem;font-weight:700;color:var(--accent)}
.metric-label{font-size:0.85rem;color:#8b949e}
.timeline-node{display:flex;align-items:center;padding:0.75rem 1rem;border-left:3px solid #30363d;margin-left:1rem}
.timeline-node.ok{border-left-color:var(--accent)}
.timeline-node.pending{border-left-color:#484f58}
.footer{text-align:center;padding:2rem 0;color:#8b949e;font-size:0.85rem}
.status-ok{color:var(--accent)}
.status-fail{color:#f85149}
.status-pending{color:#8b949e}
</style>
</head>
<body>
<div class="container">
    <div class="hero-section">
        <div class="mb-3">
            <span class="badge bg-success" id="statusBadge">Loading...</span>
        </div>
        <h1 id="projectTitle">$ProjectName</h1>
        <p class="text-secondary fs-5" id="projectDesc">Loading project information...</p>
        <div class="d-flex justify-content-center gap-3 mt-3">
            <small class="text-secondary" id="projectVersion">Version: --</small>
            <small class="text-secondary" id="projectCommit">Commit: --</small>
            <small class="text-secondary" id="projectBranch">Branch: --</small>
        </div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-md-3"><div class="card p-3 text-center"><div class="metric-value" id="metricBuildTime">--</div><div class="metric-label">Build Time</div></div></div>
        <div class="col-md-3"><div class="card p-3 text-center"><div class="metric-value" id="metricDeployTime">--</div><div class="metric-label">Deploy Time</div></div></div>
        <div class="col-md-3"><div class="card p-3 text-center"><div class="metric-value" id="metricSmokeTime">--</div><div class="metric-label">Smoke Test</div></div></div>
        <div class="col-md-3"><div class="card p-3 text-center"><div class="metric-value" id="metricCorrelation">--</div><div class="metric-label">CorrelationId</div></div></div>
    </div>

    <div class="card">
        <div class="card-header">Timeline</div>
        <div class="card-body" id="timelineContainer">
            <div class="timeline-node pending"><span class="status-pending">Loading timeline...</span></div>
        </div>
    </div>

    <div class="row g-3 mt-2">
        <div class="col-md-6">
            <div class="card"><div class="card-header">Azure Status</div><div class="card-body"><span id="azureStatus" class="status-pending">Checking...</span></div></div>
        </div>
        <div class="col-md-6">
            <div class="card"><div class="card-header">GitHub Status</div><div class="card-body"><span id="githubStatus" class="status-pending">Checking...</span></div></div>
        </div>
    </div>

    <div class="card mt-2">
        <div class="card-header">Deploy Information</div>
        <div class="card-body">
            <table class="table table-dark table-borderless table-sm">
                <tr><td>Repository</td><td id="deployRepo">--</td></tr>
                <tr><td>Pipeline</td><td id="deployPipeline">--</td></tr>
                <tr><td>URL</td><td id="deployUrl">--</td></tr>
                <tr><td>CI Status</td><td id="deployCI">--</td></tr>
            </table>
        </div>
    </div>

    <div class="footer">
        <p><strong id="footerProyecto">$ProjectName</strong></p>
        <p>Powered by Hermes Enterprise</p>
    </div>
</div>

<script>
fetch('/api/proyecto').then(r=>r.json()).then(d=>{
    document.getElementById('projectTitle').textContent = d.Nombre || d.nombre || '$ProjectName';
    document.getElementById('projectDesc').textContent = d.Descripcion || d.descripcion || 'Proyecto activo';
    document.getElementById('projectVersion').textContent = 'Version: ' + (d.Version || d.version || '--');
});
fetch('/api/version').then(r=>r.json()).then(d=>{
    document.getElementById('metricCorrelation').textContent = (d.CorrelationId || d.correlationId || '--').substring(0,8);
});
fetch('/api/workspace').then(r=>r.json()).then(d=>{
    document.getElementById('metricBuildTime').textContent = (d.TiempoBuild || d.tiempoBuild || '--') + 's';
});
fetch('/api/git').then(r=>r.json()).then(d=>{
    document.getElementById('projectCommit').textContent = 'Commit: ' + (d.CommitHash || d.commitHash || '--').substring(0,7);
    document.getElementById('projectBranch').textContent = 'Branch: ' + (d.Branch || d.branch || 'main');
});
fetch('/api/github').then(r=>r.json()).then(d=>{
    document.getElementById('githubStatus').textContent = d.Estado || d.estado || 'OK';
    document.getElementById('githubStatus').className = 'status-ok';
    document.getElementById('deployRepo').textContent = d.Repositorio || d.repositorio || '--';
});
fetch('/api/azure').then(r=>r.json()).then(d=>{
    document.getElementById('azureStatus').textContent = d.Estado || d.estado || 'OK';
    document.getElementById('azureStatus').className = 'status-ok';
    document.getElementById('deployUrl').textContent = d.UrlPublica || d.urlPublica || '--';
});
fetch('/api/despliegue').then(r=>r.json()).then(d=>{
    document.getElementById('metricDeployTime').textContent = (d.TiempoDeploy || d.tiempoDeploy || '--') + 's';
    document.getElementById('metricSmokeTime').textContent = (d.TiempoSmokeTest || d.tiempoSmokeTest || '--') + 's';
    document.getElementById('deployCI').textContent = d.Estado || d.estado || 'OK';
});
fetch('/api/sqlite').then(r=>r.json()).then(d=>{
    if(d.status === 'ok') document.getElementById('statusBadge').textContent = 'Online';
});

// Timeline
fetch('/api/timeline').then(r=>r.json()).then(events=>{
    const c = document.getElementById('timelineContainer');
    c.innerHTML = '';
    (events || []).forEach(e=>{
        const cls = (e.Estado || e.estado) === 'OK' ? 'ok' : 'pending';
        c.innerHTML += '<div class="timeline-node '+cls+'"><span class="status-'+((e.Estado||e.estado)==='OK'?'ok':'pending')+' me-2">'+((e.Estado||e.estado)||'PENDIENTE')+'</span><strong>'+ (e.Evento||e.evento) +'</strong><small class="ms-2 text-secondary">'+ (e.Fecha||e.fecha||'') +' '+ (e.Duracion||e.duracion||'') +'</small></div>';
    });
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
