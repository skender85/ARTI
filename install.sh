# 🧙‍♂️ All hail the script wizards over at https://github.com/community-scripts/ProxmoxVE
# Original Author: tteck, Co-Author: harvardthom, Source https://openwebui.com/
# 🛠️ This piece of automation sorcery wouldn't be possible without their arcane knowledge.
# ⚡ Full credits go to the mighty community-scripts crew – may your clusters never fail!
# Version 0.7

#!/usr/bin/env bash

set -e

# === [1/10] System vorbereiten ===
echo "=== [1/10] System vorbereiten ==="
apt-get update && apt-get upgrade -y
apt-get install -y curl git sudo unzip python3-full python3-venv python3-pip npm

# === [2/10] Node.js installieren (latest stable LTS) ===
echo "=== [2/10] Node.js installieren ==="
export NODE_VERSION="$(curl -sL https://nodejs.org/en/download/ | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)"
ARCH=$(dpkg --print-architecture)
wget -q https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${ARCH}.tar.xz -O /tmp/node.tar.xz
mkdir -p /usr/local/lib/nodejs
cd /usr/local/lib/nodejs
rm -rf node-${NODE_VERSION}-linux-${ARCH}
tar -xJf /tmp/node.tar.xz
rm /tmp/node.tar.xz
export PATH=/usr/local/lib/nodejs/node-${NODE_VERSION}-linux-${ARCH}/bin:$PATH

# === [3/10] OpenWebUI clonen ===
echo "=== [3/10] OpenWebUI clonen ==="
mkdir -p /opt && cd /opt
git clone https://github.com/open-webui/open-webui.git || true
cd open-webui

# === [4/10] Backend vorbereiten ===
echo "=== [4/10] Backend vorbereiten ==="
cd backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

# === [5/10] Frontend installieren & bauen ===
echo "=== [5/10] Frontend installieren & bauen ==="
cd ../frontend
npm install
npm run build

# === [6/10] Backend Start-Script fixen ===
echo "=== [6/10] Start-Script korrigieren ==="
sed -i 's|exec uvicorn|exec ./venv/bin/uvicorn|' /opt/open-webui/backend/start.sh
chmod +x /opt/open-webui/backend/start.sh

# === [7/10] Systemd Service einrichten ===
echo "=== [7/10] Systemd Service einrichten ==="
cat <<EOF > /etc/systemd/system/open-webui.service
[Unit]
Description=Open WebUI
After=network.target

[Service]
Type=simple
ExecStart=/opt/open-webui/backend/start.sh
WorkingDirectory=/opt/open-webui/backend
Restart=always
RestartSec=5
Environment=PORT=8080

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable open-webui.service
systemctl start open-webui.service

# === [8/10] Fertig ===
echo "=== [8/10] Open WebUI erfolgreich installiert ==="
echo "Zugriff: http://<IP>:8080"
