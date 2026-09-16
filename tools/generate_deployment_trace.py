#!/usr/bin/env python3
"""
generate_deployment_trace.py - Genera deployment-trace.json (FASE 20.17)
=====================================================================
Hermes Enterprise Observability Hardening

Uso:
    python tools/generate_deployment_trace.py [--db <sqlite_path>] [--did <deployment_id>]

Salida: deployment-trace-{DID}.json
"""

import json, os, sys, sqlite3, argparse
from datetime import datetime


def calcular_duracion(inicio: str, fin: str) -> float:
    if not inicio or not fin:
        return 0.0
    try:
        i = datetime.fromisoformat(inicio.replace("Z", "+00:00"))
        f = datetime.fromisoformat(fin.replace("Z", "+00:00"))
        return round((f - i).total_seconds(), 2)
    except Exception:
        return 0.0


def generar_trace(proyecto: dict, pasos: list) -> dict:
    did = proyecto.get("deployment_id", "")
    duracion = calcular_duracion(
        proyecto.get("fecha_solicitud", ""),
        proyecto.get("fecha_fin", "")
    )
    steps = []
    for p in pasos:
        step = {
            "numero": p.get("numero_paso"),
            "nombre": p.get("nombre_paso"),
            "estado": p.get("estado_paso", "PENDIENTE"),
            "detalle": p.get("detalle", ""),
            "evidencia": p.get("evidencia", ""),
            "fecha_inicio": p.get("fecha_inicio") or "",
            "fecha_fin": p.get("fecha_fin") or "",
            "duracion_segundos": calcular_duracion(
                p.get("fecha_inicio", ""), p.get("fecha_fin", "")
            ),
            "resultado": p.get("resultado", ""),
            "subpasos": json.loads(p.get("subpasos_json", "[]")) if p.get("subpasos_json") else []
        }
        steps.append(step)

    estados = [s["estado"] for s in steps]
    if any(e == "FALLIDO" for e in estados):
        estado_global = "FALLIDO"
    elif any(e in ("PENDIENTE", "EN_PROCESO") for e in estados):
        estado_global = "EN_PROCESO"
    elif all(e == "COMPLETADO" for e in estados):
        estado_global = "COMPLETADO"
    else:
        estado_global = proyecto.get("estado", "DESCONOCIDO")

    resultado_global = proyecto.get("resultado", "")
    if resultado_global == "PASS" and estado_global != "COMPLETADO":
        resultado_global = "FAIL"

    trace = {
        "schema_version": "1.0",
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "generator": "generate_deployment_trace.py FASE 20.17",
        "project": {
            "name": proyecto.get("nombre_proyecto", ""),
            "deployment_id": did,
            "correlation_id": proyecto.get("correlation_id", ""),
            "app_service_plan_id": proyecto.get("app_service_plan_id", ""),
            "app_service_plan_name": proyecto.get("app_service_plan_name", ""),
        },
        "result": {
            "global": resultado_global,
            "state": estado_global,
            "started_at": proyecto.get("fecha_solicitud", ""),
            "finished_at": proyecto.get("fecha_fin", ""),
            "duration_seconds": duracion,
            "duration_human": f"{int(duracion // 60)}m {int(duracion % 60)}s" if duracion > 0 else ""
        },
        "github": {
            "repository_url": proyecto.get("repository_url", ""),
            "commit_url": proyecto.get("commit_url", ""),
            "commit_sha": proyecto.get("commit_sha", ""),
            "visibility": proyecto.get("visibility", ""),
            "factory_run_id": proyecto.get("factory_run_id", ""),
            "factory_run_url": proyecto.get("factory_run_url", ""),
            "factory_status": proyecto.get("factory_status", ""),
            "control_plane_run_id": proyecto.get("control_plane_run_id", ""),
            "control_plane_run_url": proyecto.get("control_plane_run_url", ""),
            "control_plane_status": proyecto.get("control_plane_status", "")
        },
        "azure": {
            "web_app": proyecto.get("web_app", ""),
            "web_app_url": proyecto.get("web_app_url", ""),
            "web_app_resource_id": proyecto.get("web_app_resource_id", ""),
        },
        "validation": {
            "readiness_result": proyecto.get("readiness_result", ""),
            "functional_result": proyecto.get("functional_result", ""),
            "functional_pass_count": proyecto.get("functional_pass_count", 0),
            "functional_fail_count": proyecto.get("functional_fail_count", 0),
            "user_facing_result": proyecto.get("user_facing_result", ""),
            "evidence_result": proyecto.get("evidence_result", "")
        },
        "steps": steps,
        "events": []
    }

    # Poblar eventos desde pasos
    for s in steps:
        if s["fecha_inicio"]:
            trace["events"].append({
                "event_type": "STEP_START",
                "timestamp": s["fecha_inicio"],
                "paso": s["numero"],
                "nombre": s["nombre"],
                "estado": "EN_PROCESO"
            })
        if s["fecha_fin"]:
            trace["events"].append({
                "event_type": "STEP_END",
                "timestamp": s["fecha_fin"],
                "paso": s["numero"],
                "nombre": s["nombre"],
                "estado": s["estado"],
                "duracion_segundos": s["duracion_segundos"]
            })
    return trace


def main():
    parser = argparse.ArgumentParser(description="Genera deployment-trace.json")
    parser.add_argument("--db", default=None)
    parser.add_argument("--did", default=None, help="Deployment ID")
    parser.add_argument("--output", default=None, help="Ruta de salida")
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

    trace = generar_trace(proyecto, pasos)

    output = args.output or f"deployment-trace-{did}.json"
    with open(output, "w", encoding="utf-8") as f:
        json.dump(trace, f, indent=2, ensure_ascii=False)

    print(f"deployment-trace.json generado: {output}")
    print(f"  Proyecto:     {proyecto['nombre_proyecto']}")
    print(f"  Deployment:   {did}")
    print(f"  Estado:       {trace['result']['state']}")
    print(f"  Resultado:    {trace['result']['global']}")
    print(f"  Duracion:     {trace['result']['duration_human']}")
    print(f"  Pasos:        {len(trace['steps'])}")
    print(f"  Eventos:      {len(trace['events'])}")

    if trace["result"]["global"] == "PASS":
        pendientes = [s for s in trace["steps"] if s["estado"] in ("PENDIENTE", "EN_PROCESO")]
        if pendientes:
            print(f"\n  WARNING: PASS con pasos pendientes!")
            for p in pendientes:
                print(f"    Paso {p['numero']} {p['nombre']}: {p['estado']}")
            trace["result"]["global"] = "FAIL"


if __name__ == "__main__":
    main()