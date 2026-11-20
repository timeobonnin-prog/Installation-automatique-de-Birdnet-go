#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# ⚠️ IMPORTANT : NE PAS FORMATER CE FICHIER (Prettier, Black, etc.)
# ==============================================================================
"""
Génère un index.html authentique, léger et visuellement distinctif.
Évite les pièges du "design IA générique" grâce à des textures, 
une typographie soignée et des micro-interactions humaines.
"""

import json
import os
import re
import html
import sys
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

# ==============================================================================
# CONFIGURATION
# ==============================================================================
RELEASES_FILE = "releases.json"
OUT_HTML = "index.html"
OUT_JSON = "update.json"
REPO = "timeobonnin-prog/Installation-automatique-de-Birdnet-go"
UPSTREAM = "tphakala/birdnet-go"

ASSET_MAP = {
    "windows":     ("BirdNET-Go-Windows.exe",          "windows", "Windows",          ".exe · x64"),
    "windows_zip": ("BirdNET-Go-Windows-Portable.zip", "windows", "Windows Portable", ".zip · x64"),
    "linux_x64":   ("BirdNET-Go-Linux-x64.deb",        "linux",   "Linux x64",        ".deb · amd64"),
    "raspberry":   ("BirdNET-Go-RaspberryPi.deb",      "linux",   "Raspberry Pi",     ".deb · arm64"),
    "macos":       ("BirdNET-Go-macOS.pkg",            "macos",   "macOS (ARM)",      ".pkg · arm64"),
}

# ==============================================================================
# HELPERS
# ==============================================================================
def load_json(path: str) -> Optional[List[Dict[str, Any]]]:
    if not os.path.exists(path): return None
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
            return data if isinstance(data, list) else data.get("releases", [])
    except Exception:
        return None

def find_asset(release: Dict[str, Any], name: str) -> Optional[Dict[str, Any]]:
    for a in release.get("assets") or []:
        if a.get("name") == name: return a
    return None

def sha256_from_asset(asset: Dict[str, Any]) -> Optional[str]:
    if not asset: return None
    m = re.match(r"^sha256:([0-9a-f]{64})$", (asset.get("digest") or "").strip().lower())
    return m.group(1) if m else None

def pick_latest(releases: List[Dict[str, Any]], nightly: bool = False) -> Optional[Dict[str, Any]]:
    for r in releases:
        if r.get("draft"): continue
        tag = r.get("tag_name", "")
        is_nightly = tag.startswith("nightly-")
        if nightly and is_nightly: return r
        if (not nightly) and (not is_nightly): return r
    return None

def fmt_size(n: Any) -> str:
    if not n: return ""
    n = float(n)
    for u in ("o", "Ko", "Mo", "Go"):
        if n < 1024 or u == "Go": return f"{n:.0f} {u}" if u == "o" else f"{n:.1f} {u}"
        n /= 1024
    return ""

