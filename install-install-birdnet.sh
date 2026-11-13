#!/usr/bin/env bash

# Arrêt en cas d'erreur
set -e

echo "=== Installation de BirdNET-Go pour Raspberry Pi / Linux ARM64 ==="

# 1. Vérification de l'architecture (64 bits requis pour les performances)
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    echo "❌ Erreur : Ce script nécessite une architecture 64 bits (aarch64/arm64)."
    echo "Architecture détectée : $ARCH"
    exit 1
fi

# 2. Récupération de la dernière version
echo "[...] Recherche de la dernière version..."
LATEST_TAG=$(curl -s https://api.github.com/repos/tphakala/birdnet-go/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
    echo "❌ Impossible de trouver la dernière version."
    exit 1
fi
echo "[OK] Version détectée : $LATEST_TAG"

# 3. Téléchargement du binaire natif Linux ARM64
# Le nom du fichier suit généralement le format birdnet-go-linux-arm64.tar.gz
ARCHIVE_URL="https://github.com/tphakala/birdnet-go/releases/download/${LATEST_TAG}/birdnet-go-linux-arm64.tar.gz"
TMP_DIR=$(mktemp -d)
echo "[...] Téléchargement de l'archive..."
curl -L -o "$TMP_DIR/birdnet.tar.gz" "$ARCHIVE_URL"

# 4. Installation
INSTALL_DIR="/opt/birdnet-go"
echo "[...] Installation dans $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo tar -xzf "$TMP_DIR/birdnet.tar.gz" -C "$INSTALL_DIR" --strip-components=1
sudo chown -R $USER:$USER "$INSTALL_DIR"

# 5. Création du service systemd
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

# 6. Démarrage du service
sudo systemctl daemon-reload
sudo systemctl enable birdnet-go
sudo systemctl start birdnet-go

echo ""
echo "✅ BirdNET-Go $LATEST_TAG a été installé avec succès !"
echo "L'interface est accessible sur : http://localhost:8080"
echo "Pour voir les logs : sudo journalctl -u birdnet-go -f"
