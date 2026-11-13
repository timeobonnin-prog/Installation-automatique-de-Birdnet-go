#!/usr/bin/env bash

# Arrêt en cas d'erreur
set -e

echo "=== Installation de BirdNET-Go pour Linux / Raspberry Pi ==="

# 1. Dossier d'installation
INSTALL_DIR="${INSTALL_DIR:-/opt/birdnet-go}"

# 2. Vérification de l'architecture
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ] && [ "$ARCH" != "x86_64" ]; then
    echo "❌ Erreur : Architecture non supportée ($ARCH)."
    exit 1
fi

if [ "$ARCH" = "x86_64" ]; then
    ARCH_NAME="amd64"
else
    ARCH_NAME="arm64"
fi

# 3. Récupération des infos de la dernière version via l'API GitHub
echo "[...] Recherche de la dernière version..."
API_JSON=$(curl -s https://api.github.com/repos/tphakala/birdnet-go/releases/latest)

LATEST_TAG=$(echo "$API_JSON" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$LATEST_TAG" ]; then
    echo "❌ Impossible de trouver la dernière version."
    exit 1
fi
echo "[OK] Version détectée : $LATEST_TAG"

# 4. Extraction de l'URL exacte de téléchargement depuis l'API
# On cherche la ligne qui contient "browser_download_url" et "linux_amd64.tar.gz"
ARCHIVE_URL=$(echo "$API_JSON" | grep "browser_download_url.*linux_${ARCH_NAME}.tar.gz" | cut -d '"' -f 4)

if [ -z "$ARCHIVE_URL" ]; then
    echo "❌ Impossible de trouver l'URL de l'archive pour Linux $ARCH_NAME."
    exit 1
fi

# 5. Téléchargement
TMP_DIR=$(mktemp -d)
echo "[...] Téléchargement de l'archive depuis $ARCHIVE_URL..."
curl -sL -o "$TMP_DIR/birdnet.tar.gz" "$ARCHIVE_URL"

# 6. Installation
echo "[...] Installation dans $INSTALL_DIR..."
if [ "$EUID" -eq 0 ]; then
    mkdir -p "$INSTALL_DIR"
    tar -xzf "$TMP_DIR/birdnet.tar.gz" -C "$INSTALL_DIR" --strip-components=1
else
    sudo mkdir -p "$INSTALL_DIR"
    sudo tar -xzf "$TMP_DIR/birdnet.tar.gz" -C "$INSTALL_DIR" --strip-components=1
    sudo chown -R "$USER":"$USER" "$INSTALL_DIR"
fi
rm -rf "$TMP_DIR"

# 7. Création du service systemd (uniquement si on est sur un vrai système, pas dans Docker)
if command -v systemctl >/dev/null 2>&1 && [ "$INSTALL_DIR" = "/opt/birdnet-go" ] && [ "$EUID" -ne 0 ]; then
    echo "[...] Création du service systemd..."
    sudo bash -c "cat > /etc/systemd/system/birdnet-go.service <<EOF
[Unit]
Description=BirdNET-Go Service
After=network.target sound.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/birdnet-go
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF"

    sudo systemctl daemon-reload
    sudo systemctl enable birdnet-go
    sudo systemctl start birdnet-go
fi

echo "✅ BirdNET-Go $LATEST_TAG a été installé avec succès dans $INSTALL_DIR !"
