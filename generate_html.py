#!/usr/bin/env python3
import json
import os
import sys
import re

RELEASES_FILE = 'releases.json'
TEMPLATE_FILE = 'index.html.template'
OUTPUT_FILE = 'index.html'

if not os.path.exists(RELEASES_FILE):
    sys.exit(1)

with open(RELEASES_FILE, 'r', encoding='utf-8') as f:
    releases = json.load(f)

# Filtrage STRICT :
# - Stable : commence par 'v' et suivi de chiffres (ex: v20261031.37)
# - Nightly : commence par 'nightly-v' (ex: nightly-v20260615.24)
stable_releases = [
    r for r in releases 
    if re.match(r'^v\d+\.\d+$', r['tag_name']) and not r.get('prerelease') and not r.get('draft')
]
nightly_releases = [
    r for r in releases 
    if re.match(r'^nightly-v\d+\.\d+$', r['tag_name']) and not r.get('draft')
]

# Tri par date (le plus récent en premier)
stable_releases.sort(key=lambda x: x.get('created_at', ''), reverse=True)
nightly_releases.sort(key=lambda x: x.get('created_at', ''), reverse=True)

# Création du menu déroulant
options = []
if stable_releases:
    options.append(f'<option value="{stable_releases[0]["tag_name"]}">Dernière stable ({stable_releases[0]["tag_name"]})</option>')
if nightly_releases:
    options.append(f'<option value="{nightly_releases[0]["tag_name"]}">Dernière nightly ({nightly_releases[0]["tag_name"]})</option>')

if not options:
    options.append('<option value="latest">Aucune version disponible</option>')

options_html = '\n            '.join(options)

# Remplacement dans le template
with open(TEMPLATE_FILE, 'r', encoding='utf-8') as f:
    html = f.read()

html = html.replace('{{VERSION_OPTIONS}}', options_html)

with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    f.write(html)

print(f"✅ {OUTPUT_FILE} généré avec succès ({len(stable_releases)} stable, {len(nightly_releases)} nightly)")
