#!/usr/bin/env python3
P = []
P.append('<div class="card mb-4"><div class="card-header"><span class="section-icon bg-dark me-2"><i class="bi bi-info-circle"></i></span>Proyecto</div><div class="card-body"><div class="row">\n')
P.append('<div class="col-md-6"><table class="table table-borderless trace-table mb-0 small">\n')
P.append('<tr><td class="text-muted">Nombre</td><td class="text-end" id="proj-name">&mdash;</td></tr>\n')
P.append('<tr><td class="text-muted">Deployment ID</td><td class="text-end" id="proj-did" style="font-family:monospace">&mdash;</td></tr>\n')
P.append('<tr><td class="text-muted">Correlation ID</td><td class="text-end" id="proj-cid" style="font-family:monospace">&mdash;</td></tr>\n')
P.append('<tr><td class="text-muted">Resultado</td><td class="text-end" id="proj-resultado">&mdash;</td></tr>\n')
P.append('</table></div>\n')
P.append('<div class="col-md-6"><table class="table table-borderless trace-table mb-0 small">\n')
P.append('<tr><td class="text-muted">Inicio</td><td class="text-end" id="proj-inicio">&mdash;</td></tr>\n')
P.append('<tr><td class="text-muted">Fin</td><td class="text-end" id="proj-fin">&mdash;</td></tr>\n')
P.append('<tr><td class="text-muted">Duraci&oacute;n total</td><td class="text-end" id="proj-duracion">&mdash;</td></tr>\n')
P.append('<tr><td class="text-muted">Actualizaci&oacute;n</td><td class="text-end" id="proj-actualizacion">&mdash;</td></tr>\n')
P.append('</table></div>\n')
P.append('</div></div></div>\n')

with open('tools/build_proyecto_3a.pkl', 'w', encoding='utf-8') as f:
    for p in P:
        f.write(p)
print("Part 3a written")