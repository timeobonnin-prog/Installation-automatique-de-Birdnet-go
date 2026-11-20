#!/usr/bin/env bash

set -euo pipefail

echo "=== Installation de BirdNET-Go pour Linux / Raspberry Pi ==="

INSTALL_DIR="${INSTALL_DIR:-/opt/birdnet-go}"

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
  ARCH_NAME="amd64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
  ARCH_NAME="arm64"
else
  echo "❌ Architecture non supportée ($ARCH)."
  exit 1
fi
echo "[OK] Architecture détectée : $ARCH_NAME"

# Préparation des arguments
CURL_ARGS=("-s" "-H" "User-Agent: BirdNET-Go-Installer")
if [ -n "${GITHUB_TOKEN:-}" ]; then
  CURL_ARGS+=("-H" "Authorization: Bearer $GITHUB_TOKEN")
  echo "[OK] Token GitHub utilisé."
fi

echo "[...] Appel de l'API GitHub..."
API_JSON=$(curl "${CURL_ARGS[@]}" https://api.github.com/repos/tphakala/birdnet-go/releases/latest)

if command -v jq >/dev/null 2>&1; then
  LATEST_TAG=$(echo "$API_JSON" | jq -r '.tag_name // empty')
  if [ "$ARCH_NAME" = "amd64" ]; then
    REGEX="linux.*amd64.*\\.tar\\.gz"
  else
    REGEX="linux.*arm64.*\\.tar\\.gz"
  fi
  ARCHIVE_URL=$(echo "$API_JSON" | jq -r --arg regex "$REGEX" '.assets[] | select(.name | test($regex)) | .browser_download_url' | head -n 1)
else
  LATEST_TAG=$(echo "$API_JSON" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)
  ARCHIVE_URL=$(echo "$API_JSON" | grep -o 'https://[^"]*linux[^"]*'"${ARCH_NAME}"'[^"]*\.tar\.gz' | head -n 1 || true)
fi

if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" = "null" ]; then
  echo "❌ Impossible de trouver la version."
  exit 1
fi
echo "[OK] Version détectée : $LATEST_TAG"

if [ -z "$ARCHIVE_URL" ] || [ "$ARCHIVE_URL" = "null" ]; then
  echo "❌ Impossible de trouver l'URL pour Linux $ARCH_NAME."
  exit 1
fi
echo "[OK] URL de l'archive : $ARCHIVE_URL"

# --- TÉLÉCHARGEMENT ET EXTRACTION BLINDÉE ---
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "[...] Téléchargement de l'archive..."
curl -fsSL --max-time 180 -o "$TMP_DIR/birdnet.tar.gz" "$ARCHIVE_URL"

echo "[...] Extraction dans un dossier temporaire..."
mkdir -p "$TMP_DIR/extract"
tar -xzf "$TMP_DIR/birdnet.tar.gz" -C "$TMP_DIR/extract"

# --- RECHERCHE DU BINAIRE ---
echo "[...] Recherche de l'exécutable 'birdnet-go'..."
BIN_PATH=$(find "$TMP_DIR/extract" -type f -name "birdnet-go" | head -n 1)

if [ -z "$BIN_PATH" ]; then
  echo "❌ Impossible de trouver l'exécutable 'birdnet-go' dans l'archive !"
  echo "Voici ce que contient l'archive :"
  find "$TMP_DIR/extract" -type f | head -n 20
  exit 1
fi
echo "[OK] Exécutable trouvé : $BIN_PATH"

# --- INSTALLATION ---
echo "[...] Installation dans $INSTALL_DIR..."
if [ "$EUID" -eq 0 ]; then
  mkdir -p "$INSTALL_DIR"
  cp "$BIN_PATH" "$INSTALL_DIR/birdnet-go"
  chmod +x "$INSTALL_DIR/birdnet-go"
  # Copie de la config si elle existe dans l'archive
  find "$TMP_DIR/extract" -name "config.yaml" -exec cp {} "$INSTALL_DIR/" \; || true
else
  sudo mkdir -p "$INSTALL_DIR"
  sudo cp "$BIN_PATH" "$INSTALL_DIR/birdnet-go"
  sudo chmod +x "$INSTALL_DIR/birdnet-go"
  sudo chown -R "$USER":"$USER" "$INSTALL_DIR"
  find "$TMP_DIR/extract" -name "config.yaml" -exec sudo cp {} "$INSTALL_DIR/" \; || true
fi

# --- SERVICE SYSTEMD ---
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
