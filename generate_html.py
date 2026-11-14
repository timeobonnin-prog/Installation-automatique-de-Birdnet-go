#!/usr/bin/env python3
"""Génère index.html à partir des releases du dépôt."""
import json
import os
import sys

RELEASES_FILE = 'releases.json'
TEMPLATE_FILE = 'index.html.template'
OUTPUT_FILE = 'index.html'

if not os.path.exists(RELEASES_FILE):
    print(f"Erreur : {RELEASES_FILE} introuvable", file=sys.stderr)
    sys.exit(1)

with open(RELEASES_FILE, 'r', encoding='utf-8') as f:
    releases = json.load(f)

stable = [r for r in releases if not r.get('prerelease') and not r.get('draft')]
nightly = [r for r in releases if r.get('prerelease') and not r.get('draft')]

stable.sort(key=lambda x: x.get('created_at', ''), reverse=True)
nightly.sort(key=lambda x: x.get('created_at', ''), reverse=True)

# Construire les options du <select>
options = []
if stable:
    options.append(f'<option value="latest">Dernière stable ({stable[0]["tag_name"]})</option>')
for r in stable[:5]:
    options.append(f'<option value="{r["tag_name"]}">{r["tag_name"]} (stable)</option>')
for r in nightly[:3]:
    options.append(f'<option value="{r["tag_name"]}">{r["tag_name"]} (nightly)</option>')

options_html = '\n            '.join(options) if options else '<option value="latest">Aucune release disponible</option>'

# Charger le template
if not os.path.exists(TEMPLATE_FILE):
    print(f"Erreur : {TEMPLATE_FILE} introuvable", file=sys.stderr)
    sys.exit(1)

with open(TEMPLATE_FILE, 'r', encoding='utf-8') as f:
    html = f.read()

# Remplacer le placeholder
html = html.replace('{{VERSION_OPTIONS}}', options_html)

# Écrire
with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    f.write(html)

print(f"✅ {OUTPUT_FILE} généré ({len(stable)} stable, {len(nightly)} nightly)")
