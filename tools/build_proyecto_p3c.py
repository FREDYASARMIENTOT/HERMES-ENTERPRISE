#!/usr/bin/env python3
P = []
# Links card
P.append('<div class="card mb-4"><div class="card-header"><span class="section-icon bg-dark me-2"><i class="bi bi-link-45deg"></i></span>Links Operacionales</div>\n')
P.append('<div class="card-body"><div class="row g-2" id="links-container">\n')
P.append('<div class="col-md-4 col-6"><a id="link-repo" href="#" target="_blank" class="btn btn-sm btn-outline-secondary w-100 d-none"><i class="bi bi-github me-1"></i>GitHub Repository</a></div>\n')
P.append('<div class="col-md-4 col-6"><a id="link-commit" href="#" target="_blank" class="btn btn-sm btn-outline-secondary w-100 d-none"><i class="bi bi-git-commit me-1"></i>Commit</a></div>\n')
P.append('<div class="col-md-4 col-6"><a id="link-factory-run" href="#" target="_blank" class="btn btn-sm btn-outline-secondary w-100 d-none"><i class="bi bi-gear me-1"></i>Factory Run</a></div>\n')
P.append('<div class="col-md-4 col-6"><a id="link-child-ci" href="#" target="_blank" class="btn btn-sm btn-outline-secondary w-100 d-none"><i class="bi bi-github me-1"></i>Child CI</a></div>\n')
P.append('<div class="col-md-4 col-6"><a id="link-control-plane" href="#" target="_blank" class="btn btn-sm btn-outline-secondary w-100 d-none"><i class="bi bi-diagram-3 me-1"></i>Control Plane</a></div>\n')
P.append('<div class="col-md-4 col-6"><a id="link-azure-plan" href="#" target="_blank" class="btn btn-sm btn-outline-secondary w-100 d-none"><i class="bi bi-microsoft me-1"></i>Azure Portal</a></div>\n')
P.append('<div class="col-md-4 col-6"><a id="link-webapp" href="#" target="_blank" class="btn btn-sm btn-outline-secondary w-100 d-none"><i class="bi bi-globe me-1"></i>Azure Web App</a></div>\n')
P.append('<div class="col-md-4 col-6"><a id="link-health" href="#" target="_blank" class="btn btn-sm btn-outline-secondary w-100 d-none"><i class="bi bi-heart-pulse me-1"></i>Health</a></div>\n')
P.append('<div class="col-md-4 col-6"><a id="link-openapi" href="#" target="_blank" class="btn btn-sm btn-outline-secondary w-100 d-none"><i class="bi bi-file-earmark-code me-1"></i>OpenAPI</a></div>\n')
P.append('<div class="col-md-4 col-6"><a id="link-docs" href="#" target="_blank" class="btn btn-sm btn-outline-secondary w-100 d-none"><i class="bi bi-book me-1"></i>Docs</a></div>\n')
P.append('</div></div></div>\n')
P.append('</div></div>\n')
# Auto-refresh
P.append('<div class="auto-refresh-badge"><span class="badge bg-dark bg-opacity-75 p-2" id="auto-refresh-status"><i class="bi bi-arrow-clockwise me-1"></i><span id="polling-text">5s</span></span></div>\n')

with open('tools/build_proyecto_3c.pkl', 'w', encoding='utf-8') as f:
    for p in P:
        f.write(p)
print("Part 3c written")