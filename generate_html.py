#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# ⚠️ IMPORTANT : NE PAS FORMATER CE FICHIER (Prettier, Black, etc.)
# ==============================================================================
"""
Génère un index.html moderne, attractif et léger pour GitHub Pages.
Design : Glassmorphism, animations fluides, dégradés subtils.
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
    "windows_zip": ("BirdNET-Go-Windows-Portable.zip", "📦", "Windows Portable", ".zip · x64"),
    "linux_x64":   ("BirdNET-Go-Linux-x64.deb",        "🐧", "Linux x64",        ".deb · amd64"),
    "raspberry":   ("BirdNET-Go-RaspberryPi.deb",      "🍓", "Raspberry Pi",     ".deb · arm64"),
    "macos":       ("BirdNET-Go-macOS.pkg",            "🍎", "macOS (ARM)",      ".pkg · arm64"),
}

def load_json(path):
    if not os.path.exists(path): return None
    try:
        with open(path, encoding="utf-8") as f: return json.load(f)
    except Exception: return None

def find_asset(release, name):
    for a in release.get("assets") or []:
        if a.get("name") == name: return a
    return None

def sha256_from_asset(asset):
    if not asset: return None
    d = (asset.get("digest") or "").strip().lower()
    m = re.match(r"^sha256:([0-9a-f]{64})$", d)
    return m.group(1) if m else None

def pick_latest(releases, nightly=False):
    for r in releases:
        if r.get("draft"): continue
        tag = r.get("tag_name", "")
        is_nightly = tag.startswith("nightly-")
        if nightly and is_nightly: return r
        if (not nightly) and (not is_nightly): return r
    return None

def fmt_size(n):
    if not n: return ""
    n = float(n)
    for u in ("o", "Ko", "Mo", "Go"):
        if n < 1024 or u == "Go": return f"{n:.0f} {u}" if u == "o" else f"{n:.1f} {u}"
        n /= 1024
    return ""

def build_platform_card(key, release, index):
    name, icon, title, sub = ASSET_MAP[key]
    asset = find_asset(release, name)
    if not asset: return ""
    url = html.escape(asset.get("browser_download_url", "#"))
    size = fmt_size(asset.get("size"))
    sha = sha256_from_asset(asset)
    
    sha_html = ""
    if sha:
        vt = f"https://www.virustotal.com/gui/file/{sha}"
        sha_html = f"""
        <div class="sha-block">
            <div class="sha-row">
                <span class="sha-label">SHA-256</span>
                <code>{sha[:16]}...{sha[-16:]}</code>
            </div>
            <div class="sha-actions">
                <button class="btn-copy" data-copy="{sha}" title="Copier le hash complet">⧉ Copier</button>
                <a class="btn-vt" href="{vt}" target="_blank" rel="noopener">🛡️ VirusTotal</a>
            </div>
        </div>"""

    # Animation décalée pour un effet cascade
    delay = index * 0.1
    return f"""
      <div class="card" style="animation-delay: {delay}s">
        <div class="card-header">
            <span class="card-icon">{icon}</span>
            <div>
                <div class="card-title">{title}</div>
                <div class="card-sub">{sub} · {size}</div>
            </div>
        </div>
        <a class="btn-dl" href="{url}" download>
            <span>Télécharger</span>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
        </a>
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

