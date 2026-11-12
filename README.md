# Installation automatique de BirdNET-Go (Windows)

Installe la dernière version de [BirdNET-Go](https://github.com/tphakala/birdnet-go)
sur Windows (x64 / ARM64) via un `.exe` auto-généré.

## Téléchargement

Récupère le dernier `BirdNET-Go-Installer.exe` dans la section
[**Releases**](../../releases) de ce dépôt.

## Fonctionnement

1. `install-birdnet.ps1` détecte l'architecture du PC et télécharge le bon
   asset depuis la dernière release de BirdNET-Go.
2. `BirdNET-Go-Installer.iss` (Inno Setup) empaquette ce script dans un `.exe`.
3. `.github/workflows/build-release.yml` compile, scanne avec VirusTotal,
   puis publie la Release automatiquement.
4. `.github/workflows/update-birdnet-version.yml` vérifie chaque jour les
   nouvelles versions de BirdNET-Go et déclenche le build.

## Installation manuelle (sans le .exe)

```powershell
powershell -ExecutionPolicy Bypass -File install-birdnet.ps1
