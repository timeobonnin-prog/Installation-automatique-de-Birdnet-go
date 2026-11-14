#!/usr/bin/env python3
import json
import os
import sys

RELEASES_FILE = 'releases.json'
TEMPLATE_FILE = 'index.html.template'
OUTPUT_FILE = 'index.html'

if not os.path.exists(RELEASES_FILE):
    sys.exit(1)

with open(RELEASES_FILE, 'r', encoding='utf-8') as f:
    releases = json.load(f)

# Garder uniquement tes builds (exclut les releases brutes officielles)
stable = [r for r in releases if r['tag_name'].startswith('v') and not r['tag_name'].startswith('nightly-v') and not r['tag_name'].startswith('manual-')]
nightly = [r for r in releases if r['tag_name'].startswith('nightly-v')]

stable.sort(key=lambda x: x.get('created_at', ''), reverse=True)
nightly.sort(key=lambda x: x.get('created_at', ''), reverse=True)

options = []
if stable:
    options.append(f'<option value="{stable[0]["tag_name"]}">Dernière stable ({stable[0]["tag_name"]})</option>')
if nightly:
    options.append(f'<option value="{nightly[0]["tag_name"]}">Dernière nightly ({nightly[0]["tag_name"]})</option>')

if not options:
    options.append('<option value="latest">Aucune version disponible</option>')

options_html = '\n            '.join(options)

with open(TEMPLATE_FILE, 'r', encoding='utf-8') as f:
    html = f.read()

html = html.replace('{{VERSION_OPTIONS}}', options_html)

with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    f.write(html)
