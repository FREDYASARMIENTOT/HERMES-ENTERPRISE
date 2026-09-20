"""Post-deploy smoke tests for Hermes Portal — full battery"""
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

def check_content(label, text, marker):
    global PASS, FAIL
    if marker in text:
        PASS += 1
        print(f"  PASS {label}: found '{marker}'")
    else:
        FAIL += 1
        print(f"  FAIL {label}: missing '{marker}'")

print("=== HERMES PORTAL SMOKE TEST ===")
print()

# --- HTTP status checks ---
check("GET /", requests.get(f"{BASE}/", timeout=30))
check("GET /health", requests.get(f"{BASE}/health", timeout=30))
check("GET /openapi.json", requests.get(f"{BASE}/openapi.json", timeout=30))
check("GET /swagger", requests.get(f"{BASE}/swagger", timeout=30))
check("GET /proyectos", requests.get(f"{BASE}/proyectos", timeout=30))
check("GET /api/fabrica/proyectos", requests.get(f"{BASE}/api/fabrica/proyectos", timeout=30))

# --- Content validation (no project creation) ---
print()
print("--- [Content Validation] ---")
root_html = requests.get(f"{BASE}/", timeout=30).text
check_content("Root: Fabrica de Proyectos UR", root_html, "Fábrica de Proyectos UR")
check_content("Root: Fabrica de Proyectos", root_html, "Fábrica de Proyectos")
check_content("Root: project input", root_html, "nuevo-proyecto-input")
check_content("Root: create button", root_html, "crear-proyecto-btn")
check_content("Root: health section", root_html, "Health Check")
check_content("Root: metrics section", root_html, "Métricas de Rendimiento")
check_content("Root: swagger link", root_html, "/swagger")

# --- Security: no secrets in HTML ---
print()
print("--- [Security Check] ---")
SECRET_PATTERNS = [
    "GH_PORTAL_HERMES_REPO_WRITE_TOKEN",
    "HERMES_GITHUB_TOKEN",
    "AZURE_CLIENT_SECRET",
    "client_secret",
]
no_secrets = True
for pat in SECRET_PATTERNS:
    if pat in root_html:
        no_secrets = False
        FAIL += 1
        print(f"  FAIL Security: secret pattern '{pat}' exposed in HTML!")
if no_secrets:
    PASS += 1
    print("  PASS Security: no secret values in frontend")

# --- OpenAPI paths ---
print()
print("--- [OpenAPI] ---")
spec = requests.get(f"{BASE}/openapi.json", timeout=30).json()
paths = spec.get("paths", {})
api_paths_ok = (
    "/" in paths
    and "/health" in paths
    and "/api/fabrica/proyectos" in paths
)
if api_paths_ok:
    PASS += 1
    print("  PASS OpenAPI: factory endpoints registered")
else:
    FAIL += 1
    print("  FAIL OpenAPI: missing factory endpoints")

print()
print(f"=== RESULT: {PASS} passed, {FAIL} failed ===")
print("HERMES PORTAL " + ("PASSED" if FAIL == 0 else "FAILED"))