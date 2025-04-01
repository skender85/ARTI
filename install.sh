# 🧙‍♂️ All hail the script wizards over at https://github.com/community-scripts/ProxmoxVE
# Original Author: tteck, Co-Author: harvardthom, Source https://openwebui.com/
# 🛠️ This piece of automation sorcery wouldn't be possible without their arcane knowledge.
# ⚡ Full credits go to the mighty community-scripts crew – may your clusters never fail!
# Version 0.3

#!/usr/bin/env bash
set -e

APP="Open WebUI"
INSTALL_DIR="/opt/open-webui"
BACKUP_DIR="/opt/open-webui-backup"

echo "=== [0/9] NodeSource entfernen, falls vorhanden ==="
rm -f /etc/apt/sources.list.d/nodesource*
sed -i '/nodesource/d' /etc/apt/sources.list
apt update

echo "=== [1/9] System vorbereiten ==="
apt install -y curl wget git python3 python3-pip build-essential python3-venv nodejs npm

echo "=== [2/9] Node.js-Version prüfen ==="
NODE_VER=$(node -v | grep -oP '\d+' | head -1)
if [ "$NODE_VER" -lt 18 ]; then
  echo "⚠️ Die Node-Version ist zu alt. Bitte Node.js >=18 manuell installieren."
  exit 1
fi

echo "=== [3/9] Ollama installieren (0.0.0.0:11434) ==="
curl -fsSLO https://ollama.com/download/ollama-linux-amd64.tgz
tar -xzf ollama-linux-amd64.tgz
rm -f ollama-linux-amd64.tgz

# Datei finden und korrekt verschieben
OLLAMA_BIN=$(find . -type f -name 'ollama' | head -n 1)
if [[ -f "$OLLAMA_BIN" ]]; then
  install -m 755 "$OLLAMA_BIN" /usr/bin/ollama
else
  echo "❌ ollama-Binärdatei nicht gefunden."
  exit 1
fi


mkdir -p /root/.ollama
cat <<EOF > /root/.ollama/config.toml
[api]
address = "0.0.0.0:11434"
EOF

echo "=== [4/9] Open WebUI klonen ==="
git clone https://github.com/open-webui/open-webui.git "$INSTALL_DIR"

echo "=== [5/9] Frontend installieren & bauen ==="
cd "$INSTALL_DIR"
npm install
export NODE_OPTIONS="--max-old-space-size=3584"
npm run build

echo "=== [6/9] Backend installieren ==="
cd backend
pip install -r requirements.txt

echo "=== [7/9] systemd-Service für Open WebUI ==="
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

echo "=== [8/9] systemd-Service für Ollama ==="
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

echo "=== [9/9] Services starten ==="
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now ollama
systemctl enable --now open-webui

echo ""
echo "✅ Fertig! $APP & Ollama sind installiert."
echo "🌍 Webinterface:   http://$(hostname -I | awk '{print $1}'):8080"
echo "🔌 Ollama API:     http://0.0.0.0:11434"
