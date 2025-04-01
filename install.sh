# 🧙‍♂️ All hail the script wizards over at https://github.com/community-scripts/ProxmoxVE
# Original Author: tteck, Co-Author: harvardthom, Source https://openwebui.com/
# 🛠️ This piece of automation sorcery wouldn't be possible without their arcane knowledge.
# ⚡ Full credits go to the mighty community-scripts crew – may your clusters never fail!
# Version 0.9

#!/usr/bin/env bash

set -e

echo "=== [1/10] System vorbereiten ==="
apt update && apt upgrade -y
apt install -y curl git python3 python3-pip python3-venv sudo lsb-release ca-certificates gnupg

echo "=== [2/10] NodeJS & npm installieren ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "=== [3/10] Ollama installieren ==="
curl -fsSL https://ollama.com/install.sh | sh

echo "=== [4/10] Ollama systemd Service einrichten ==="
cat <<EOF >/etc/systemd/system/ollama.service
[Unit]
Description=Ollama Service
After=network.target

[Service]
ExecStart=/usr/local/bin/ollama serve
Restart=always
User=root
Environment=OLLAMA_MODELS=/root/.ollama/models

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable ollama.service
systemctl start ollama.service

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
cd ../web
npm install
npm run build

echo "=== [8/10] Startscript prüfen ==="
/bin/chmod +x /opt/open-webui/backend/start.sh

echo "=== [9/10] systemd Service für Open WebUI einrichten ==="
cat <<EOF >/etc/systemd/system/open-webui.service
[Unit]
Description=Open WebUI
After=network.target

[Service]
Type=simple
ExecStart=/opt/open-webui/backend/start.sh
WorkingDirectory=/opt/open-webui/backend
Restart=always
User=root
Environment=PORT=8080
Environment=HOST=0.0.0.0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable open-webui
systemctl start open-webui

echo "=== [10/10] Installation abgeschlossen ==="
echo "Zugriff via: http://<IP>:8080/"
