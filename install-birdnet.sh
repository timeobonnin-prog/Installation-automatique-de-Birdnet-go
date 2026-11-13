#!/usr/bin/env bash

# --- MODE BLINDÉ ---
# On active le mode strict : arrêt sur erreur, variable non définie, ou erreur dans un pipe
set -euo pipefail

# Piège pour afficher la ligne exacte en cas d'erreur
trap 'echo "❌ Erreur inattendue à la ligne $LINENO. Code de sortie: $?"; exit 1' ERR

echo "=== Installation de BirdNET-Go pour Linux / Raspberry Pi ==="

# 1. Dossier d'installation
INSTALL_DIR="${INSTALL_DIR:-/opt/birdnet-go}"

# 2. Détection de l'architecture
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

# 3. Préparation des arguments de l'API
CURL_ARGS=("-s" "-H" "User-Agent: BirdNET-Go-Installer-Script")
if [ -n "${GITHUB_TOKEN:-}" ]; then
    CURL_ARGS+=("-H" "Authorization: Bearer $GITHUB_TOKEN")
    echo "[OK] Token GitHub utilisé pour éviter les blocages."
else
    echo "[INFO] Pas de token fourni. Risque de blocage par l'API GitHub."
fi

# 4. Appel de l'API
echo "[...] Recherche de la dernière version..."
API_JSON=$(curl "${CURL_ARGS[@]}" https://api.github.com/repos/tphakala/birdnet-go/releases/latest)

# Vérification si l'API a renvoyé une erreur de quota
if echo "$API_JSON" | grep -q "API rate limit exceeded"; then
    echo "❌ Erreur : Limite d'API GitHub atteinte. Réessayez dans 1 heure ou ajoutez un token."
    exit 1
fi

# 5. Extraction des données (avec jq si dispo, sinon fallback)
if command -v jq >/dev/null 2>&1; then
    echo "[OK] Utilisation de jq pour lire la réponse."
    LATEST_TAG=$(echo "$API_JSON" | jq -r '.tag_name // empty')
    ARCHIVE_URL=$(echo "$API_JSON" | jq -r ".assets[] | select(.name | contains(\"linux_${ARCH_NAME}.tar.gz\")) | .browser_download_url" | head -n 1)
else
    echo "[INFO] jq non trouvé, utilisation de grep."
    LATEST_TAG=$(echo "$API_JSON" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)
    ARCHIVE_URL=$(echo "$API_JSON" | grep "browser_download_url.*linux_${ARCH_NAME}.tar.gz" | cut -d '"' -f 4 || true)
fi

# 6. Vérifications finales
if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" = "null" ]; then
    echo "❌ Impossible de trouver la version. Voici la réponse brute de l'API :"
    echo "$API_JSON"
    exit 1
fi
echo "[OK] Version détectée : $LATEST_TAG"

if [ -z "$ARCHIVE_URL" ] || [ "$ARCHIVE_URL" = "null" ]; then
    echo "❌ Impossible de trouver l'URL pour Linux $ARCH_NAME."
    exit 1
fi
echo "[OK] URL de l'archive trouvée."

# 7. Téléchargement (avec retry en cas de coupure réseau)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
echo "[...] Téléchargement de l'archive..."
curl -fsSL --retry 3 -o "$TMP_DIR/birdnet.tar.gz" "$ARCHIVE_URL"

# 8. Installation
echo "[...] Installation dans $INSTALL_DIR..."
if [ "$EUID" -eq 0 ]; then
    mkdir -p "$INSTALL_DIR"
    tar -xzf "$TMP_DIR/birdnet.tar.gz" -C "$INSTALL_DIR" --strip-components=1
else
    sudo mkdir -p "$INSTALL_DIR"
    sudo tar -xzf "$TMP_DIR/birdnet.tar.gz" -C "$INSTALL_DIR" --strip-components=1
    sudo chown -R "$USER":"$USER" "$INSTALL_DIR"
fi

# 9. Service systemd (uniquement si on est sur un vrai serveur)
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
