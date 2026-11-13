#!/usr/bin/env bash

# Arrêt en cas d'erreur
set -e

echo "=== Installation de BirdNET-Go pour Raspberry Pi / Linux ARM64 ==="

# 1. Dossier d'installation (modifiable via une variable d'environnement pour les tests)
INSTALL_DIR="${INSTALL_DIR:-/opt/birdnet-go}"

# 2. Vérification de l'architecture (64 bits requis pour les performances)
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

# 4. Téléchargement du binaire natif
if [ "$ARCH" = "x86_64" ]; then
    ARCH_NAME="amd64"
else
    ARCH_NAME="arm64"
fi

ARCHIVE_URL="https://github.com/tphakala/birdnet-go/releases/download/${LATEST_TAG}/birdnet-go-linux-${ARCH_NAME}.tar.gz"
TMP_DIR=$(mktemp -d)
echo "[...] Téléchargement de l'archive ($ARCH_NAME)..."
curl -sL -o "$TMP_DIR/birdnet.tar.gz" "$ARCHIVE_URL"

# 5. Installation (Création automatique du dossier)
echo "[...] Installation dans $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo tar -xzf "$TMP_DIR/birdnet.tar.gz" -C "$INSTALL_DIR" --strip-components=1
sudo chown -R $USER:$USER "$INSTALL_DIR"
rm -rf "$TMP_DIR"

# 6. Création du service systemd (uniquement si on est sur un vrai système avec systemd)
if command -v systemctl >/dev/null 2>&1 && [ "$INSTALL_DIR" = "/opt/birdnet-go" ]; then
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
    echo "✅ Service systemd configuré et démarré."
fi

echo ""
echo "✅ BirdNET-Go $LATEST_TAG a été installé avec succès dans $INSTALL_DIR !"
