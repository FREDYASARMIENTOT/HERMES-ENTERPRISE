"""FASE 21.1 — Audit Inventory Generator"""
import os, sys, json

BASE = r"d:\HERMES-ENTERPRISE"

def read_file(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    except:
        return ""

def has(text, *keywords):
    for k in keywords:
        if k.lower() in text.lower():
            return True
    return False

def find_functions(text):
    import re
    funcs = re.findall(r'(?:async\s+)?def\s+(\w+)\s*\(', text)
    return funcs

def audit_component(name, file_rel, content, checks):
    """Returns a dict with: component, estado, falta, archivo, funciones"""
    funcs = find_functions(content)
    issues = []
    for check_name, check_keywords in checks.items():
        if isinstance(check_keywords, str):
            check_keywords = [check_keywords]
        if not has(content, *check_keywords):
            issues.append(check_name)
    return {
        "COMPONENTE": name,
        "ARCHIVO": file_rel,
        "FUNCIONES": funcs[:10],  # top 10
        "FALTA": issues if issues else ["N/A - OK"],
        "ESTADO": "INCOMPLETO" if issues else "OK",
        "LINEAS": len(content.split('\n'))
    }

inventory = []

# 1) proyecto.html
proy = read_file(os.path.join(BASE, "Hermes.Web", "templates", "proyecto.html"))
inventory.append(audit_component("Portal UI (proyecto.html)", "Hermes.Web/templates/proyecto.html", proy, {
    "eventos": "eventos",
    "trace/json": "trace/json",
    "trace/md": "trace/md",
    "subpasos": "subpaso",
    "cargarEventos": "cargarEventos",
    "filtro eventos": "filtro",
    "polling inteligente": "polling",
    "log del proceso": "LOG DEL PROCESO",
    "Ver JSON": "Ver JSON",
    "Descargar JSON": "Descargar JSON",
    "timeline visual": "timeline",
    "indicador global": "13 / 13",
}))

# 2) index.html
index_html = read_file(os.path.join(BASE, "Hermes.Web", "templates", "index.html"))
inventory.append(audit_component("Portal Index UI", "Hermes.Web/templates/index.html", index_html, {
    "eventos": "eventos",
    "subpasos": "subpaso",
    "cargarEventos": "cargarEventos",
    "trace endpoints": "trace/json",
    "timeline": "Timeline",
}))

# 3) api_fabrica.py
api = read_file(os.path.join(BASE, "Hermes.Web", "api", "api_fabrica.py"))
inventory.append(audit_component("API Router", "Hermes.Web/api/api_fabrica.py", api, {
    "endpoint /eventos": "eventos",
    "endpoint /trace/json": "trace/json",
    "endpoint /trace/md": "trace/md",
    "endpoint actualizar_paso": "actualizar_paso",
    "endpoint finalizar": "finalizar",
}))

# 4) servicio_fabrica.py
svc = read_file(os.path.join(BASE, "Hermes.Web", "backend", "servicio_fabrica.py"))
inventory.append(audit_component("Servicio Fabrica", "Hermes.Web/backend/servicio_fabrica.py", svc, {
    "event_logs table": "event_logs",
    "registrar_evento": "_registrar_evento",
    "obtener_eventos": "obtener_eventos",
    "subpasos": "subpaso",
    "calcular_estado": "_calcular_estado_global",
    "validar_consistencia": "validar_consistencia",
    "PASOS_CANONICOS": "PASOS_CANONICOS",
}))

# 5) factory-run.yml
factory_yml = read_file(os.path.join(BASE, ".github", "workflows", "factory-run.yml"))
inventory.append(audit_component("Factory Workflow", ".github/workflows/factory-run.yml", factory_yml, {
    "TRACE_START events": "TRACE START",
    "TRACE_END events": "TRACE END",
    "event recording": "registrar_evento",
    "substep tracking": "substep",
    "callback HTTP": "/paso",
}))

# 6) deploy-child.yml
child_yml = read_file(os.path.join(BASE, ".github", "workflows", "deploy-child.yml"))
inventory.append(audit_component("Control Plane Workflow", ".github/workflows/deploy-child.yml", child_yml, {
    "register_paso function": "register_paso",
    "Paso 12 PUBLICACION": "PUBLICACIÓN",
    "Paso 13 NAVEGADOR": "NAVEGADOR",
    "TRACE_START events": "TRACE START",
    "TRACE_END events": "TRACE END",
    "callback /paso HTTP": "register_paso",
    "error callback on fail": "CALLBACK_FAILED",
}))

# 7) test_traceability.py
test_file = os.path.join(BASE, "Hermes.Web", "tests", "test_traceability.py")
if os.path.exists(test_file):
    test_content = read_file(test_file)
    test_funcs = find_functions(test_content)
    inventory.append({
        "COMPONENTE": "Tests Traceability",
        "ARCHIVO": "Hermes.Web/tests/test_traceability.py",
        "FUNCIONES": test_funcs,
        "FALTA": ["N/A - check test count"],
        "ESTADO": "OK" if test_content else "VACIO",
        "LINEAS": len(test_content.split('\n'))
    })
else:
    inventory.append({
        "COMPONENTE": "Tests Traceability",
        "ARCHIVO": "Hermes.Web/tests/test_traceability.py",
        "FUNCIONES": [],
        "FALTA": ["NO EXISTE"],
        "ESTADO": "INCOMPLETO",
        "LINEAS": 0
    })

print("=" * 80)
print("FASE 21.1 — AUDIT INVENTORY")
print("=" * 80)
for item in inventory:
    print(f"\n{'─' * 60}")
    print(f"COMPONENTE: {item['COMPONENTE']}")
    print(f"ARCHIVO: {item['ARCHIVO']}")
    print(f"ESTADO: {item['ESTADO']}")
    print(f"LINEAS: {item['LINEAS']}")
    falta = item.get('FALTA', [])
    if falta and falta != ["N/A - OK"]:
        print(f"FALTA: {', '.join(falta)}")
    else:
        print(f"FALTA: (ninguna)")
    if item.get('FUNCIONES'):
        print(f"FUNCIONES ({len(item['FUNCIONES'])}): {', '.join(item['FUNCIONES'][:8])}")

print("\n" + "=" * 80)
print("RESUMEN")
print("=" * 80)
ok = sum(1 for i in inventory if i['ESTADO'] == 'OK')
inc = sum(1 for i in inventory if i['ESTADO'] == 'INCOMPLETO')
print(f"OK: {ok}/{len(inventory)}")
print(f"INCOMPLETO: {inc}/{len(inventory)}")
for item in inventory:
    if item['ESTADO'] == 'INCOMPLETO':
        print(f"  - {item['COMPONENTE']}: falta {', '.join(item['FALTA'])}")