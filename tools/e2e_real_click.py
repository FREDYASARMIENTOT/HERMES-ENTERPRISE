#!/usr/bin/env python3
import json, os, sys, time, traceback, pathlib, requests
from datetime import datetime

PORTAL_URL = "https://as-hermesportal.azurewebsites.net"
RESULTS = {}
ERROR_LOG = [] 
def log_error(msg): ERROR_LOG.append(msg); print(f"  [ERROR] {msg}")
def log_pass(msg): print(f"  [PASS] {msg}")
def log_info(msg): print(f"  [INFO] {msg}")

def launch_browser():
    from playwright.sync_api import sync_playwright
    pw = sync_playwright().start()
    u = pathlib.Path.home() / "AppData" / "Local" / "ms-playwright" / "chromium-1161" / "chrome-win" / "chrome.exe"
    b = pw.chromium.launch(executable_path=str(u), headless=True)
    c = b.new_context(viewport={"width":1280,"height":900})
    return pw, b, c, c.new_page()

def check_health():
    ok = True
    for ep in ["/","/health","/openapi.json"]:
        try:
            r = requests.get(f"{PORTAL_URL}{ep}", timeout=10)
            if r.status_code==200: log_pass(f"HTTP {ep} -> 200")
            else: log_error(f"HTTP {ep} -> {r.status_code}"); ok=False
        except Exception as e: log_error(f"HTTP {ep} -> {e}"); ok=False
    return ok

def check_plans():
    try:
        r = requests.get(f"{PORTAL_URL}/api/fabrica/app-service-plans", timeout=10)
        d = r.json()
        if d.get("exito"):
            ps = d.get("planes",[])
            log_pass(f"Plans: {len(ps)}")
            for p in ps:
                if p.get("resource_group")!="RG-Hermes-Proyectos":
                    log_error(f"Wrong RG: {p.get('resource_group')}"); return False, ps
            return True, ps
        log_error(f"Plans fail: {d}"); return False, []
    except Exception as e: log_error(f"Plans: {e}"); return False, []

def check_main_page(page):
    """Check main page has crearProyecto function and plans loaded"""
    ok=True; h=page.content()
    checks = [
        ("crearProyecto", "crearProyecto" in h),
        ("No polling (main)", "iniciarPolling" not in h),
        ("Plans select", "app-service-plan-select" in h),
    ]
    for n,c in checks:
        if c: log_pass(f"  {n}")
        else: log_error(f"  {n} MISSING"); ok=False
    return ok

def create_project(page, plans):
    pn = f"hermes-final-e2e-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    log_info(f"\nProject: {pn}")
    page.goto(PORTAL_URL, wait_until="networkidle", timeout=30000)
    # Wait for button to be enabled (plans loaded)
    btn = page.locator("#crear-proyecto-btn")
    try:
        btn.wait_for(state="visible", timeout=10000)
        page.wait_for_function("() => !document.getElementById('crear-proyecto-btn').disabled", timeout=15000)
    except Exception as e:
        log_error(f"Button never enabled: {e}")
        return False,None,None,pn
    pi = page.locator("#nuevo-proyecto-input")
    if pi.count()==0: log_error("No input"); return False,None,None,pn
    ps = page.locator("#app-service-plan-select")
    if ps.count()==0: log_error("No select"); return False,None,None,pn
    pi.first.fill(pn)
    log_pass(f"Name: {pn}")
    tv = None
    for p in plans:
        if p["name"]=="ASP-HERMES-PORTAL": tv=p["id"]; break
    if tv:
        ps.select_option(tv)
        log_pass("Selected ASP-HERMES-PORTAL")
    else: log_error("ASP-HERMES-PORTAL not found"); return False,None,None,pn
    log_info("CLICK REAL on Crear Proyecto...")
    with page.expect_response(lambda r: r.request.method=="POST" and "/api/fabrica/proyectos" in r.url, timeout=30000) as ri:
        btn.first.click()
    resp = ri.value
    log_info(f"POST: HTTP {resp.status}")
    if resp.status!=202: log_error(f"Expected 202, got {resp.status}"); return False,None,None,pn
    log_pass("HTTP 202")
    try:
        d=resp.json(); did=d.get("deployment_id"); cid=d.get("correlation_id")
        log_pass(f"deployment_id: {did}"); log_pass(f"correlation_id: {cid}")
        return True,did,cid,pn
    except Exception as e: log_error(f"JSON: {e}"); return False,None,None,pn

