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

if echo "$API_JSON" | grep -q "API rate limit exceeded"; then
    echo "❌ Erreur : Limite d'API GitHub atteinte."
    exit 1
fi

# --- EXTRACTION INTELLIGENTE ---
if command -v jq >/dev/null 2>&1; then
    LATEST_TAG=$(echo "$API_JSON" | jq -r '.tag_name // empty')
    
    # On cherche le fichier avec une Regex : il doit contenir "linux", "amd64" (ou arm64) et finir par ".tar.gz"
    if [ "$ARCH_NAME" = "amd64" ]; then
        REGEX="linux.*amd64.*\\.tar\\.gz"
    else
        REGEX="linux.*arm64.*\\.tar\\.gz"
    fi
    
    ARCHIVE_URL=$(echo "$API_JSON" | jq -r --arg regex "$REGEX" '.assets[] | select(.name | test($regex)) | .browser_download_url' | head -n 1)
else
    # Fallback si jq n'est pas installé
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
    echo "Voici les fichiers trouvés dans la release :"
    echo "$API_JSON" | grep '"name":' || true
    exit 1
fi
echo "[OK] URL de l'archive : $ARCHIVE_URL"

# Téléchargement
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
echo "[...] Téléchargement de l'archive..."
curl -fsSL --max-time 180 -o "$TMP_DIR/birdnet.tar.gz" "$ARCHIVE_URL"

# Installation
echo "[...] Installation dans $INSTALL_DIR..."
if [ "$EUID" -eq 0 ]; then
    mkdir -p "$INSTALL_DIR"
    tar -xzf "$TMP_DIR/birdnet.tar.gz" -C "$INSTALL_DIR" --strip-components=1
else
    sudo mkdir -p "$INSTALL_DIR"
    sudo tar -xzf "$TMP_DIR/birdnet.tar.gz" -C "$INSTALL_DIR" --strip-components=1
    sudo chown -R "$USER":"$USER" "$INSTALL_DIR"
fi

echo "✅ BirdNET-Go $LATEST_TAG a été installé avec succès dans $INSTALL_DIR !"