def build_platform_card(key: str, release: Dict[str, Any]) -> str:
    name, os_type, title, sub = ASSET_MAP[key]
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
                <code title="{sha}">{sha[:16]}...{sha[-16:]}</code>
            </div>
            <div class="sha-actions">
                <button class="btn-copy" data-copy="{sha}" aria-label="Copier le hash">⧉ Copier</button>
                <a class="btn-vt" href="{vt}" target="_blank" rel="noopener">🛡️ VirusTotal</a>
            </div>
        </div>"""

    return f"""
      <article class="download-card" data-os="{os_type}">
        <div class="card-badge recommended-badge" style="display:none;">✨ Recommandé pour vous</div>
        <div class="card-header">
            <span class="os-icon">{ '🪟' if os_type=='windows' else '🐧' if os_type=='linux' else '🍎' }</span>
            <div>
                <h3 class="card-title">{html.escape(title)}</h3>
                <p class="card-sub">{html.escape(sub)} · {size}</p>
            </div>
        </div>
        <a class="btn-dl" href="{url}" download aria-label="Télécharger {html.escape(title)}">
            <span>Télécharger</span>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
        </a>
        {sha_html}
      </article>"""

def build_update_json(release: Optional[Dict[str, Any]]) -> Dict[str, Any]:
    asset = find_asset(release, "BirdNET-Go-Windows.exe") if release else None
    return {
        "tag": release.get("tag_name") if release else None,
        "prerelease": bool(release.get("prerelease")) if release else False,
        "url": asset.get("browser_download_url") if asset else None,
        "sha256": sha256_from_asset(asset),
    }

# ==============================================================================
# TEMPLATE HTML (Authentique, texturé, sans clichés IA)
# ==============================================================================
HTML_TEMPLATE = """<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="dark">
<meta name="description" content="Panneau de contrôle local et sécurisé pour BirdNET-Go. Écoutez la nature chez vous.">
<title>BirdNET-Go Control — Installateur Communautaire</title>
<link rel="icon" href="assets/logo.png" type="image/png">
<style>
:root {
  --bg: #0c0c10;
  --text: #e2e8f0;
  --muted: #94a3b8;
  --accent: #38bdf8;
  --accent-glow: rgba(56, 189, 248, 0.15);
  --card-bg: rgba(30, 41, 59, 0.4);
  --card-border: rgba(255, 255, 255, 0.06);
  --success: #4ade80;
  --radius: 12px;
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body { 
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; 
  background-color: var(--bg);
  color: var(--text); 
  line-height: 1.6;
  /* Texture de bruit subtile pour casser l'effet "plat IA" */
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)' opacity='0.04'/%3E%3C/svg%3E");
}
a { color: var(--accent); text-decoration: none; transition: opacity 0.2s; }
a:hover { opacity: 0.8; }
.wrap { max-width: 960px; margin: 0 auto; padding: 0 24px; }