def wait_poll(did, mm=15):
    log_info(f"\nPolling (max {mm}min)")
    start=time.time(); end=start+mm*60
    while time.time()<end:
        try:
            r=requests.get(f"{PORTAL_URL}/api/fabrica/proyectos/{did}", timeout=10)
            if r.status_code==200:
                d=r.json(); s=d.get("estado","")
                if s in ("COMPLETADO","FAILED","CANCELED"):
                    log_info(f"Done: {s} ({time.time()-start:.0f}s)"); return d
                ps=d.get("pasos",[]); c=sum(1 for p in ps if p.get("estado_paso")=="COMPLETADO")
                log_info(f"  {s}: {c}/{len(ps)} pasos")
        except: pass
        time.sleep(30)
    log_error(f"Timeout {mm}min")
    try: return requests.get(f"{PORTAL_URL}/api/fabrica/proyectos/{did}", timeout=10).json()
    except: return None

def check_protected():
    ok=True
    try:
        r=requests.get(f"{PORTAL_URL}/api/fabrica/app-service-plans", timeout=10)
        ns=[p["name"] for p in r.json().get("planes",[])]
        for a in ["ASP-HERMES-PORTAL","ASP-IAUR"]:
            if a in ns: log_pass(f"{a}: NO MODIFICADO")
            else: log_error(f"{a}: NOT FOUND"); ok=False
    except Exception as e: log_error(f"Protected: {e}"); ok=False
    return ok

def gen_evidence(did, cid, pd, st, et, pn):
    log_info("Generating evidence...")
    ed=pathlib.Path(f"evidence/e2e/{did or 'unknown'}"); ed.mkdir(parents=True, exist_ok=True)
    ps=(pd or {}).get("pasos",[])
    pm={p.get("numero_paso"):{"n":p.get("nombre_paso"),"e":p.get("estado_paso")} for p in ps}
    ac=all(p.get("estado_paso")=="COMPLETADO" for p in ps if p.get("numero_paso",0)<=13)
    e2e="PASS" if ac else "FAIL"
    rpt={"e2e_result":e2e,"project_name":pn,"deployment_id":did,"correlation_id":cid,
         "portal":PORTAL_URL,"pasos":pm,"errors":ERROR_LOG}
    (ed/"e2e-report.json").write_text(json.dumps(rpt, indent=2), encoding="utf-8")
    log_pass(f"Evidence: {ed}/e2e-report.json")

def main():
    print(f"\n{'='*70}"); st=datetime.now()
    print(f"HERMES-ENTERPRISE E2E FINAL - {st}"); print(f"{'='*70}")
    pw=b=c=page=None; did=cid=pn=None; pd=None
    try:
        RESULTS["health"]=check_health()
        RESULTS["plans_ok"],plans=check_plans()
        pw,b,c,page=launch_browser(); page.goto(PORTAL_URL, wait_until="networkidle", timeout=30000)
        RESULTS["sse_html"]=check_main_page(page)
        RESULTS["click_ok"],did,cid,pn=create_project(page,plans)
        RESULTS["http_202"]=RESULTS["click_ok"]
        if RESULTS["click_ok"] and did:
            pd=wait_poll(did, mm=15)
            check_protected()
        else: log_error("Creation failed")
        if page: page.close()
        if b: b.close()
        if pw: pw.stop()
    except Exception as e:
        log_error(f"EXCEPTION: {e}"); traceback.print_exc()
        if page:
            try: page.screenshot(path="error_screenshot.png"); log_info("Screenshot saved")
            except: pass
        if pw:
            try: pw.stop()
            except: pass
    et=datetime.now()
    gen_evidence(did,cid,pd,st,et,pn or "unknown")
    print(f"\n{'='*70}"); print(f"E2E COMPLETE - {et}"); print(f"{'='*70}")

if __name__=="__main__":
    main()