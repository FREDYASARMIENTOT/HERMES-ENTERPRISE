#!/usr/bin/env python3
import os
BASE = r"d:\HERMES-ENTERPRISE"

def instrument_factory_yml():
    path = os.path.join(BASE, ".github", "workflows", "factory-run.yml")
    d = open(path, 'r', encoding='utf-8').read()
    marker = 'RESUMEN EJECUTIVO'
    idx = d.rfind(marker)
    if idx < 0: print("factory: RESUMEN not found"); return False
    # Find beginning of line containing RESUMEN (bol) to avoid splitting echo
    bol = d.rfind("\n", 0, idx) + 1

    h = [
        '',
        '          # --- TRACE: Registrar pasos en Portal ---',
        '          echo ""',
        '          echo "--- TRACE: Registrando trazabilidad en Portal ---"',
        '          register_paso() {',
        '            local NUM=$1 NAME=$2 ESTADO=$3 DETALLE=$4 RESULT=$5',
        '            local RESPONSE HTTP_CODE',
        '            RESPONSE=$(curl -s -w "\\n%{http_code}" -X POST "${PORTAL_URL}/api/fabrica/proyectos/${DID}/paso" \\',
        '              -H "Content-Type: application/json" \\',
        '              -d "{\\"numero_paso\\":${NUM},\\"estado_paso\\":\\"${ESTADO}\\",\\"detalle\\":\\"${DETALLE}\\",\\"evidencia\\":\\"${RESULT}\\"}" 2>&1)',
        '            HTTP_CODE=$(echo "${RESPONSE}" | tail -1)',
        '            if [ "${HTTP_CODE}" -ge 200 ] && [ "${HTTP_CODE}" -lt 300 ]; then',
        '              echo "  OK: Paso ${NUM} ${NAME} -> ${ESTADO} (HTTP ${HTTP_CODE})"',
        '            else',
        '              echo "  WARN: Paso ${NUM} ${NAME} -> HTTP ${HTTP_CODE}"',
        '            fi',
        '          }',
        '          register_paso 2 "FACTORY" "COMPLETADO" "Factory Runner ejecutado" "PASS"',
        '          register_paso 3 "GITHUB" "COMPLETADO" "Repo hijo creado SHA ${SHA}" "PASS"',
        '          if [ -n "${ASP_ID}" ]; then',
        '            register_paso 7 "AZURE" "COMPLETADO" "Plan asignado: ${ASP_ID}" "PASS"',
        '          fi',
        '',
    ]
    new_d = d[:bol] + '\n'.join(h) + '\n\n' + d[bol:]
    open(path, 'w', encoding='utf-8').write(new_d)
    print("factory-run.yml: OK")
    return True

def instrument_deploy_yml():
    path = os.path.join(BASE, ".github", "workflows", "deploy-child.yml")
    d = open(path, 'r', encoding='utf-8').read()
    if d.find('register_paso 12') >= 0: print("deploy: already done"); return True
    idx = d.rfind('register_paso')
    if idx < 0: print("deploy: no register_paso"); return False
    # Find end of line containing the last register_paso
    eol = d.find('\n', idx)
    ins = '\n          # Step 12: PUBLICACION\n          register_paso 12 "PUBLICACIÓN" "COMPLETADO" "WebApp publicada" "PASS"\n          # Step 13: NAVEGADOR\n          UF_RESULT="${{ needs.user-facing-validation.outputs.user_facing_result }}"\n          UF_ESTADO="COMPLETADO"\n          if [ "${UF_RESULT}" != "PASS" ]; then UF_ESTADO="FALLIDO"; fi\n          register_paso 13 "NAVEGADOR" "${UF_ESTADO}" "Validacion navegador: ${UF_RESULT}" "${UF_RESULT}"\n'
    # Insert AFTER the complete line containing the last register_paso
    new_d = d[:eol + 1] + ins + d[eol + 1:]
    open(path, 'w', encoding='utf-8').write(new_d)
    print("deploy-child.yml: OK")
    return True

def update_index_html():
    path = os.path.join(BASE, "Hermes.Web", "templates", "index.html")
    d = open(path, 'r', encoding='utf-8').read()
    if d.find('traceability-summary') >= 0: print("index: already done"); return True
    idx = d.find('</body>')
    if idx < 0: print("index: </body> not found"); return False
    ins = '\n    <div class="row mb-4" id="traceability-summary">\n        <div class="col-12">\n            <div class="card">\n                <div class="card-header d-flex justify-content-between align-items-center">\n                    <h5 class="mb-0"><i class="bi bi-diagram-3 me-2 text-info"></i>Trazabilidad</h5>\n                    <a href="/proyecto" class="btn btn-outline-info btn-sm"><i class="bi bi-eye me-1"></i>Panel</a>\n                </div>\n                <div class="card-body">\n                    <p class="text-muted small mb-3">13 pasos canónicos. Event Store captura estado/evidencia.</p>\n                    <div class="row g-2">\n                        <div class="col-3"><div class="text-center p-2 rounded" style="background:rgba(13,110,253,0.1);"><div class="small text-primary fw-bold">PASOS</div><div class="h5 mb-0">13</div></div></div>\n                        <div class="col-3"><div class="text-center p-2 rounded" style="background:rgba(25,135,84,0.1);"><div class="small text-success fw-bold">EVENTOS</div><div class="h5 mb-0" id="trace-events">--</div></div></div>\n                        <div class="col-3"><div class="text-center p-2 rounded" style="background:rgba(255,193,7,0.1);"><div class="small text-warning fw-bold">ACTIVOS</div><div class="h5 mb-0" id="trace-active">--</div></div></div>\n                        <div class="col-3"><div class="text-center p-2 rounded" style="background:rgba(25,135,84,0.1);"><div class="small text-success fw-bold">COMPLETADOS</div><div class="h5 mb-0" id="trace-done">--</div></div></div>\n                    </div>\n                </div>\n            </div>\n        </div>\n    </div>\n'
    new_d = d[:idx] + ins + d[idx:]
    open(path, 'w', encoding='utf-8').write(new_d)
    print("index.html: OK")
    return True

instrument_factory_yml()
instrument_deploy_yml()
update_index_html()
print("Done!")