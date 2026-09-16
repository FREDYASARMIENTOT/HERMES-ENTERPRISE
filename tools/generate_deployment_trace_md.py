#!/usr/bin/env python3
"""
generate_deployment_trace_md.py - Genera deployment-trace.md (FASE 20.18)
=====================================================================
Hermes Enterprise Observability Hardening

Uso:
    python tools/generate_deployment_trace_md.py [--db <sqlite>] [--did <deployment_id>]

Salida: deployment-trace-{DID}.md
"""

import json, os, sys, sqlite3, argparse
from datetime import datetime


def calc_dur(inicio: str, fin: str) -> float:
    if not inicio or not fin:
        return 0.0
    try:
        i = datetime.fromisoformat(inicio.replace("Z", "+00:00"))
        f = datetime.fromisoformat(fin.replace("Z", "+00:00"))
        return round((f - i).total_seconds(), 2)
    except Exception:
        return 0.0


def dur_hum(seg: float) -> str:
    if seg <= 0:
        return "-"
    m, s = divmod(int(seg), 60)
    return f"{m}m {s}s" if m else f"{s}s"


def generar_md(proyecto: dict, pasos: list) -> str:
    did = proyecto.get("deployment_id", "")
    cid = proyecto.get("correlation_id", "")
    nombre = proyecto.get("nombre_proyecto", "")
    estado = proyecto.get("estado", "")
    resultado = proyecto.get("resultado", "")
    dur = calc_dur(proyecto.get("fecha_solicitud", ""), proyecto.get("fecha_fin", ""))

    lines = []
    lines.append(f"# Deployment Trace {nombre}")
    lines.append(f"")
    lines.append(f"**Deployment ID**: `{did}`  ")
    lines.append(f"**Correlation ID**: `{cid}`  ")
    lines.append(f"**Estado**: {estado}  ")
