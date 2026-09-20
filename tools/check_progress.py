#!/usr/bin/env python3
"""Check the progress of the Factory Runner E2E."""
import requests, json, sys

BASE = 'https://as-hermesportal.azurewebsites.net'
did = sys.argv[1] if len(sys.argv) > 1 else 'D33A289C0F334E69'

r = requests.get(BASE + f'/api/fabrica/proyectos/{did}', timeout=10)
d = r.json()

print(f'Deployment ID: {did}')
print(f'Estado: {d.get("estado")}')
print(f'Resultado: {d.get("resultado")}')
print(f'Factory Run ID: {d.get("factory_run_id")}')
print(f'Factory Status: {d.get("factory_status")}')
print(f'Factory Run URL: {d.get("factory_run_url")}')
print(f'Repo: {d.get("repositorio")}')
print(f'SHA: {d.get("commit_sha")}')
print(f'Control Plane Run ID: {d.get("control_plane_run_id")}')
print()

pasos = d.get('pasos', [])
print(f'Pasos ({len(pasos)}):')
for p in pasos:
    detalle = p.get('detalle', '')[:200]
    print(f'  {p["numero"]:2d}. {p["nombre"]:20s} -> {p["estado"]:15s} | {detalle}')