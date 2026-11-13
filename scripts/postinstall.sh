#!/bin/sh
set -e

if ! id -u birdnet >/dev/null 2>&1; then
    useradd -r -s /bin/false birdnet
fi

mkdir -p /var/lib/birdnet-go
chown -R birdnet:birdnet /var/lib/birdnet-go /etc/birdnet-go

cat <<EOF > /etc/systemd/system/birdnet-go.service
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
