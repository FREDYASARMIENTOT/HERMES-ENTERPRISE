"""Post-deploy smoke tests for Hermes Portal"""
import requests

BASE = "https://as-hermesportal.azurewebsites.net"
PASS = 0
FAIL = 0

def check(label, r):
    global PASS, FAIL
    if r.status_code in (200, 202):
        PASS += 1
        print(f"  PASS {label}: {r.status_code}")
    else:
        FAIL += 1
        print(f"  FAIL {label}: {r.status_code} - {r.text[:200]}")

print("=== POST-DEPLOY SMOKE TESTS ===")
print()

check("GET /", requests.get(f"{BASE}/", timeout=30))
check("GET /health", requests.get(f"{BASE}/health", timeout=30))
check("GET /openapi.json", requests.get(f"{BASE}/openapi.json", timeout=30))
check("GET /swagger", requests.get(f"{BASE}/swagger", timeout=30))
check("GET /proyectos", requests.get(f"{BASE}/proyectos", timeout=30))
check("GET /api/fabrica/proyectos", requests.get(f"{BASE}/api/fabrica/proyectos", timeout=30))

r = requests.post(f"{BASE}/api/fabrica/proyectos",
                  json={"nombre_proyecto": "hermes-smoke-001"},
                  timeout=30)
check("POST /api/fabrica/proyectos", r)
if r.status_code == 202:
    d = r.json()
    did = d.get("deployment_id", "?")
    print(f"    Deployment ID: {did}")
    print(f"    Estado: {d.get('estado', '?')}")
    print(f"    Mensaje: {d.get('mensaje', '?')}")

    # Test GET by deployment_id
    r2 = requests.get(f"{BASE}/api/fabrica/proyectos/{did}", timeout=30)
    check(f"GET /api/fabrica/proyectos/{did}", r2)

    # Test POST actualizar paso
    r3 = requests.post(f"{BASE}/api/fabrica/proyectos/{did}/paso",
                       json={"numero_paso": 2, "estado_paso": "EN_PROCESO"},
                       timeout=30)
    check(f"POST /paso ({did})", r3)

print()
print(f"=== RESULT: {PASS} passed, {FAIL} failed ===")
print("SMOKE TESTS " + ("PASSED" if FAIL == 0 else "FAILED"))