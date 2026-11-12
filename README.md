# Installation automatique de BirdNET-Go (Windows)

Installe la dernière version de [BirdNET-Go](https://github.com/tphakala/birdnet-go)
sur Windows (x64 / ARM64) via un `.exe` auto-généré.

## Téléchargement

Récupérez le dernier `BirdNET-Go-Installer.exe` dans la section
[**Releases**](../../releases).

## ⚠️ Avertissement Windows SmartScreen

Cet exécutable **n'est pas signé numériquement** (pas de certificat de signature).
Au premier lancement, Windows peut afficher :

> Windows a protégé votre PC — Application inconnue

C'est **normal** pour un `.exe` non signé. Pour l'exécuter :

1. Cliquez sur **"Informations complémentaires"**.
2. Cliquez sur **"Exécuter quand même"**.

**Alternative** : clic droit sur le `.exe` → **Propriétés** → cocher
**"Débloquer"** en bas → **OK**. Cela retire le marqueur Mark-of-the-Web.

## Vérification d'intégrité

Chaque Release indique le **SHA-256** du `.exe`. Pour vérifier :

```powershell
Get-FileHash .\BirdNET-Go-Installer.exe -Algorithm SHA256
