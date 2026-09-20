#!/usr/bin/env python3
"""List child repos by user."""
import requests, json

r = requests.get('https://api.github.com/users/FREDYASARMIENTOT/repos?per_page=50&sort=created', timeout=10)
d = r.json()
print(f'Total repos returned: {len(d)}')
print()
for repo in d[:20]:
    name = repo['name']
    private = repo.get('private', '')
    url = repo['html_url']
    print(f'{name:60s} private={private}  {url}')