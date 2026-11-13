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

# 3. Authentification (si GITHUB_TOKEN est fourni, on l'utilise)
AUTH_HEADER=""
if [ -n "$GITHUB_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"
    echo "[OK] Utilisation du GITHUB_TOKEN pour éviter les limites d'API."
else
    echo "[ATTENTION] Pas de GITHUB_TOKEN. Risque de blocage par l'API GitHub."
fi

# 4. Récupération des infos via l'API GitHub
echo "[...] Recherche de la dernière version..."
API_JSON=$(curl -s -H "User-Agent: GitHub-Actions" -H "$AUTH_HEADER" https://api.github.com/repos/tphakala/birdnet-go/releases/latest)

# Vérification si l'API a renvoyé une erreur (Rate Limit)
if echo "$API_JSON" | grep -q "API rate limit exceeded"; then
    echo "❌ Erreur : Limite d'API GitHub atteinte. Veuillez réessayer plus tard."
    exit 1
fi

if command -v jq >/dev/null 2>&1; then
    LATEST_TAG=$(echo "$API_JSON" | jq -r .tag_name)
    ARCHIVE_URL=$(echo "$API_JSON" | jq -r ".assets[] | select(.name | contains(\"linux_${ARCH_NAME}.tar.gz\")) | .browser_download_url" | head -n 1)
else
    LATEST_TAG=$(echo "$API_JSON" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)
    ARCHIVE_URL=$(echo "$API_JSON" | grep "browser_download_url.*linux_${ARCH_NAME}.tar.gz" | cut -d '"' -f 4 || true)
fi

if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" = "null" ]; then
    echo "❌ Impossible de trouver la dernière version. Voici la réponse de l'API :"
    echo "$API_JSON"
    exit 1
fi
echo "[OK] Version détectée : $LATEST_TAG"

if [ -z "$ARCHIVE_URL" ] || [ "$ARCHIVE_URL" = "null" ]; then
    echo "❌ Impossible de trouver l'URL de l'archive pour Linux $ARCH_NAME."
    exit 1
fi

# 5. Téléchargement
TMP_DIR=$(mktemp -d)
echo "[...] Téléchargement de l'archive depuis $ARCHIVE_URL..."
curl -fsSL -o "$TMP_DIR/birdnet.tar.gz" "$ARCHIVE_URL"

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

# 7. Création du service systemd
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
