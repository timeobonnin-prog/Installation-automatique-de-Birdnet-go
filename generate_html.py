#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# ⚠️ IMPORTANT : NE PAS FORMATER CE FICHIER (Prettier, Black, etc.)
# Ce script utilise des marqueurs __XXX__ et du CSS/JS brut.
# Tout formatage automatique risque de casser la génération de la page HTML.
# Assurez-vous que ce fichier est listé dans .prettierignore.
# ==============================================================================
"""
Génère index.html (GitHub Pages) et update.json (canal de MAJ statique).
Utilise .replace() au lieu de .format() pour être 100% immunisé contre 
les formateurs de code qui mangent les accolades.
"""

import json
import os
import re
import html
import sys
from datetime import datetime, timezone

RELEASES_FILE = "releases.json"
OUT_HTML = "index.html"
OUT_JSON = "update.json"
REPO = "timeobonnin-prog/Installation-automatique-de-Birdnet-go"
UPSTREAM = "tphakala/birdnet-go"

ASSET_MAP = {
    "windows":     ("BirdNET-Go-Windows.exe",          "🪟", "Windows",          ".exe · x64"),
    "windows_zip": ("BirdNET-Go-Windows-Portable.zip", "📦", "Windows portable", ".zip · x64"),
    "linux_x64":   ("BirdNET-Go-Linux-x64.deb",        "🐧", "Linux x64",        ".deb · amd64"),
    "raspberry":   ("BirdNET-Go-RaspberryPi.deb",      "🍓", "Raspberry Pi",     ".deb · arm64"),
    "macos":       ("BirdNET-Go-macOS.pkg",            "🍎", "macOS (ARM)",      ".pkg · arm64"),
}

def load_json(path):
    if not os.path.exists(path):
        return None
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None

def find_asset(release, name):
    for a in release.get("assets") or []:
        if a.get("name") == name:
            return a
    return None

def sha256_from_asset(asset):
    if not asset:
        return None
    d = (asset.get("digest") or "").strip().lower()
    m = re.match(r"^sha256:([0-9a-f]{64})$", d)
    return m.group(1) if m else None

def pick_latest(releases, nightly=False):
    for r in releases:
        if r.get("draft"):
            continue
        tag = r.get("tag_name", "")
        is_nightly = tag.startswith("nightly-")
        if nightly and is_nightly:
            return r
        if (not nightly) and (not is_nightly):
            return r
    return None

def fmt_size(n):
    if not n:
        return ""
    n = float(n)
    for u in ("o", "Ko", "Mo", "Go"):
        if n < 1024 or u == "Go":
            return f"{n:.0f} {u}" if u == "o" else f"{n:.1f} {u}"
        n /= 1024
    return ""

def build_platform_card(key, release):
    name, icon, title, sub = ASSET_MAP[key]
    asset = find_asset(release, name)
    if not asset:
        return ""
    url = html.escape(asset.get("browser_download_url", "#"))
    size = fmt_size(asset.get("size"))
    sha = sha256_from_asset(asset)
    sha_html = ""
    if sha:
        vt = f"https://www.virustotal.com/gui/file/{sha}"
        sha_html = (
            f'<div class="sha">'
            f'<span class="sha-label">SHA-256</span>'
            f'<code id="sha-{key}">{sha}</code>'
            f'<button class="copy" data-copy="{sha}" title="Copier le hash">⧉</button>'
            f'<a class="vt" href="{vt}" target="_blank" rel="noopener">VirusTotal</a>'
            f'</div>'
        )
    return f"""
      <div class="card">
        <div class="card-icon">{icon}</div>
        <div class="card-title">{title}</div>
        <div class="card-sub">{sub}{f' · {size}' if size else ''}</div>
        <a class="dl" href="{url}" download>Télécharger →</a>
        {sha_html}
      </div>"""

def build_update_json(release):
    asset = find_asset(release, "BirdNET-Go-Windows.exe") if release else None
    return {
        "tag": release.get("tag_name") if release else None,
        "prerelease": bool(release.get("prerelease")) if release else False,
        "url": asset.get("browser_download_url") if asset else None,
        "sha256": sha256_from_asset(asset),
    }

