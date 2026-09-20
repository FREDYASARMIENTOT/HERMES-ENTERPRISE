"""Validate deployed portal HTML for SSE and crearProyecto"""
import urllib.request
import re

BASE = 'https://as-hermesportal.azurewebsites.net'

# Main page
r = urllib.request.urlopen(BASE + '/', timeout=15)
html = r.read().decode('utf-8', errors='replace')

print("=== MAIN PAGE ===")
print(f"crearProyecto: {'crearProyecto' in html}")
print(f"EventSource: {'EventSource' in html}")
print(f"conectarSSE: {'conectarSSE' in html}")
print(f"/eventos/stream: {'/eventos/stream' in html}")

# Look for external scripts
scripts = re.findall(r'<script[^>]*src="([^"]+)"', html)
print(f"External scripts: {scripts}")

# Look for project links
links = re.findall(r'href="([^"]*proyect[^"]*)"', html)
print(f"Project links: {links[:10]}")

print("\n=== DONE ===")