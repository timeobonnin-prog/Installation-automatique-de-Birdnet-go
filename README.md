<div align="center">
  <img src="logo.png" alt="BirdNET-Go Control" width="160" />
  <h1>🐦 BirdNET-Go Control</h1>
  <p><strong>Panneau de contrôle multilingue pour BirdNET-Go</strong> — le détecteur d'oiseaux auto-hébergé.</p>
  <p>
    <a href="https://github.com/timeobonnin-prog/Installation-automatique-de-Birdnet-go/actions/workflows/build-and-release.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/timeobonnin-prog/Installation-automatique-de-Birdnet-go/build-and-release.yml?label=Build" alt="Build" />
    </a>
    <img src="https://img.shields.io/badge/license-MIT-green" alt="License" />
    <img src="https://img.shields.io/badge/langues-16-blue" alt="16 langues" />
  </p>
  <p><em>⚠️ Projet communautaire non officiel — BirdNET-Go officiel : <a href="https://github.com/tphakala/birdnet-go">tphakala/birdnet-go</a></em></p>
</div>

---

## ✨ Fonctionnalités

- **🎛️ Contrôle serveur** : démarrer/arrêter `birdnet-go.exe` en 1 clic, watchdog anti-crash (jusqu'à 3 redémarrages auto), synchronisation du port avec `config.yaml` du moteur
- **📊 Résultats en direct** : pastille qui pulse quand le moteur écoute, latence ms, détections du jour, dernière espèce
- **📈 Statistiques** : sparkline 24 h, top 5 espèces, export CSV
- **🔄 Mises à jour in-app** : MAJ contrôleur + moteur en 1 clic, vérification SHA-256 avant installation
- **🌍 16 langues** : FR, EN, DE, ES, IT, PT, NL, PL, CS, SK, HU, DA, SV, NB, FI, LV — avec aperçu instantané
- **💾 Backup / Restore** : sauvegarde zip horodatée des réglages + config moteur
- **📜 Visionneuse de logs** intégrée
- **⌨️ Raccourci global** : `Ctrl+Alt+B` pour afficher depuis n'importe où
- **🔒 Single-instance** : mutex + NamedPipe pour éviter les doublons
- **📦 Self-contained** : aucun runtime .NET requis chez l'utilisateur

---

## 🔐 Sécurité — 4 garanties

1. **Téléchargement depuis la source officielle** — les binaires de BirdNET-Go proviennent **directement** des releases de `tphakala/birdnet-go`, jamais recompilés
2. **Vérification SHA-256** — chaque installateur est hashé et comparé au digest GitHub officiel **avant exécution** ; en cas de mismatch, l'installation est annulée
3. **Code 100 % open source** — tout le code du contrôleur est dans `src/`, auditable
4. **Canal de MAJ statique** — l'app lit `update.json` publié sur GitHub Pages (aucune quota API, aucune limite de débit)

---

## 📥 Installation

| Plateforme      | Fichier                      | Commande                                                                       |
| --------------- | ---------------------------- | ------------------------------------------------------------------------------ |
| 🪟 Windows      | `BirdNET-Go-Windows.exe`     | Double-clic (installateur) ou `BirdNET-Go-Windows-Portable.zip` (sans install) |
| 🐧 Linux x64    | `BirdNET-Go-Linux-x64.deb`   | `sudo apt install ./BirdNET-Go-Linux-x64.deb`                                  |
| 🍓 Raspberry Pi | `BirdNET-Go-RaspberryPi.deb` | `sudo apt install ./BirdNET-Go-RaspberryPi.deb`                                |
| 🍎 macOS (ARM)  | `BirdNET-Go-macOS.pkg`       | Double-clic                                                                    |

> Les releases sont publiées automatiquement via GitHub Actions à chaque commit sur `main` et chaque jour à 15 h 55 UTC.

---

## 🖥️ Captures

| Contrôle                            | Résultats                            | Statistiques                            |
| ----------------------------------- | ------------------------------------ | --------------------------------------- |
| _(ajouter capture onglet Contrôle)_ | _(ajouter capture onglet Résultats)_ | _(ajouter capture onglet Statistiques)_ |

---

## ⚙️ Paramètres d'installation avancés (Windows)

Port personnalisé (par défaut 8080) :

```
BirdNET-Go-Windows.exe /VERYSILENT /PORT=9090
```

Mode réparation (réinstalle sans toucher aux réglages) :

```
BirdNET-Go-Windows.exe /REPAIR
```

Installation silencieuse complète :

```
BirdNET-Go-Windows.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /PORT=8080
```

---

## 🏗️ Développer

```
dotnet run --project src/BirdNET-Go-Control.csproj
```

Prérequis : .NET 8 SDK, Windows (WPF).

---

## 🤝 Contribuer

Les PR sont les bienvenues ! Avant d'ouvrir une PR :

- `dotnet build src/BirdNET-Go-Control.csproj` doit passer sans erreur
- Ajouter les clés de traduction dans `src/Loc.cs` pour les 16 langues si vous ajoutez du texte
- Les commits suivent [Conventional Commits](https://www.conventionalcommits.org/)

---

## 📄 Licence

MIT — voir [`LICENSE`](LICENSE).

**Non affilié** au projet officiel BirdNET-Go de Tomi P. Hakala ([tphakala/birdnet-go](https://github.com/tphakala/birdnet-go)), que nous remercions chaleureusement.
