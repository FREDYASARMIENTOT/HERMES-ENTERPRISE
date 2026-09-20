#!/usr/bin/env python3
"""Check the child repo's GitHub Actions status."""
import requests, json, sys

REPO = sys.argv[1] if len(sys.argv) > 1 else 'FREDYASARMIENTOT/hermes-hermes-fix-test-1789663736'

r = requests.get(f'https://api.github.com/repos/{REPO}/actions/runs',
                 headers={'Accept': 'application/vnd.github.v3+json'}, timeout=10)
d = r.json()
print(f'Child repo: {REPO}')
print(f'Total runs: {d.get("total_count", 0)}')
print()
for w in d.get('workflow_runs', [])[:5]:
    c = str(w.get('conclusion', ''))
    print(f'  Name:       {w["name"]}')
    print(f'  Status:     {w["status"]}')
    print(f'  Conclusion: {c}')
    print(f'  Created:    {w["created_at"][:19]}')
    print(f'  URL:        {w["html_url"]}')
    print()