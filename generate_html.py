#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# ⚠️ NE PAS FORMATER CE FICHIER (Prettier, Black, etc.) — voir .prettierignore
# ==============================================================================
"""
Génère index.html + update.json. Design "hand-crafted" :
disclaimer officiel visible, 1 seule carte recommandée par OS,
captures sans déformation, grille propre, léger et accessible.
"""

import json, os, re, html, sys
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

RELEASES_FILE = "releases.json"
OUT_HTML = "index.html"
OUT_JSON = "update.json"
REPO = "timeobonnin-prog/Installation-automatique-de-Birdnet-go"
UPSTREAM = "tphakala/birdnet-go"

# (asset, os_key, primary, titre, sous-titre, emoji, accent)
ASSET_MAP = {
    "windows":     ("BirdNET-Go-Windows.exe",          "windows", True,  "Windows",            ".exe · x64",        "🪟", "#38bdf8"),
    "windows_zip": ("BirdNET-Go-Windows-Portable.zip", "windows", False, "Windows Portable",   ".zip · x64",        "📦", "#38bdf8"),
    "linux_x64":   ("BirdNET-Go-Linux-x64.deb",        "linux",   True,  "Linux x64",          ".deb · amd64",      "🐧", "#a6e3a1"),
    "raspberry":   ("BirdNET-Go-RaspberryPi.deb",      "linux",   False, "Raspberry Pi",       ".deb · arm64",      "🍓", "#a6e3a1"),
    "macos":       ("BirdNET-Go-macOS.pkg",            "macos",   True,  "macOS (ARM)",        ".pkg · arm64",      "🍎", "#cba6f7"),
}

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

def build_card(key: str, release: Dict[str, Any]) -> str:
    name, os_key, primary, title, sub, emoji, accent = ASSET_MAP[key]
    asset = find_asset(release, name)
    if not asset: return ""
    url = html.escape(asset.get("browser_download_url", "#"))
    size = fmt_size(asset.get("size"))
    sha = sha256_from_asset(asset)
    sha_html = ""
    if sha:
        vt = f"https://www.virustotal.com/gui/file/{sha}"
        sha_html = (
            '<div class="sha-block">'
            '<div class="sha-row"><span class="sha-label">SHA-256</span>'
            f'<code title="{sha}">{sha[:16]}…{sha[-16:]}</code></div>'
            '<div class="sha-actions">'
            f'<button class="btn-copy" data-copy="{sha}" aria-label="Copier le hash">⧉ Copier</button>'
            f'<a class="btn-vt" href="{vt}" target="_blank" rel="noopener">🛡️ VirusTotal</a>'
            '</div></div>'
        )
    flag = ' data-primary="1"' if primary else ''
    return (
        f'<article class="dl-card" data-os="{os_key}"{flag} style="--accent:{accent}">'
        '<span class="rec-pill">✨ Recommandé pour vous</span>'
        '<div class="dl-head"><span class="dl-emoji" aria-hidden="true">' + emoji + '</span>'
        f'<div><h3 class="dl-title">{html.escape(title)}</h3>'
        f'<p class="dl-sub">{html.escape(sub)} · {size}</p></div></div>'
        f'<a class="btn-dl" href="{url}" download aria-label="Télécharger {html.escape(title)}">'
        '<span>Télécharger</span>'
        '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg></a>'
        f'{sha_html}</article>'
    )

def build_update_json(release: Optional[Dict[str, Any]]) -> Dict[str, Any]:
    asset = find_asset(release, "BirdNET-Go-Windows.exe") if release else None
    return {
        "tag": release.get("tag_name") if release else None,
        "prerelease": bool(release.get("prerelease")) if release else False,
        "url": asset.get("browser_download_url") if asset else None,
        "sha256": sha256_from_asset(asset),
    }

