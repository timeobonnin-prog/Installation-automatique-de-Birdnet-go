# 🪶 Installation automatique de BirdNET-Go

Ce dépôt fournit des installateurs automatisés pour déployer facilement la dernière version de [BirdNET-Go](https://github.com/tphakala/birdnet-go) sur **Windows** et **Raspberry Pi / Linux ARM64**.

Chaque mise à jour de BirdNET-Go est détectée automatiquement, compilée, testée, scannée par VirusTotal, et publiée ici dans la section Releases.

---

## 📥 Installation sur Windows (x64 / ARM64)

1. Rendez-vous dans la section [**Releases**](../../releases) de ce dépôt.
2. Téléchargez le fichier **`BirdNET-Go-Installer.exe`** de la version la plus récente (environ 96 Mo).
3. Double-cliquez dessus pour lancer l'installation. 

**Note :** Cet installateur est "hors-ligne". Il contient déjà le binaire et les modèles d'IA de BirdNET-Go. Il ne télécharge rien pendant l'installation, ce qui le rend beaucoup plus sûr et beaucoup plus rapide.

### ⚠️ Avertissement Windows SmartScreen

Cet exécutable n'étant pas encore signé numériquement, Windows peut afficher un écran bleu : *"Windows a protégé votre PC — Application inconnue"*. 
**C'est normal.** Pour continuer :
1. Cliquez sur **"Informations complémentaires"**.
2. Cliquez sur **"Exécuter quand même"**.

*Astuce : Vous pouvez aussi faire un clic droit sur le `.exe` → **Propriétés** → cocher **"Débloquer"** en bas → **OK**.*

---

## 🍓 Installation sur Raspberry Pi (et Linux ARM64)

Pour installer BirdNET-Go sur un Raspberry Pi 4 ou 5 (OS 64 bits requis), connectez-vous en SSH à votre appareil et exécutez cette commande :

    curl -fsSL https://raw.githubusercontent.com/timeobonnin-prog/Installation-automatique-de-Birdnet-go/main/install-birdnet.sh | bash

**Ce que fait ce script :**
- Vérifie que votre système est bien en 64 bits.
- Télécharge la dernière version binaire native (optimisée pour ARM64, sans surcoût lié à Docker).
- L'installe dans le dossier `/opt/birdnet-go`.
- Crée un service `systemd` pour que BirdNET-Go démarre automatiquement avec votre Raspberry Pi.

Une fois installé, ouvrez votre navigateur et allez sur `http://<IP_DE_VOTRE_RASPBERRY>:8080`.

---

## 🛡️ Sécurité et Vérification d'intégrité

Nous prenons la sécurité au sérieux. Chaque version publiée est analysée par plus de 70 moteurs antivirus via VirusTotal. Grâce à notre installateur "hors-ligne", le taux de faux positifs est extrêmement faible (généralement 0 ou 1 sur 71).

**1. Analyse VirusTotal**
Dans la description de chaque Release, vous trouverez un lien direct vers le rapport d'analyse.

**2. Empreinte SHA-256**
Pour vérifier que le fichier `.exe` téléchargé est intact et n'a pas été altéré, comparez son empreinte avec celle indiquée dans la Release.

Ouvrez PowerShell et exécutez :
    Get-FileHash .\BirdNET-Go-Installer.exe -Algorithm SHA256

La valeur affichée doit correspondre exactement à celle indiquée dans la description de la Release GitHub.

---

## ⚙️ Comment fonctionne ce dépôt ? (Pour les curieux)

L'automatisation repose sur plusieurs workflows GitHub Actions :
- **`update-birdnet-version.yml`** : Vérifie chaque jour si une nouvelle version de BirdNET-Go est disponible.
- **`build-release.yml`** : À chaque modification ou nouvelle version, télécharge le binaire, compile l'installateur Inno Setup, le scanne avec VirusTotal, et publie une nouvelle Release (ex: `v20261031.1`).
- **Tests automatisés** : Des workflows dédiés testent l'installation sur Windows, Linux et simulent un Raspberry Pi (ARM64) pour garantir que tout fonctionne avant publication.

---

## 🔏 Code signing policy

Free code signing provided by [SignPath.io](https://signpath.io/), certificate by [SignPath Foundation](https://signpath.org/).

- **Committers and reviewers:** [timeobonnin-prog](https://github.com/timeobonnin-prog)
- **Approvers:** [timeobonnin-prog](https://github.com/timeobonnin-prog)
- **Privacy policy:** This program will not transfer any information to other networked systems unless specifically requested by the user or the person installing or operating it.

---

## 🛠️ Installation manuelle (Pour les développeurs)

Si vous préférez exécuter le script sans passer par le `.exe` sous Windows :

    powershell -ExecutionPolicy Bypass -File install-birdnet.ps1

---
*Projet open source sous licence MIT. Non affilié officiellement au projet BirdNET-Go.*
