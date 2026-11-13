# 🪶 Installation automatique de BirdNET-Go

Ce dépôt fournit des installateurs automatisés pour déployer facilement la dernière version de [BirdNET-Go](https://github.com/tphakala/birdnet-go) sur **Windows** et **Raspberry Pi / Linux ARM64**.

Chaque mise à jour de BirdNET-Go est détectée automatiquement, compilée, scannée par VirusTotal, et publiée ici dans la section Releases.

---

## 📥 Installation sur Windows (x64 / ARM64)

1. Rendez-vous dans la section [**Releases**](../../releases) de ce dépôt.
2. Téléchargez le fichier **`BirdNET-Go-Installer.exe`** de la version la plus récente.
3. Double-cliquez dessus pour lancer l'installation. Le script téléchargera et configurera BirdNET-Go automatiquement dans votre dossier utilisateur (`%LOCALAPPDATA%\BirdNET-Go`).

> ⚠️ **Avertissement Windows SmartScreen**
> 
> Cet exécutable n'étant pas signé numériquement (pas de certificat), Windows peut afficher un écran bleu : *"Windows a protégé votre PC — Application inconnue"*. 
> **C'est normal.** Pour continuer :
> 1. Cliquez sur **"Informations complémentaires"**.
> 2. Cliquez sur **"Exécuter quand même"**.
> 
> *Astuce : Vous pouvez aussi faire un clic droit sur le `.exe` → **Propriétés** → cocher **"Débloquer"** en bas → **OK**.*

---

## 🍓 Installation sur Raspberry Pi (et Linux ARM64)

Pour installer BirdNET-Go sur un Raspberry Pi 4 ou 5 (OS 64 bits requis), connectez-vous en SSH à votre appareil et exécutez cette commande :

```bash
curl -fsSL https://raw.githubusercontent.com/timeobonnin-prog/Installation-automatique-de-Birdnet-go/main/install-birdnet.sh | bash