HTML_TEMPLATE = """<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="dark">
<meta name="description" content="Panneau de contrôle local et sécurisé pour BirdNET-Go. Projet communautaire non officiel.">
<title>BirdNET-Go Control — Installateur communautaire</title>
<link rel="icon" href="assets/logo.png" type="image/png">
<style>
:root{
  --bg:#0c0c10; --text:#e2e8f0; --muted:#94a3b8; --dim:#64748b;
  --accent:#38bdf8; --glow:rgba(56,189,248,.18); --success:#4ade80; --warn:#f9e2af; --danger:#f87171;
  --card:rgba(30,41,59,.45); --line:rgba(255,255,255,.07); --r:14px;
}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;background-color:var(--bg);color:var(--text);line-height:1.6;-webkit-font-smoothing:antialiased;
  background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='2'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.035'/%3E%3C/svg%3E")}
a{color:var(--accent);text-decoration:none;transition:opacity .2s}a:hover{opacity:.8}
.wrap{max-width:980px;margin:0 auto;padding:0 22px}

/* --- Header + disclaimer fort --- */
header{padding:52px 0 28px;text-align:center}
.logo-row{display:flex;align-items:center;justify-content:center;gap:14px;margin-bottom:14px}
.logo-row img{width:54px;height:54px;border-radius:12px}
h1{font-size:clamp(28px,5vw,42px);font-weight:800;letter-spacing:-.02em;color:#fff}
.tagline{color:var(--muted);font-size:18px;max-width:560px;margin:14px auto 0}
.disclaimer-pill{display:inline-flex;align-items:center;gap:8px;margin-top:18px;padding:8px 16px;border-radius:99px;
  background:rgba(248,113,113,.12);border:1px solid rgba(248,113,113,.35);color:#fecaca;font-weight:700;font-size:14px}
.disclaimer-pill a{color:#fff;text-decoration:underline}
.ver-pill{display:inline-flex;gap:8px;align-items:center;margin-top:14px;padding:5px 14px;border-radius:99px;
  background:rgba(56,189,248,.1);border:1px solid rgba(56,189,248,.25);color:var(--accent);font-size:13px;font-weight:600}

section{margin:56px 0}
h2{font-size:21px;font-weight:700;color:#fff;margin-bottom:20px;display:flex;align-items:center;gap:10px}
h2::before{content:'';width:4px;height:20px;background:var(--accent);border-radius:2px}
.lead{color:var(--muted);font-size:14px;margin:-8px 0 18px}

/* --- Étapes --- */
.steps{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px}
.step{background:var(--card);border:1px solid var(--line);border-radius:var(--r);padding:22px;position:relative;transition:transform .2s,border-color .2s}
.step:hover{transform:translateY(-2px);border-color:rgba(255,255,255,.14)}
.step-n{position:absolute;top:-12px;left:18px;width:30px;height:30px;border-radius:50%;background:var(--bg);
  border:1px solid var(--accent);color:var(--accent);font-weight:800;display:flex;align-items:center;justify-content:center}
.step h3{font-size:15px;color:#fff;margin:10px 0 6px}
.step p{color:var(--muted);font-size:14px}

/* --- Aperçu : images à leur vrai ratio --- */
.shots{display:grid;grid-template-columns:1.6fr 1fr;gap:14px}
.shot{background:#0a0a0d;border:1px solid var(--line);border-radius:var(--r);overflow:hidden}
.shot img{width:100%;height:auto;display:block}
.shot-col{display:flex;flex-direction:column;gap:14px}
@media(max-width:640px){.shots{grid-template-columns:1fr}}

/* --- Téléchargements --- */
.dl-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:16px}
.dl-card{background:var(--card);border:1px solid var(--line);border-left:3px solid var(--accent);border-radius:var(--r);
  padding:20px;display:flex;flex-direction:column;gap:14px;position:relative;transition:transform .2s,box-shadow .2s,border-color .2s}
.dl-card:hover{transform:translateY(-3px)}
.dl-card.is-recommended{border-color:var(--accent);box-shadow:0 0 0 1px var(--accent),0 14px 36px -16px var(--glow);order:-1}
.rec-pill{position:absolute;top:-11px;right:14px;background:var(--accent);color:#06121f;font-size:11px;font-weight:800;
  padding:4px 11px;border-radius:99px;text-transform:uppercase;letter-spacing:.04em;display:none}
.dl-card.is-recommended .rec-pill{display:block}
.dl-head{display:flex;align-items:flex-start;gap:12px}
.dl-emoji{font-size:26px;line-height:1}
.dl-title{font-size:16px;font-weight:700;color:#fff}
.dl-sub{font-size:13px;color:var(--dim);margin-top:2px}
.btn-dl{display:flex;align-items:center;justify-content:center;gap:8px;background:#fff;color:#0f172a;font-weight:700;
  font-size:14px;padding:11px;border-radius:10px;transition:filter .2s,transform .2s}
.btn-dl:hover{filter:brightness(.92);transform:translateY(-1px)}
.sha-block{margin-top:auto;padding-top:12px;border-top:1px solid var(--line);font-size:12px}
.sha-row{display:flex;align-items:center;gap:8px;margin-bottom:8px;font-family:ui-monospace,Menlo,monospace}
.sha-label{background:rgba(74,222,128,.12);color:var(--success);padding:2px 7px;border-radius:5px;font-size:10px;font-weight:800;font-family:system-ui}
.sha-row code{color:var(--muted);word-break:break-all}
.sha-actions{display:flex;gap:8px}
.btn-copy,.btn-vt{flex:1;text-align:center;padding:7px;border-radius:7px;font-size:12px;font-weight:600;cursor:pointer;border:none;text-decoration:none;transition:all .2s}
.btn-copy{background:rgba(255,255,255,.05);color:var(--text);border:1px solid var(--line)}
.btn-copy:hover{background:rgba(255,255,255,.1);border-color:var(--accent)}
.btn-vt{background:rgba(74,222,128,.1);color:var(--success);border:1px solid rgba(74,222,128,.2)}
.btn-vt:hover{background:rgba(74,222,128,.2)}

/* --- Bandeau NON OFFICIEL dédié --- */
.official-box{background:rgba(248,113,113,.07);border:1px solid rgba(248,113,113,.3);border-left:4px solid var(--danger);
  border-radius:var(--r);padding:22px 24px}
.official-box h2{margin-bottom:10px}
.official-box h2::before{background:var(--danger)}
.official-box p{color:var(--muted);font-size:15px;margin-bottom:10px}
.official-box strong{color:#fecaca}
.official-box .go-official{display:inline-flex;align-items:center;gap:8px;margin-top:6px;background:var(--danger);color:#1a0505;
  font-weight:700;padding:9px 16px;border-radius:9px}
.official-box .go-official:hover{filter:brightness(1.08);opacity:1}

/* --- Confiance --- */
.trust{list-style:none;display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:14px}
.trust li{display:flex;gap:10px;color:var(--muted);font-size:14px;background:var(--card);border:1px solid var(--line);
  border-radius:12px;padding:16px}
.trust li::before{content:'✓';color:var(--success);font-weight:800}
.trust b{color:#fff}

footer{text-align:center;color:var(--dim);font-size:13px;padding:40px 0;border-top:1px solid var(--line);margin-top:56px}
footer .not-official{color:var(--danger);font-weight:700;margin-bottom:6px}
</style>
</head>
<body>
<div class="wrap">

<header>
  <div class="logo-row"><img src="assets/logo.png" alt="Logo BirdNET-Go Control"><h1>BirdNET-Go Control</h1></div>
  <p class="tagline">Écoutez la nature chez vous. Un panneau de contrôle local, léger et sécurisé pour votre détecteur d'oiseaux.</p>
  <div class="disclaimer-pill">⚠️ Projet communautaire <strong>NON OFFICIEL</strong> — sans lien avec <a href="https://github.com/__UPSTREAM__" target="_blank" rel="noopener">tphakala/birdnet-go</a></div>
  <div><span class="ver-pill">📦 Version stable : <strong>__STABLE_TAG__</strong></span></div>
</header>

<main>
<section>
  <h2>Comment ça marche</h2>
  <div class="steps">
    <div class="step"><span class="step-n">1</span><h3>Installez le contrôle</h3><p>Téléchargez l'installateur ci-dessous. Il configure le moteur officiel et l'interface de gestion en un clic.</p></div>
    <div class="step"><span class="step-n">2</span><h3>Branchez votre micro</h3><p>Connectez un microphone USB à votre PC ou Raspberry Pi. L'application le détecte automatiquement.</p></div>
    <div class="step"><span class="step-n">3</span><h3>Écoutez la nature</h3><p>Lancez le serveur : l'IA analyse les sons en temps réel et vous alerte sur les espèces détectées.</p></div>
  </div>
</section>

<section>
  <h2>Aperçu de l'application</h2>
  <div class="shots">
    <div class="shot"><img src="screenshots/control.webp" alt="Tableau de bord de contrôle" loading="lazy" decoding="async"></div>
    <div class="shot-col">
      <div class="shot"><img src="screenshots/results.webp" alt="Résultats en direct" loading="lazy" decoding="async"></div>
      <div class="shot"><img src="screenshots/stats.webp" alt="Statistiques" loading="lazy" decoding="async"></div>
    </div>
  </div>
</section>

<section>
  <h2>Téléchargements sécurisés</h2>
  <p class="lead">Votre système est détecté automatiquement — la carte recommandée passe en premier. Chaque fichier affiche son empreinte SHA-256.</p>
  <div class="dl-grid">__CARDS__</div>
</section>

<section class="official-box">
  <h2>⚠️ Ce projet n'est PAS officiel</h2>
  <p><strong>BirdNET-Go Control</strong> est un panneau de contrôle créé par la communauté. Il n'est <strong>ni affilié, ni approuvé, ni maintenu</strong> par Tomi P. Hakala, l'auteur du moteur BirdNET-Go.</p>
  <p>Les binaires du moteur sont téléchargés <strong>directement et sans modification</strong> depuis les releases officielles de <code>__UPSTREAM__</code>, jamais recompilés par nos soins. Nous ne distribuons que l'interface de gestion.</p>
  <p>En cas de question sur le moteur lui-même, rendez-vous sur le dépôt officiel :</p>
  <a class="go-official" href="https://github.com/__UPSTREAM__" target="_blank" rel="noopener">🐦 Aller sur le projet officiel BirdNET-Go →</a>
</section>

<section>
  <h2>Confiance et transparence</h2>
  <ul class="trust">
    <li><b>100 % Open Source</b> : code auditable dans le dépôt GitHub.</li>
    <li><b>Binaire officiel</b> : moteur récupéré depuis <code>__UPSTREAM__</code>, jamais recompilé.</li>
    <li><b>Vérification SHA-256</b> : empreinte comparée avant toute installation.</li>
    <li><b>Vie privée</b> : tout reste local, aucune audio envoyée dans le cloud.</li>
  </ul>
</section>
</main>

<footer>
  <p class="not-official">⚠️ Projet communautaire indépendant — NON affilié au projet officiel BirdNET-Go.</p>
  <p>Généré le __NOW__ · <a href="https://github.com/__REPO__">Dépôt du contrôleur</a> · <a href="https://github.com/__UPSTREAM__">Projet officiel BirdNET-Go</a> · Licence MIT</p>
</footer>

</div>
<script>
(function(){
  var ua=navigator.userAgent.toLowerCase();
  var os='windows';
  if(ua.indexOf('mac')!==-1)os='macos';
  else if(ua.indexOf('linux')!==-1||ua.indexOf('android')!==-1)os='linux';
  var cards=document.querySelectorAll('.dl-card');
  var chosen=null;
  cards.forEach(function(c){
    if(c.dataset.os===os && c.dataset.primary==='1'){chosen=c;}
  });
  if(!chosen){ // fallback : première primary windows
    cards.forEach(function(c){if(!chosen&&c.dataset.os==='windows'&&c.dataset.primary==='1')chosen=c;});
  }
  if(chosen)chosen.classList.add('is-recommended');

  document.querySelectorAll('.btn-copy').forEach(function(b){
    b.addEventListener('click',function(){
      navigator.clipboard.writeText(b.dataset.copy).then(function(){
        var o=b.innerHTML;b.innerHTML='✓ Copié';b.style.borderColor='var(--success)';b.style.color='var(--success)';
        setTimeout(function(){b.innerHTML=o;b.style.borderColor='';b.style.color='';},1500);
      });
    });
  });
})();
</script>
</body>
</html>"""

def main():
    try:
        releases = load_json(RELEASES_FILE) or []
        stable = pick_latest(releases, nightly=False)
        stable_tag = (stable or {}).get("tag_name") or "Inconnue"
        cards = "".join(build_card(k, stable) for k in ASSET_MAP)
        if not cards:
            cards = "<p style='color:var(--muted);grid-column:1/-1;text-align:center;padding:30px'>Aucune release stable disponible.</p>"
        now = datetime.now(timezone.utc).strftime("%d %b %Y")

        page = HTML_TEMPLATE
        page = page.replace("__UPSTREAM__", UPSTREAM)
        page = page.replace("__REPO__", REPO)
        page = page.replace("__STABLE_TAG__", html.escape(stable_tag))
        page = page.replace("__CARDS__", cards)
        page = page.replace("__NOW__", now)

        with open(OUT_HTML, "w", encoding="utf-8") as f:
            f.write(page)
        print(f"✅ {OUT_HTML} généré ({len(page)} octets)")

        with open(OUT_JSON, "w", encoding="utf-8") as f:
            json.dump(build_update_json(stable), f, indent=2)
        print(f"✅ {OUT_JSON} généré")
    except Exception as e:
        print(f"❌ Erreur fatale : {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