/* --- Header --- */
header { padding: 48px 0 32px; display: flex; flex-direction: column; align-items: center; text-align: center; }
.logo-area { display: flex; align-items: center; gap: 16px; margin-bottom: 16px; }
.logo-area img { width: 56px; height: 56px; border-radius: 12px; }
h1 { font-size: clamp(28px, 5vw, 40px); font-weight: 700; letter-spacing: -0.02em; color: #fff; }
.version-badge { 
  display: inline-flex; align-items: center; gap: 6px;
  background: rgba(56, 189, 248, 0.1); color: var(--accent); 
  padding: 4px 12px; border-radius: 99px; font-size: 13px; font-weight: 600;
  border: 1px solid rgba(56, 189, 248, 0.2); margin-top: 12px;
}
.tagline { color: var(--muted); font-size: 18px; max-width: 540px; margin: 16px auto 0; }

/* --- Sections --- */
section { margin: 64px 0; }
h2 { font-size: 22px; font-weight: 600; margin-bottom: 24px; color: #fff; display: flex; align-items: center; gap: 10px; }
h2::before { content: ''; display: block; width: 4px; height: 20px; background: var(--accent); border-radius: 2px; }

/* --- Quick Start (Asymétrique et humain) --- */
.steps { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 24px; }
.step { 
  background: var(--card-bg); border: 1px solid var(--card-border); 
  border-radius: var(--radius); padding: 24px; position: relative;
  transition: transform 0.2s ease, border-color 0.2s ease;
}
.step:hover { transform: translateY(-2px); border-color: rgba(255,255,255,0.12); }
.step-num { 
  position: absolute; top: -12px; left: 24px; 
  background: var(--bg); border: 1px solid var(--card-border); 
  color: var(--accent); font-weight: 700; font-size: 14px; 
  width: 28px; height: 28px; border-radius: 50%; 
  display: flex; align-items: center; justify-content: center;
}
.step h3 { font-size: 16px; font-weight: 600; color: #fff; margin-bottom: 8px; margin-top: 8px; }
.step p { color: var(--muted); font-size: 14px; line-height: 1.5; }

/* --- App Preview (Galerie simple) --- */
.preview-grid { 
  display: grid; grid-template-columns: 2fr 1fr; gap: 16px; 
  background: var(--card-bg); border: 1px solid var(--card-border); 
  border-radius: var(--radius); padding: 16px; overflow: hidden;
}
.preview-main { 
  background: #1e293b; border-radius: 8px; aspect-ratio: 16/10; 
  display: flex; align-items: center; justify-content: center;
  color: var(--muted); font-size: 14px; border: 1px dashed rgba(255,255,255,0.1);
}
.preview-side { display: flex; flex-direction: column; gap: 16px; }
.preview-sub { 
  flex: 1; background: #1e293b; border-radius: 8px; 
  display: flex; align-items: center; justify-content: center;
  color: var(--muted); font-size: 13px; border: 1px dashed rgba(255,255,255,0.1);
}
/* Remplacez les divs ci-dessus par des <img src="screenshots/..."> quand vous les aurez */

/* --- Downloads --- */
.download-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; }
.download-card { 
  background: var(--card-bg); border: 1px solid var(--card-border); 
  border-radius: var(--radius); padding: 20px; position: relative;
  transition: all 0.25s ease;
}
.download-card.recommended { 
  border-color: var(--accent); 
  box-shadow: 0 0 0 1px var(--accent), 0 8px 24px -8px var(--accent-glow);
}
.recommended-badge { 
  position: absolute; top: -10px; right: 16px; 
  background: var(--accent); color: #0f172a; 
  font-size: 11px; font-weight: 700; padding: 4px 10px; 
  border-radius: 99px; text-transform: uppercase; letter-spacing: 0.05em;
}
.card-header { display: flex; align-items: flex-start; gap: 12px; margin-bottom: 16px; }
.os-icon { font-size: 24px; }
.card-title { font-weight: 600; font-size: 16px; color: #fff; margin: 0; }
.card-sub { color: var(--muted); font-size: 13px; margin-top: 2px; }
.btn-dl { 
  display: flex; align-items: center; justify-content: center; gap: 8px;
  background: #fff; color: #0f172a; font-weight: 600; font-size: 14px;
  padding: 10px; border-radius: 8px; transition: all 0.2s ease; text-decoration: none;
}
.btn-dl:hover { background: #e2e8f0; transform: translateY(-1px); }
.sha-block { 
  margin-top: 16px; padding-top: 16px; border-top: 1px solid var(--card-border); 
  font-size: 12px;
}
.sha-row { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; font-family: monospace; }
.sha-label { background: rgba(74, 222, 128, 0.1); color: var(--success); padding: 2px 6px; border-radius: 4px; font-size: 10px; font-weight: 700; font-family: system-ui; }
.sha-row code { color: var(--muted); word-break: break-all; }
.sha-actions { display: flex; gap: 8px; }
.btn-copy, .btn-vt { 
  flex: 1; text-align: center; padding: 6px; border-radius: 6px; 
  font-size: 12px; font-weight: 500; cursor: pointer; transition: all 0.2s; border: none; text-decoration: none;
}
.btn-copy { background: rgba(255,255,255,0.05); color: var(--text); border: 1px solid var(--card-border); }
.btn-copy:hover { background: rgba(255,255,255,0.1); }
.btn-vt { background: rgba(74, 222, 128, 0.1); color: var(--success); border: 1px solid rgba(74, 222, 128, 0.2); }
.btn-vt:hover { background: rgba(74, 222, 128, 0.2); }

/* --- Trust & Footer --- */
.trust-list { list-style: none; display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; }
.trust-list li { 
  display: flex; align-items: flex-start; gap: 10px; 
  color: var(--muted); font-size: 14px; line-height: 1.5;
}
.trust-list li::before { content: '✓'; color: var(--success); font-weight: 700; }
footer { text-align: center; color: var(--muted); font-size: 13px; padding: 48px 0; border-top: 1px solid var(--card-border); margin-top: 64px; }

@media (max-width: 640px) {
  .preview-grid { grid-template-columns: 1fr; }
  .preview-side { flex-direction: row; }
}
</style>
</head>
<body>
<div class="wrap">

<header>
  <div class="logo-area">
    <img src="assets/logo.png" alt="Logo">
    <h1>BirdNET-Go Control</h1>
  </div>
  <div class="version-badge">
    <span>📦 Version stable actuelle :</span>
    <strong>__STABLE_TAG__</strong>
  </div>
  <p class="tagline">Écoutez la nature chez vous. Un panneau de contrôle local, léger et sécurisé pour votre détecteur d'oiseaux.</p>
</header>

<main>
<section>
  <h2>Comment ça marche</h2>
  <div class="steps">
    <div class="step">
      <span class="step-num">1</span>
      <h3>Installez le contrôle</h3>
      <p>Téléchargez l'installateur ci-dessous. Il configurera le moteur BirdNET-Go officiel et l'interface de gestion en un clic.</p>
    </div>
    <div class="step">
      <span class="step-num">2</span>
      <h3>Branchez votre micro</h3>
      <p>Connectez un microphone USB à votre ordinateur ou Raspberry Pi. L'application le détectera automatiquement.</p>
    </div>
    <div class="step">
      <span class="step-num">3</span>
      <h3>Écoutez la nature</h3>
      <p>Lancez le serveur. L'IA analyse les sons en temps réel et vous alerte des espèces détectées autour de chez vous.</p>
    </div>
  </div>
</section>

<section>
  <h2>Aperçu de l'application</h2>
  <div class="preview-grid">
    <!-- Remplacez ces divs par : <img src="screenshots/control.png" style="width:100%; border-radius:8px;"> -->
    <div class="preview-main">[ Capture : Tableau de bord de Contrôle ]</div>
    <div class="preview-side">
      <div class="preview-sub">[ Capture : Résultats en direct ]</div>
      <div class="preview-sub">[ Capture : Statistiques ]</div>
    </div>
  </div>
</section>

<section>
  <h2>Téléchargements sécurisés</h2>
  <p style="color: var(--muted); margin-bottom: 20px; font-size: 14px;">Votre système a été détecté automatiquement. Les empreintes SHA-256 sont vérifiables.</p>
  <div class="download-grid">
    __CARDS__
  </div>
</section>

<section>
  <h2>Confiance et transparence</h2>
  <ul class="trust-list">
    <li><strong>100 % Open Source</strong> : Code entièrement auditable dans le dépôt GitHub.</li>
    <li><strong>Binaire officiel</strong> : Télécharge directement le moteur depuis <code>tphakala/birdnet-go</code>, jamais recompilé.</li>
    <li><strong>Vérification cryptographique</strong> : Le hash SHA-256 est comparé avant toute installation.</li>
    <li><strong>Vie privée</strong> : Tout reste en local. Aucune donnée audio n'est envoyée vers le cloud.</li>
  </ul>
</section>
</main>

<footer>
  <p>Généré le __NOW__ · <a href="https://github.com/__REPO__">Dépôt du contrôleur</a> · <a href="https://github.com/__UPSTREAM__">Projet officiel BirdNET-Go</a></p>
  <p style="margin-top: 8px; opacity: 0.7;">Projet communautaire indépendant. Licence MIT.</p>
</footer>

</div>
<script>
// 1. Détection automatique de l'OS pour mettre en avant la bonne carte
const ua = navigator.userAgent.toLowerCase();
let detectedOs = 'windows';
if (ua.indexOf('mac') !== -1) detectedOs = 'macos';
else if (ua.indexOf('linux') !== -1) detectedOs = 'linux';

document.querySelectorAll('.download-card').forEach(card => {
  if (card.dataset.os === detectedOs) {
    card.classList.add('recommended');
    const badge = card.querySelector('.recommended-badge');
    if (badge) badge.style.display = 'block';
  }
});

// 2. Gestion de la copie du hash avec feedback visuel
document.querySelectorAll('.btn-copy').forEach(function(b) {
  b.addEventListener('click', function() {
    navigator.clipboard.writeText(b.dataset.copy).then(function() {
      const original = b.innerHTML; 
      b.innerHTML = '✓ Copié'; 
      b.style.borderColor = 'var(--success)';
      b.style.color = 'var(--success)';
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

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================
def main():
    try:
        releases = load_json(RELEASES_FILE) or []
        stable = pick_latest(releases, nightly=False)
        
        stable_tag = (stable or {}).get("tag_name") or "Inconnue"
        
        # Génère toutes les cartes d'un coup
        cards_html = "".join(build_platform_card(k, stable) for k in ASSET_MAP)
        if not cards_html:
            cards_html = "<p style='color:var(--muted); grid-column: 1/-1; text-align:center; padding: 40px;'>Aucune release stable disponible pour le moment.</p>"
        
        now = datetime.now(timezone.utc).strftime("%d %b %Y")
        
        # Remplacement sécurisé (immunisé contre les formateurs de code)
        page = HTML_TEMPLATE
        page = page.replace("__UPSTREAM__", UPSTREAM)
        page = page.replace("__REPO__", REPO)
        page = page.replace("__STABLE_TAG__", html.escape(stable_tag))
        page = page.replace("__CARDS__", cards_html)
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
