# 🧙‍♂️ All hail the script wizards over at https://github.com/community-scripts/ProxmoxVE
# Original Author: tteck, Co-Author: harvardthom, Source https://openwebui.com/
# 🛠️ This piece of automation sorcery wouldn't be possible without their arcane knowledge.
# ⚡ Full credits go to the mighty community-scripts crew – may your clusters never fail!


#!/usr/bin/env bash
set -e

APP="Open WebUI"
INSTALL_DIR="/opt/open-webui"
BACKUP_DIR="/opt/open-webui-backup"

echo "=== [1/9] System vorbereiten ==="
apt update
apt install -y curl wget git python3 python3-pip nodejs npm build-essential python3-venv

echo "=== [2/9] Ollama installieren (Port 11434, 0.0.0.0) ==="
curl -fsSLO https://ollama.com/download/ollama-linux-amd64.tgz
tar -xzf ollama-linux-amd64.tgz
rm -f ollama-linux-amd64.tgz
install -m 755 ollama /usr/bin/ollama
rm ollama

# Ollama-Konfiguration auf 0.0.0.0:11434
mkdir -p /root/.ollama
cat <<EOF > /root/.ollama/config.toml
[api]
address = "0.0.0.0:11434"
EOF

echo "=== [3/9] Open WebUI klonen ==="
git clone https://github.com/open-webui/open-webui.git "$INSTALL_DIR"

echo "=== [4/9] Node-Module installieren & bauen ==="
cd "$INSTALL_DIR"
npm install
export NODE_OPTIONS="--max-old-space-size=3584"
npm run build

echo "=== [5/9] Python-Abhängigkeiten installieren ==="
cd backend
pip install -r requirements.txt

echo "=== [6/9] systemd-Service für Open WebUI erstellen ==="
cat <<EOF > /etc/systemd/system/open-webui.service
[Unit]
Description=Open WebUI
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR/backend
ExecStart=/usr/bin/python3 app.py
Restart=on-failure
User=root
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

echo "=== [7/9] systemd-Service für Ollama erstellen ==="
cat <<EOF > /etc/systemd/system/ollama.service
[Unit]
Description=Ollama LLM API
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/ollama serve
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "=== [8/9] Services aktivieren und starten ==="
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now ollama
systemctl enable --now open-webui

echo "=== [9/9] Installation abgeschlossen ==="
echo ""
echo "🚀 Open WebUI läuft jetzt!"
echo "🌐 Webinterface:   http://$(hostname -I | awk '{print $1}'):8080"
echo "🔌 Ollama API:     http://0.0.0.0:11434"
echo ""
echo "ℹ️ Du kannst nun in Open WebUI Modelle installieren und prompten."

