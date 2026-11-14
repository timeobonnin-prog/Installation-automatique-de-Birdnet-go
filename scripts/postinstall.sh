#!/bin/sh
set -e

# Création de l'utilisateur système
if ! id -u birdnet >/dev/null 2>&1; then
  useradd -r -s /bin/false birdnet
fi

# Création des dossiers AVANT de changer les droits
mkdir -p /var/lib/birdnet-go
mkdir -p /etc/birdnet-go

# Attribution des droits
chown -R birdnet:birdnet /var/lib/birdnet-go /etc/birdnet-go

# Création du service systemd
cat <<EOF >/etc/systemd/system/birdnet-go.service
[Unit]
Description=BirdNET-Go Service
After=network.target sound.target

[Service]
Type=simple
User=birdnet
WorkingDirectory=/var/lib/birdnet-go
ExecStart=/usr/local/bin/birdnet-go -config /etc/birdnet-go/config.yaml
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable birdnet-go