# GitHub section
    lines.append(f"---")
    lines.append(f"## GitHub")
    lines.append(f"")
    lines.append(f"| Recurso | URL / ID |")
    lines.append(f"|---------|----------|")
    if proyecto.get("repository_url"):
        lines.append(f"| Repository | [{proyecto['repository_url']}]({proyecto['repository_url']}) |")
    if proyecto.get("commit_url"):
        lines.append(f"| Commit | [{proyecto.get('commit_sha','')[:12]}...]({proyecto['commit_url']}) |")
    if proyecto.get("factory_run_url"):
        lines.append(f"| Factory Run | [{proyecto['factory_run_id']}]({proyecto['factory_run_url']}) |")
    if proyecto.get("control_plane_run_url"):
        lines.append(f"| Control Plane | [{proyecto['control_plane_run_id']}]({proyecto['control_plane_run_url']}) |")
    lines.append(f"")

    # Azure
    lines.append(f"---")
    lines.append(f"## Azure")
    lines.append(f"")
    lines.append(f"| Recurso | Valor |")
    lines.append(f"|---------|-------|")
    lines.append(f"| Web App | {proyecto.get('web_app','-')} |")
    if proyecto.get("web_app_url"):
        lines.append(f"| URL | [{proyecto['web_app_url']}]({proyecto['web_app_url']}) |")
    lines.append(f"| Plan | {proyecto.get('app_service_plan_name','-')} |")
    lines.append(f"")

    # Validation
    lines.append(f"---")
    lines.append(f"## Validacion")
    lines.append(f"")
    lines.append(f"| Prueba | Resultado |")
    lines.append(f"|--------|-----------|")
    lines.append(f"| Readiness | {proyecto.get('readiness_result','-')} |")
    lines.append(f"| Functional | {proyecto.get('functional_result','-')} |")
    lines.append(f"| Pass | {proyecto.get('functional_pass_count',0)} |")
    lines.append(f"| Fail | {proyecto.get('functional_fail_count',0)} |")
    lines.append(f"| Evidence | {proyecto.get('evidence_result','-')} |")
    lines.append(f"")

    # Steps detalle
    lines.append(f"---")
    lines.append(f"## Detalle de Pasos")
    lines.append(f"")
    for p in pasos:
        num = p.get("numero_paso", "?")
        nom = p.get("nombre_paso", "")
        est = p.get("estado_paso", "PENDIENTE")
        ini = p.get("fecha_inicio", "") or "-"
        fin = p.get("fecha_fin", "") or "-"
        det = p.get("detalle", "") or "-"
        evi = p.get("evidencia", "") or "-"
        pdur = calc_dur(p.get("fecha_inicio", ""), p.get("fecha_fin", ""))
        lines.append(f"### Paso {num}: {nom}")
        lines.append(f"")
        lines.append(f"- **Estado**: {est}")
        lines.append(f"- **Inicio**: {ini}")
        lines.append(f"- **Fin**: {fin}")
        lines.append(f"- **Duracion**: {dur_hum(pdur)}")
        lines.append(f"- **Detalle**: {det}")
        lines.append(f"- **Evidencia**: {evi}")
        lines.append(f"")

        sp_json = p.get("subpasos_json") or "[]"
        try:
            subpasos = json.loads(sp_json) if isinstance(sp_json, str) else sp_json
        except Exception:
            subpasos = []
        if subpasos:
            lines.append(f"#### Subpasos")
            lines.append(f"")
            lines.append(f"| # | Nombre | Estado |")
            lines.append(f"|---|--------|--------|")
            for sp in subpasos:
                sn = sp.get("numero_subpaso", "")
                snm = sp.get("nombre_subpaso", "")
                se = sp.get("estado", "")
                lines.append(f"| {sn} | {snm} | {se} |")
            lines.append(f"")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Genera deployment-trace.md")
    parser.add_argument("--db", default=None)
    parser.add_argument("--did", default=None)
    parser.add_argument("--output", default=None)
    args = parser.parse_args()

    db_path = args.db or os.environ.get("HERMES_DB_PATH", "Hermes.Web/data/proyecto.db")
    if not os.path.exists(db_path):
        print(f"ERROR: BD no encontrada: {db_path}")
        sys.exit(1)

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()

    if args.did:
        c.execute("SELECT * FROM solicitudes_proyecto WHERE deployment_id=?", (args.did,))
    else:
        c.execute("SELECT * FROM solicitudes_proyecto ORDER BY fecha_solicitud DESC LIMIT 1")
    row = c.fetchone()
    if not row:
        print("ERROR: Proyecto no encontrado")
        sys.exit(1)
    proyecto = dict(row)
    did = proyecto["deployment_id"]
    c.execute("SELECT * FROM pasos_proyecto WHERE deployment_id=? ORDER BY numero_paso", (did,))
    pasos = [dict(r) for r in c.fetchall()]
    conn.close()

    md = generar_md(proyecto, pasos)
    output = args.output or f"deployment-trace-{did}.md"
    with open(output, "w", encoding="utf-8") as f:
        f.write(md)
    print(f"deployment-trace.md generado: {output}")


    lines.append(f"**Resultado**: {resultado}  ")
    lines.append(f"**Duracion**: {dur_hum(dur)}  ")
    lines.append(f"**Generado**: {datetime.utcnow().isoformat()}Z  ")
    lines.append(f"")

    # Timeline
    lines.append(f"---")
    lines.append(f"## Timeline")
    lines.append(f"")
    lines.append(f"| Paso | Estado | Duracion | Detalle |")
    lines.append(f"|------|--------|----------|---------|")
    for p in pasos:
        num = p.get("numero_paso", "?")
        nom = p.get("nombre_paso", "")
        est = p.get("estado_paso", "PENDIENTE")
        det = (p.get("detalle", "") or "")[:60]
        pdur = calc_dur(p.get("fecha_inicio", ""), p.get("fecha_fin", ""))
        icon = {"COMPLETADO": "✅", "FALLIDO": "❌", "EN_PROCESO": "⏳", "PENDIENTE": "⬜"}
        lines.append(f"| {icon.get(est,'')} **{num}** {nom} | {est} | {dur_hum(pdur)} | {det} |")


if __name__ == "__main__":
    main()