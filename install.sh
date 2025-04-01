# 🧙‍♂️ All hail the script wizards over at https://github.com/community-scripts/ProxmoxVE
# Original Author: tteck, Co-Author: harvardthom, Source https://openwebui.com/
# 🛠️ This piece of automation sorcery wouldn't be possible without their arcane knowledge.
# ⚡ Full credits go to the mighty community-scripts crew – may your clusters never fail!
# Version 0.8

#!/usr/bin/env bash

set -e

echo "=== [1/10] System vorbereiten ==="
apt update && apt upgrade -y
apt install -y curl wget sudo git python3 python3-venv python3-pip build-essential ca-certificates gnupg unzip

echo "=== [2/10] Node.js installieren (v20 LTS) ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "=== [3/10] Ollama installieren ==="
curl -fsSL https://ollama.com/install.sh | sh

echo "=== [4/10] Ollama systemd Service einrichten ==="
tee /etc/systemd/system/ollama.service > /dev/null <<EOF
[Unit]
Description=Ollama Server
After=network.target

[Service]
ExecStart=/usr/local/bin/ollama serve
Restart=always
User=root
WorkingDirectory=/root
Environment=OLLAMA_HOST=0.0.0.0
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now ollama

echo "=== [5/10] Open WebUI herunterladen ==="
mkdir -p /opt/open-webui
cd /opt/open-webui
git clone https://github.com/open-webui/open-webui.git .
git checkout main

echo "=== [6/10] Python Backend vorbereiten ==="
cd backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

echo "=== [7/10] Frontend vorbereiten ==="
cd ../frontend
npm install
npm run build

echo "=== [8/10] Open WebUI systemd Service einrichten ==="
tee /etc/systemd/system/open-webui.service > /dev/null <<EOF
[Unit]
Description=Open WebUI
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/open-webui/backend
ExecStart=/opt/open-webui/backend/start.sh
Restart=always
User=root
Environment=HOST=0.0.0.0
Environment=PORT=8080

[Install]
WantedBy=multi-user.target
EOF

echo "=== [9/10] Dienste aktivieren und starten ==="
systemctl enable --now open-webui

echo "=== [10/10] Setup abgeschlossen ==="
echo "Zugriff auf Open WebUI unter: http://<SERVER-IP>:8080"
