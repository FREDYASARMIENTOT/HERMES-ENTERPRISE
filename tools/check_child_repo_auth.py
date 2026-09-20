#!/usr/bin/env python3
"""Check child repo with auth."""
import requests, json, sys

TOKEN = 'ghp_r5dK7VgLy5s31HVn6EmcQjT6TaktzQ2YfzWL'
REPO = sys.argv[1] if len(sys.argv) > 1 else 'FREDYASARMIENTOT/hermes-fix-test-1789663736'
HEADERS = {'Authorization': f'token {TOKEN}', 'Accept': 'application/vnd.github.v3+json'}

print(f'Checking repo: {REPO}')
r = requests.get(f'https://api.github.com/repos/{REPO}', headers=HEADERS, timeout=10)
print(f'Status: {r.status_code}')
if r.status_code == 200:
    d = r.json()
    print(f'Full name: {d["full_name"]}')
    print(f'Private: {d.get("private")}')
    print(f'Default branch: {d.get("default_branch")}')
    
    # Check CI runs
    r2 = requests.get(f'https://api.github.com/repos/{REPO}/actions/runs', headers=HEADERS, timeout=10)
    if r2.status_code == 200:
        d2 = r2.json()
        print(f'\nWorkflow runs ({d2.get("total_count", 0)}):')
        for w in d2.get('workflow_runs', [])[:5]:
            c = str(w.get('conclusion', ''))
            print(f'  Name: {w["name"]}')
            print(f'  Status: {w["status"]}')
            print(f'  Conclusion: {c}')
            print(f'  URL: {w["html_url"]}')
            print()
    else:
        print(f'No actions data: {r2.status_code} {r2.text[:200]}')
else:
    print(r.text[:500])