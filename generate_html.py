#!/usr/bin/env python3
"""Génère index.html à partir des releases du dépôt.
Garde UNIQUEMENT la release de build la plus récente (manual-v* ou v*)."""
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

# Filtrer uniquement les releases de type "manual-v*" ou "v*" (compilations)
build_releases = [
    r for r in releases
    if not r.get('draft')
    and (r['tag_name'].startswith('manual-v') or r['tag_name'].startswith('v'))
]

# Trier par date de création (la plus récente d'abord)
build_releases.sort(key=lambda x: x.get('created_at', ''), reverse=True)

# Construire les options du <select> : UNE SEULE option (la plus récente)
options = []
if build_releases:
    latest = build_releases[0]
    options.append(f'<option value="{latest["tag_name"]}">{latest["tag_name"]}</option>')
else:
    options.append('<option value="latest">Aucune version disponible</option>')

options_html = '\n            '.join(options)

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

print(f"OK : {OUTPUT_FILE} genere avec {len(build_releases)} release(s) de build.")