# Les marqueurs __XXX__ sont immunisés contre Prettier et les formateurs de code
HTML_TEMPLATE = """<!doctype html>
<html lang="fr" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>BirdNET-Go Control — Installateur communautaire</title>
<meta name="description" content="Panneau de contrôle multilingue pour BirdNET-Go. Vérification SHA-256.">
<link rel="icon" href="logo.png" type="image/png">
<style>
:root {
  --bg:#1E1E2E; --bg2:#181825; --panel:#313244; --panel2:#26263A;
  --text:#CDD6F4; --muted:#A6ADC8; --dim:#6C7086;
  --accent:#89B4FA; --green:#A6E3A1; --purple:#CBA6F7; --red:#F38BA8; --yellow:#F9E2AF;
  --radius:14px;
}
* { box-sizing:border-box; }
body { margin:0; font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;
  background:radial-gradient(1200px 600px at 50% -10%, #2A2A40, var(--bg)); color:var(--text); line-height:1.55; }
a { color:var(--accent); text-decoration:none; }
a:hover { text-decoration:underline; }
.wrap { max-width:1040px; margin:0 auto; padding:0 20px; }
header { text-align:center; padding:48px 0 24px; }
header img { width:120px; height:auto; }
h1 { font-size:clamp(26px,4vw,40px); margin:14px 0 6px; }
.tagline { color:var(--muted); font-size:17px; margin:0 auto; max-width:680px; }
.badges { display:flex; gap:8px; justify-content:center; flex-wrap:wrap; margin-top:16px; }
.badges img { height:20px; }
.notice { margin:22px auto 0; max-width:760px; background:var(--panel2); border:1px solid var(--panel);
  border-left:4px solid var(--yellow); border-radius:var(--radius); padding:14px 18px; color:var(--muted); font-size:14px; }
section { margin:40px 0; }
h2 { font-size:22px; margin:0 0 6px; display:flex; align-items:center; gap:10px; }
h2 .dot { width:10px; height:10px; border-radius:50%; background:var(--accent); }
.sub { color:var(--dim); margin:0 0 18px; font-size:14px; }
.grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(230px,1fr)); gap:16px; }
.card { background:var(--panel); border:1px solid var(--panel2); border-radius:var(--radius);
  padding:20px; display:flex; flex-direction:column; gap:8px; transition:transform .15s, border-color .15s; }
.card:hover { transform:translateY(-3px); border-color:var(--accent); }
.card-icon { font-size:30px; }
.card-title { font-weight:700; font-size:16px; }
.card-sub { color:var(--dim); font-size:13px; }
.dl { margin-top:6px; align-self:flex-start; background:var(--accent); color:#1E1E2E;
  font-weight:700; padding:9px 14px; border-radius:9px; }
.dl:hover { filter:brightness(1.08); text-decoration:none; }
.sha { display:flex; flex-wrap:wrap; align-items:center; gap:6px; margin-top:8px; font-size:12px; color:var(--dim); }
.sha-label { background:var(--panel2); padding:2px 6px; border-radius:5px; color:var(--muted); }
.sha code { background:#11111B; color:var(--green); padding:3px 6px; border-radius:5px;
  font-family:ui-monospace,Menlo,Consolas,monospace; word-break:break-all; max-width:100%; }
.copy { background:var(--panel2); color:var(--text); border:1px solid var(--dim); border-radius:6px;
  padding:2px 7px; cursor:pointer; font-size:12px; }
.copy:hover { border-color:var(--accent); }
.vt { color:var(--green); font-weight:600; }
.tabs { display:flex; gap:8px; margin-bottom:18px; }
.tab { background:var(--panel2); border:1px solid var(--panel); color:var(--muted);
  padding:8px 16px; border-radius:9px; cursor:pointer; font-weight:600; font-size:14px; }
.tab.active { background:var(--accent); color:#1E1E2E; border-color:var(--accent); }
.pane { display:none; }
.pane.active { display:block; }
.features { display:grid; grid-template-columns:repeat(auto-fit,minmax(240px,1fr)); gap:14px; }
.feature { background:var(--panel); border-radius:var(--radius); padding:16px; border:1px solid var(--panel2); }
.feature b { display:block; margin-bottom:4px; }
.feature span { color:var(--muted); font-size:14px; }
.security ol { margin:0; padding-left:20px; color:var(--muted); }
.security li { margin:6px 0; }
.links { display:flex; gap:12px; justify-content:center; flex-wrap:wrap; margin-top:12px; }
.links a { background:var(--panel2); padding:8px 16px; border-radius:8px; border:1px solid var(--panel); font-size:14px; }
.links a:hover { background:var(--panel); border-color:var(--accent); text-decoration:none; }
footer { text-align:center; color:var(--dim); font-size:13px; padding:40px 0; border-top:1px solid var(--panel); margin-top:40px; }
footer a { color:var(--muted); }
@media (max-width:520px) { .tabs { flex-wrap:wrap; } }
</style>
</head>
<body>
<div class="wrap">
<header>
  <img src="logo.png" alt="BirdNET-Go Control">
  <h1>🐦 BirdNET-Go Control</h1>
  <p class="tagline">Panneau de contrôle multilingue pour <strong>BirdNET-Go</strong> — le détecteur d'oiseaux auto-hébergé. Installez, mettez à jour et surveillez en un clic.</p>
  <div class="badges">
    <img src="https://img.shields.io/badge/license-MIT-green" alt="License MIT">
    <img src="https://img.shields.io/badge/langues-16-blue" alt="16 langues">
    <img src="https://img.shields.io/badge/SHA--256-v%C3%A9rifi%C3%A9-brightgreen" alt="SHA-256 vérifié">
  </div>
  <div class="notice">
    ⚠️ <strong>Projet communautaire non officiel.</strong> Les binaires BirdNET-Go proviennent directement des releases officielles de
    <a href="https://github.com/__UPSTREAM__" target="_blank" rel="noopener">__UPSTREAM__</a>, jamais recompilés.
    Chaque fichier est vérifié par empreinte <strong>SHA-256</strong> avant installation.
  </div>
</header>

<section>
  <h2><span class="dot"></span> Télécharger</h2>
  <p class="sub">Choisissez le canal, puis votre plateforme. Les empreintes SHA-256 sont affichées pour chaque fichier.</p>
  <div class="tabs">
    <button class="tab active" data-pane="stable">Stable · __STABLE_TAG__</button>
    <button class="tab" data-pane="nightly">Nightly · __NIGHTLY_TAG__</button>
  </div>
  <div class="pane active" id="pane-stable"><div class="grid">__CARDS_STABLE__</div></div>
  <div class="pane" id="pane-nightly"><div class="grid">__CARDS_NIGHTLY__</div></div>
</section>

<section>
  <h2><span class="dot"></span> Fonctionnalités</h2>
  <div class="features">
    <div class="feature"><b>🎛️ Contrôle serveur</b><span>Démarrer/arrêter, watchdog anti-crash, port auto synchronisé avec le moteur.</span></div>
    <div class="feature"><b>📊 Résultats en direct</b><span>Pastille qui pulse, latence ms, détections du jour, dernière espèce.</span></div>
    <div class="feature"><b>📈 Statistiques</b><span>Sparkline 24 h, top 5 espèces, export CSV.</span></div>
    <div class="feature"><b>🔄 Mises à jour in-app</b><span>Contrôleur + moteur en 1 clic, canal statique sans quota API.</span></div>
    <div class="feature"><b>🌍 16 langues</b><span>FR, EN, DE, ES, IT, PT, NL, PL, CS, SK, HU, DA, SV, NB, FI, LV.</span></div>
    <div class="feature"><b>💾 Backup / Restore</b><span>Sauvegarde zip horodatée des réglages + config moteur.</span></div>
    <div class="feature"><b>⌨️ Raccourci global</b><span><code>Ctrl+Alt+B</code> pour afficher depuis n'importe où.</span></div>
    <div class="feature"><b>📦 Self-contained</b><span>Aucun runtime .NET requis chez l'utilisateur.</span></div>
  </div>
</section>

<section class="security">
  <h2><span class="dot"></span> Sécurité</h2>
  <ol>
    <li><strong>Source officielle</strong> — binaires téléchargés depuis les releases de <code>__UPSTREAM__</code>.</li>
    <li><strong>SHA-256 vérifié</strong> — empreinte comparée au digest GitHub avant exécution ; mismatch = installation annulée.</li>
    <li><strong>100 % open source</strong> — code auditable dans <code>src/</code>.</li>
    <li><strong>Scan VirusTotal</strong> — chaque fichier propose un lien direct vers son rapport (aucune clé API requise).</li>
  </ol>
  <div class="links">
    <a href="https://github.com/__REPO__" target="_blank" rel="noopener">📂 Dépôt du contrôleur</a>
    <a href="https://github.com/__UPSTREAM__" target="_blank" rel="noopener">🐦 Projet officiel BirdNET-Go</a>
    <a href="https://github.com/__UPSTREAM__/wiki" target="_blank" rel="noopener">📖 Documentation officielle</a>
  </div>
  <p class="sub" style="margin-top:14px">
    Installation avancée (Windows) :
    <code>BirdNET-Go-Windows.exe /VERYSILENT /PORT=9090</code> ·
    <code>... /REPAIR</code>
  </p>
</section>

<footer>
  <p>BirdNET-Go Installer · généré le __NOW__ · <a href="https://github.com/__REPO__" target="_blank" rel="noopener">Dépôt</a> · <a href="https://github.com/__REPO__/releases" target="_blank" rel="noopener">Releases</a> · <a href="https://github.com/__UPSTREAM__" target="_blank" rel="noopener">Projet officiel</a></p>
  <p>Non affilié officiellement au projet BirdNET-Go. Licence MIT.</p>
</footer>
</div>
<script>
document.querySelectorAll('.tab').forEach(function(t) {
  t.addEventListener('click', function() {
    document.querySelectorAll('.tab').forEach(function(x) { x.classList.remove('active'); });
    document.querySelectorAll('.pane').forEach(function(x) { x.classList.remove('active'); });
    t.classList.add('active');
    document.getElementById('pane-' + t.dataset.pane).classList.add('active');
  });
});
document.querySelectorAll('.copy').forEach(function(b) {
  b.addEventListener('click', function() {
    navigator.clipboard.writeText(b.dataset.copy).then(function() {
      var o = b.textContent; b.textContent = '✓'; setTimeout(function() { b.textContent = o; }, 1200);
    });
  });
});
</script>
</body>
</html>"""

