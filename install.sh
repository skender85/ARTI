# 🧙‍♂️ All hail the script wizards over at https://github.com/community-scripts/ProxmoxVE
# Original Author: tteck, Co-Author: harvardthom, Source https://openwebui.com/
# 🛠️ This piece of automation sorcery wouldn't be possible without their arcane knowledge.
# ⚡ Full credits go to the mighty community-scripts crew – may your clusters never fail!
# Version 0.6

#!/usr/bin/env bash
set -e

APP="Open WebUI"
REPO="https://github.com/open-webui/open-webui"
APP_DIR="/opt/open-webui"
SERVICE_FILE="/etc/systemd/system/open-webui.service"
PORT=8080

echo -e "\n=== Installing dependencies ==="
apt-get update
apt-get install -y git curl python3 python3-pip python3-venv sudo build-essential

if ! command -v node >/dev/null; then
  echo -e "\n=== Installing latest Node.js (via nvm) ==="
  export NVM_DIR="$HOME/.nvm"
  mkdir -p "$NVM_DIR"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  source "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm use --lts
  npm install -g npm
fi

if ! command -v ollama >/dev/null; then
  echo -e "\n=== Installing Ollama ==="
  curl -fsSLO https://ollama.com/download/ollama-linux-amd64.tgz
  tar -xzf ollama-linux-amd64.tgz
  mv ollama /usr/bin/
  chmod +x /usr/bin/ollama
  rm -f ollama-linux-amd64.tgz
fi

echo -e "\n=== Cloning Open WebUI ==="
git clone "$REPO" "$APP_DIR" || {
  echo "Directory already exists. Pulling latest changes..."
  cd "$APP_DIR"
  git pull
}

echo -e "\n=== Building Frontend ==="
cd "$APP_DIR"
npm install
npm run build

echo -e "\n=== Setting up Python backend ==="
cd "$APP_DIR/backend"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo -e "\n=== Creating config file ==="
cat <<EOF >"$APP_DIR/backend/data/config.json"
{
  "ollama_base_url": "http://0.0.0.0:11434"
}
EOF

echo -e "\n=== Creating systemd service ==="
cat <<EOF >"$SERVICE_FILE"
[Unit]
Description=Open WebUI
After=network.target

[Service]
Type=simple
WorkingDirectory=${APP_DIR}/backend
ExecStart=${APP_DIR}/backend/venv/bin/python3 app.py
Restart=always
RestartSec=3
Environment=OLLAMA_HOST=0.0.0.0

[Install]
WantedBy=multi-user.target
EOF

echo -e "\n=== Enabling & starting service ==="
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable open-webui.service
systemctl restart open-webui.service

echo -e "\n✅ Installation abgeschlossen!"
echo -e "➡️ Zugriff unter: http://$(hostname -I | awk '{print $1}'):${PORT}"
