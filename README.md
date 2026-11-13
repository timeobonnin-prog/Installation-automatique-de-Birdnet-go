# 🪶 Installation automatique de BirdNET-Go

<p align="center">
  <a href="https://github.com/timeobonnin-prog/Installation-automatique-de-Birdnet-go/releases/latest"><img src="https://img.shields.io/github/v/release/timeobonnin-prog/Installation-automatique-de-Birdnet-go?style=flat-square" alt="Latest Release"></a>
  <a href="https://github.com/timeobonnin-prog/Installation-automatique-de-Birdnet-go/blob/main/LICENSE"><img src="https://img.shields.io/github/license/timeobonnin-prog/Installation-automatique-de-Birdnet-go?style=flat-square" alt="License"></a>
  <a href="https://github.com/timeobonnin-prog/Installation-automatique-de-Birdnet-go/actions"><img src="https://img.shields.io/github/actions/workflow/status/timeobonnin-prog/Installation-automatique-de-Birdnet-go/build-release.yml?style=flat-square" alt="Build Status"></a>
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue?style=flat-square" alt="Platforms">
</p>

Ce dépôt fournit des installateurs automatisés pour déployer facilement la dernière version de [BirdNET-Go](https://github.com/tphakala/birdnet-go) sur **Windows**, **Linux (Debian/Ubuntu)**, **Raspberry Pi** et **macOS**.

Chaque mise à jour est détectée automatiquement, compilée, testée, scannée par VirusTotal, et publiée dans la section Releases.

---

## 📥 Installation sur Windows (x64 / ARM64)

1. Rendez-vous dans la section [**Releases**](../../releases).
2. Téléchargez le fichier **`BirdNET-Go-Windows.exe`** (environ 96 Mo).
3. Double-cliquez dessus. L'installateur fera tout le travail : il créera un raccourci sur votre Bureau, ajoutera le dossier au PATH de Windows, et configurera le pare-feu.

**Note :** Cet installateur est "hors-ligne". Il contient déjà le binaire et les modèles d'IA. Il ne télécharge rien.

### ⚠️ Avertissement Windows SmartScreen
Cet exécutable n'étant pas encore signé numériquement, Windows peut afficher un écran bleu : *"Windows a protégé votre PC"*. Cliquez sur **"Informations complémentaires"** puis **"Exécuter quand même"**.

---

## 🐧 Installation sur Linux (Debian/Ubuntu) et 🍓 Raspberry Pi

Téléchargez le fichier **`.deb`** correspondant à votre architecture (amd64 pour PC, arm64 pour Raspberry Pi) dans les Releases, puis installez-le :

```bash
sudo dpkg -i birdnet-go_*.deb
