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

# 3. Récupération de la dernière version
echo "[...] Recherche de la dernière version..."
LATEST_TAG=$(curl -s https://api.github.com/repos/tphakala/birdnet-go/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
    echo "❌ Impossible de trouver la dernière version."
    exit 1
fi
echo "[OK] Version détectée : $LATEST_TAG"

# 4. Téléchargement du binaire natif (Correction du nom de l'archive)
if [ "$ARCH" = "x86_64" ]; then
    ARCH_NAME="amd64"
else
    ARCH_NAME="arm64"
fi

# Le format exact utilisé par BirdNET-Go est : gobirdnet_<version>_linux_<arch>.tar.gz
ARCHIVE_URL="https://github.com/tphakala/birdnet-go/releases/download/${LATEST_TAG}/gobirdnet_${LATEST_TAG}_linux_${ARCH_NAME}.tar.gz"
TMP_DIR=$(mktemp -d)
echo "[...] Téléchargement de l'archive ($ARCH_NAME)..."
curl -sL -o "$TMP_DIR/birdnet.tar.gz" "$ARCHIVE_URL"

# 5. Installation
echo "[...] Installation dans $INSTALL_DIR..."
# Si on est root (dans Docker), pas besoin de sudo.
if [ "$EUID" -eq 0 ]; then
    mkdir -p "$INSTALL_DIR"
    tar -xzf "$TMP_DIR/birdnet.tar.gz" -C "$INSTALL_DIR" --strip-components=1
else
    sudo mkdir -p "$INSTALL_DIR"
    sudo tar -xzf "$TMP_DIR/birdnet.tar.gz" -C "$INSTALL_DIR" --strip-components=1
    sudo chown -R "$USER":"$USER" "$INSTALL_DIR"
fi
rm -rf "$TMP_DIR"

# 6. Création du service systemd (Uniquement sur un vrai système)
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