# ==============================================================================
# TEMPLATE HTML PREMIUM (Glassmorphism, Animations, Dégradés)
# ==============================================================================
HTML_TEMPLATE = """<!doctype html>
<html lang="fr" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>BirdNET-Go Control — Installateur Communautaire</title>
<meta name="description" content="Panneau de contrôle multilingue et sécurisé pour BirdNET-Go.">
<meta property="og:title" content="BirdNET-Go Control">
<meta property="og:description" content="Installez, mettez à jour et surveillez BirdNET-Go en un clic.">
<link rel="icon" href="logo.png" type="image/png">
<style>
:root {
  --bg: #0f0f13;
  --bg-glow: radial-gradient(circle at 50% 0%, #1e1e2e 0%, #0f0f13 60%);
  --panel: rgba(30, 30, 46, 0.6);
  --panel-border: rgba(255, 255, 255, 0.08);
  --text: #cdd6f4;
  --muted: #a6adc8;
  --dim: #6c7086;
  --accent: #89b4fa;
  --accent-glow: rgba(137, 180, 250, 0.4);
  --green: #a6e3a1;
  --purple: #cba6f7;
  --radius: 16px;
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body { 
  font-family: 'Inter', system-ui, -apple-system, sans-serif; 
  background: var(--bg);
  background-image: var(--bg-glow);
  color: var(--text); 
  line-height: 1.6; 
  min-height: 100vh;
}
a { color: var(--accent); text-decoration: none; transition: color 0.2s; }
a:hover { color: #b4befe; }

.wrap { max-width: 1100px; margin: 0 auto; padding: 0 24px; }

/* --- Animations --- */
@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(24px); }
  to { opacity: 1; transform: translateY(0); }
}
.animate { animation: fadeInUp 0.7s cubic-bezier(0.16, 1, 0.3, 1) forwards; opacity: 0; }

/* --- Header --- */
header { text-align: center; padding: 64px 0 40px; }
header img { width: 96px; height: 96px; margin-bottom: 16px; filter: drop-shadow(0 8px 24px rgba(137, 180, 250, 0.2)); }
h1 { 
  font-size: clamp(32px, 5vw, 48px); 
  font-weight: 800; 
  letter-spacing: -0.02em;
  background: linear-gradient(135deg, #fff 0%, var(--accent) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: 12px;
}
.tagline { color: var(--muted); font-size: 18px; max-width: 600px; margin: 0 auto 24px; }
.badges { display: flex; gap: 10px; justify-content: center; flex-wrap: wrap; margin-bottom: 24px; }
.badges img { height: 22px; border-radius: 6px; }
.notice { 
  max-width: 700px; margin: 0 auto; 
  background: rgba(249, 226, 175, 0.05); 
  border: 1px solid rgba(249, 226, 175, 0.2); 
  border-radius: var(--radius); 
  padding: 16px 20px; 
  color: var(--muted); 
  font-size: 14px; 
  text-align: left;
}
.notice strong { color: #f9e2af; }

/* --- Sections --- */
section { margin: 56px 0; }
h2 { font-size: 24px; font-weight: 700; margin-bottom: 8px; display: flex; align-items: center; gap: 10px; }
h2 .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--accent); box-shadow: 0 0 12px var(--accent-glow); }
.sub { color: var(--dim); margin-bottom: 24px; font-size: 15px; }

/* --- Tabs --- */
.tabs { display: inline-flex; background: rgba(255,255,255,0.03); border: 1px solid var(--panel-border); border-radius: 99px; padding: 4px; margin-bottom: 24px; }
.tab { 
  background: transparent; border: none; color: var(--dim); 
  padding: 8px 20px; border-radius: 99px; cursor: pointer; 
  font-weight: 600; font-size: 14px; transition: all 0.3s ease; 
}
.tab.active { background: var(--accent); color: #0f0f13; box-shadow: 0 4px 16px var(--accent-glow); }
.pane { display: none; }
.pane.active { display: block; }

/* --- Grid & Cards (Glassmorphism) --- */
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
.card { 
  background: var(--panel); 
  backdrop-filter: blur(12px);
  border: 1px solid var(--panel-border); 
  border-radius: var(--radius); 
  padding: 24px; 
  display: flex; flex-direction: column; gap: 16px; 
  transition: transform 0.3s ease, border-color 0.3s ease, box-shadow 0.3s ease;
}
.card:hover { 
  transform: translateY(-4px); 
  border-color: rgba(137, 180, 250, 0.3); 
  box-shadow: 0 12px 40px -12px rgba(0,0,0,0.5), 0 0 20px -5px var(--accent-glow);
}
.card-header { display: flex; align-items: flex-start; gap: 14px; }
.card-icon { font-size: 32px; line-height: 1; }
.card-title { font-weight: 700; font-size: 17px; color: #fff; }
.card-sub { color: var(--dim); font-size: 13px; margin-top: 2px; }

/* --- Buttons --- */
.btn-dl { 
  display: flex; align-items: center; justify-content: center; gap: 8px;
  background: linear-gradient(135deg, var(--accent), var(--purple)); 
  color: #0f0f13; font-weight: 700; font-size: 15px;
  padding: 12px; border-radius: 12px; 
  transition: all 0.2s ease; text-decoration: none;
}
.btn-dl:hover { filter: brightness(1.1); transform: scale(1.02); box-shadow: 0 8px 24px -4px var(--accent-glow); }
.btn-dl svg { transition: transform 0.2s; }
.btn-dl:hover svg { transform: translateY(2px); }

/* --- SHA Block --- */
.sha-block { 
  background: rgba(0,0,0,0.3); border: 1px solid var(--panel-border); 
  border-radius: 10px; padding: 12px; font-size: 13px; 
}
.sha-row { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; font-family: 'JetBrains Mono', monospace; }
.sha-label { background: rgba(166, 227, 161, 0.1); color: var(--green); padding: 2px 8px; border-radius: 6px; font-size: 11px; font-weight: 700; font-family: system-ui; }
.sha-row code { color: var(--muted); word-break: break-all; }
.sha-actions { display: flex; gap: 8px; }
.btn-copy, .btn-vt { 
  flex: 1; text-align: center; padding: 8px; border-radius: 8px; 
  font-size: 12px; font-weight: 600; cursor: pointer; transition: all 0.2s; border: none; text-decoration: none;
}
.btn-copy { background: rgba(255,255,255,0.05); color: var(--text); border: 1px solid var(--panel-border); }
.btn-copy:hover { background: rgba(255,255,255,0.1); border-color: var(--accent); }
.btn-vt { background: rgba(166, 227, 161, 0.1); color: var(--green); border: 1px solid rgba(166, 227, 161, 0.2); }
.btn-vt:hover { background: rgba(166, 227, 161, 0.2); }

/* --- Features --- */
.features { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px; }
.feature { 
  background: var(--panel); border: 1px solid var(--panel-border); 
  border-radius: var(--radius); padding: 20px; 
  transition: border-color 0.2s;
}
.feature:hover { border-color: rgba(137, 180, 250, 0.2); }
.feature b { display: block; margin-bottom: 6px; font-size: 15px; color: #fff; }
.feature span { color: var(--muted); font-size: 14px; line-height: 1.5; }

/* --- Security & Footer --- */
.security ol { margin-left: 20px; color: var(--muted); }
.security li { margin: 8px 0; font-size: 15px; }
.security code { background: rgba(255,255,255,0.05); padding: 2px 6px; border-radius: 4px; color: var(--accent); font-size: 13px; }
.links { display: flex; gap: 12px; justify-content: center; flex-wrap: wrap; margin-top: 24px; }
.links a { 
  background: var(--panel); padding: 10px 18px; border-radius: 10px; 
  border: 1px solid var(--panel-border); font-size: 14px; font-weight: 500;
}
.links a:hover { background: rgba(255,255,255,0.05); border-color: var(--accent); color: var(--accent); }
footer { text-align: center; color: var(--dim); font-size: 13px; padding: 48px 0; border-top: 1px solid var(--panel-border); margin-top: 64px; }

@media (max-width: 600px) { 
  .tabs { width: 100%; } 
  .tab { flex: 1; text-align: center; font-size: 13px; padding: 10px; }
  .sha-actions { flex-direction: column; }
}
</style>
</head>
<body>
<div class="wrap">

<header class="animate" style="animation-delay: 0.1s">
  <img src="logo.png" alt="BirdNET-Go Control">
  <h1>BirdNET-Go Control</h1>
  <p class="tagline">Panneau de contrôle multilingue pour <strong>BirdNET-Go</strong>.<br>Installez, mettez à jour et surveillez en un clic.</p>
  <div class="badges">
    <img src="https://img.shields.io/badge/license-MIT-89b4fa?style=flat-square" alt="License">
    <img src="https://img.shields.io/badge/langues-16-a6e3a1?style=flat-square" alt="16 langues">
    <img src="https://img.shields.io/badge/SHA--256-v%C3%A9rifi%C3%A9-cba6f7?style=flat-square" alt="SHA-256">
  </div>
  <div class="notice">
    ⚠️ <strong>Projet communautaire non officiel.</strong> Les binaires proviennent directement des releases de <a href="https://github.com/__UPSTREAM__" target="_blank" rel="noopener">__UPSTREAM__</a>, jamais recompilés. Chaque fichier est vérifié par empreinte SHA-256 avant installation.
  </div>
</header>

<section class="animate" style="animation-delay: 0.2s">
  <h2><span class="dot"></span> Télécharger</h2>
  <p class="sub">Choisissez votre plateforme. Les empreintes de sécurité sont affichées pour chaque fichier.</p>
  <div class="tabs">
    <button class="tab active" data-pane="stable">Stable · __STABLE_TAG__</button>
    <button class="tab" data-pane="nightly">Nightly · __NIGHTLY_TAG__</button>
  </div>
  <div class="pane active" id="pane-stable"><div class="grid">__CARDS_STABLE__</div></div>
  <div class="pane" id="pane-nightly"><div class="grid">__CARDS_NIGHTLY__</div></div>
</section>

<section class="animate" style="animation-delay: 0.3s">
  <h2><span class="dot"></span> Fonctionnalités</h2>
  <div class="features">
    <div class="feature"><b>🎛️ Contrôle serveur</b><span>Démarrer/arrêter, watchdog anti-crash, port auto synchronisé.</span></div>
    <div class="feature"><b>📊 Résultats en direct</b><span>Pastille qui pulse, latence ms, détections du jour.</span></div>
    <div class="feature"><b>📈 Statistiques</b><span>Sparkline 24h, top 5 espèces, export CSV.</span></div>
    <div class="feature"><b>🔄 Mises à jour in-app</b><span>Contrôleur + moteur en 1 clic, sans quota API.</span></div>
    <div class="feature"><b>🌍 16 langues</b><span>FR, EN, DE, ES, IT, PT, NL, PL, CS, SK, HU, DA, SV, NB, FI, LV.</span></div>
    <div class="feature"><b>💾 Backup / Restore</b><span>Sauvegarde zip horodatée des réglages.</span></div>
  </div>
</section>

<section class="security animate" style="animation-delay: 0.4s">
  <h2><span class="dot"></span> Sécurité & Transparence</h2>
  <ol>
    <li><strong>Source officielle</strong> : binaires téléchargés depuis <code>__UPSTREAM__</code>.</li>
    <li><strong>SHA-256 vérifié</strong> : empreinte comparée au digest GitHub avant exécution.</li>
    <li><strong>100 % open source</strong> : code entièrement auditable dans <code>src/</code>.</li>
    <li><strong>Scan VirusTotal</strong> : lien direct vers le rapport de chaque fichier.</li>
  </ol>
  <div class="links">
    <a href="https://github.com/__REPO__" target="_blank" rel="noopener">📂 Dépôt du contrôleur</a>
    <a href="https://github.com/__UPSTREAM__" target="_blank" rel="OPenSource">🐦 Projet officiel BirdNET-Go</a>
    <a href="https://github.com/__UPSTREAM__/wiki" target="_blank" rel="noopener">📖 Documentation officielle</a>
  </div>
</section>

<footer class="animate" style="animation-delay: 0.5s">
  <p>BirdNET-Go Installer · généré le __NOW__</p>
  <p style="margin-top: 8px;">Non affilié officiellement au projet BirdNET-Go. Licence MIT.</p>
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
document.querySelectorAll('.btn-copy').forEach(function(b) {
  b.addEventListener('click', function() {
    navigator.clipboard.writeText(b.dataset.copy).then(function() {
      var original = b.innerHTML; 
      b.innerHTML = '✓ Copié !'; 
      b.style.borderColor = 'var(--green)';
      b.style.color = 'var(--green)';
      setTimeout(function() { 
        b.innerHTML = original; 
        b.style.borderColor = ''; 
        b.style.color = '';
      }, 1500);
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
        
        cards_stable = "".join(build_platform_card(k, stable, i) for i, k in enumerate(ASSET_MAP)) if stable else "<p style='color:var(--dim); padding:20px;'>Aucune release stable trouvée.</p>"
        cards_nightly = "".join(build_platform_card(k, nightly, i) for i, k in enumerate(ASSET_MAP)) if nightly else "<p style='color:var(--dim); padding:20px;'>Aucune release nightly trouvée.</p>"
        
        now = datetime.now(timezone.utc).strftime("%d %b %Y à %H:%M UTC")
        
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
        print(f"❌ Erreur fatale : {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