def main():
    try:
        releases = load_json(RELEASES_FILE) or []
        if isinstance(releases, dict):
            releases = releases.get("releases", [])
        
        stable = pick_latest(releases, nightly=False)
        nightly = pick_latest(releases, nightly=True)
        
        stable_tag = (stable or {}).get("tag_name") or "—"
        nightly_tag = (nightly or {}).get("tag_name") or "—"
        
        # Petit message de secours si aucune release n'est trouvée
        cards_stable = "".join(build_platform_card(k, stable) for k in ASSET_MAP) if stable else "<p style='color:var(--muted);'>Aucune release stable trouvée pour le moment.</p>"
        cards_nightly = "".join(build_platform_card(k, nightly) for k in ASSET_MAP) if nightly else "<p style='color:var(--muted);'>Aucune release nightly trouvée pour le moment.</p>"
        
        now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
        
        # Remplacement sécurisé, insensible aux formateurs de code
        page = HTML_TEMPLATE
        page = page.replace("__UPSTREAM__", UPSTREAM)
        page = page.replace("__REPO__", REPO)
        page = page.replace("__STABLE_TAG__", html.escape(stable_tag))
        page = page.replace("__NIGHTLY_TAG__", html.escape(nightly_tag))
        page = page.replace("__CARDS_STABLE__", cards_stable)
        page = page.replace("__CARDS_NIGHTLY__", cards_nightly)
        page = page.replace("__NOW__", now)
        
        with open(OUT_HTML, "w", encoding="utf-8") as f:
            f.write(page)
        print(f"✅ {OUT_HTML} généré avec succès ({len(page)} octets)")
        
        update_data = build_update_json(stable)
        with open(OUT_JSON, "w", encoding="utf-8") as f:
            json.dump(update_data, f, indent=2)
        print(f"✅ {OUT_JSON} généré (tag: {update_data.get('tag')})")
        
    except Exception as e:
        print(f"❌ Erreur fatale lors de la génération : {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
