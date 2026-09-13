#!/usr/bin/env python3
"""RC94.40: Portal HTTP endpoint validator - ONE SHOT, no loops."""
import urllib.request
import sys

BASE = 'https://as-hermesportal.azurewebsites.net'
ENDPOINTS = [
    ('/', 'GET'),
    ('/health', 'GET'),
    ('/openapi.json', 'GET'),
    ('/swagger', 'GET'),
    ('/proyectos', 'GET'),
]

results = {}
for path, method in ENDPOINTS:
    url = BASE + path
    try:
        req = urllib.request.Request(url, method=method)
        req.add_header('User-Agent', 'RC94.40-Validator')
        resp = urllib.request.urlopen(req, timeout=15)
        body = resp.read()
        results[path] = {
            'status': resp.status,
            'len': len(body),
            'type': resp.headers.get('Content-Type', ''),
        }
        if path == '/':
            results[path]['html_preview'] = body[:500].decode('utf-8', errors='replace')
    except Exception as e:
        results[path] = {'status': 'ERROR', 'error': str(e)[:200]}

print("=" * 60)
print("PORTAL HTTP VALIDATION")
print("=" * 60)
all_ok = True
for path, r in results.items():
    status = r['status']
    ok = status == 200
    if not ok:
        all_ok = False
    icon = "PASS" if ok else "FAIL"
    print(f"  {icon}  {path:25s}  HTTP {status}")
    if 'error' in r:
        print(f"       ERROR: {r['error']}")
    if 'html_preview' in r:
        print(f"       HTML preview (first 500 chars):")
        print(f"       {r['html_preview'][:500]}")

print()
print(f"Overall: {'ALL PASS' if all_ok else 'SOME FAILED'}")
sys.exit(0 if all_ok else 1)