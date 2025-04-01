# 🧙‍♂️ All hail the script wizards over at https://github.com/community-scripts/ProxmoxVE
# Original Author: tteck, Co-Author: harvardthom, Source https://openwebui.com/
# 🛠️ This piece of automation sorcery wouldn't be possible without their arcane knowledge.
# ⚡ Full credits go to the mighty community-scripts crew – may your clusters never fail!


#!/usr/bin/env bash

set -e

APP="Open WebUI"

echo "=== Installing curl ==="
apt update && apt upgrade -y && apt install curl -y

echo "=== Installing Node.js 18.x (LTS) ==="
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo "=== Installing dependencies ==="
apt install -y git python3 python3-pip build-essential python3-venv

echo "=== Installing Ollama ==="
curl -fsSLO https://ollama.com/download/ollama-linux-amd64.tgz
tar -C /usr -xzf ollama-linux-amd64.tgz
rm -f ollama-linux-amd64.tgz
ollama --version

echo "=== Cloning Open WebUI ==="
mkdir -p /opt
cd /opt
git clone https://github.com/open-webui/open-webui.git
cd open-webui

echo "=== Building frontend ==="
npm install
export NODE_OPTIONS="--max-old-space-size=3584"
npm run build

echo "=== Installing backend dependencies ==="
cd backend
pip install -r requirements.txt

echo "=== Creating systemd service ==="
cat <<EOF > /etc/systemd/system/open-webui.service
[Unit]
Description=Open WebUI
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/open-webui/backend
ExecStart=/usr/bin/python3 app.py
Restart=on-failure
User=root
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now open-webui

echo "✅ Open WebUI installed successfully!"
echo "🌐 Access it at: http://$(hostname -I | awk '{print $1}'):8080"
