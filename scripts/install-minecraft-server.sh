#!/usr/bin/env bash
# Minecraft PaperMC Server Installation für Raspberry Pi 5

set -e

echo '=== Minecraft Server Installation ==='

# 1. Paketupdates & Abhängigkeiten
sudo apt update && sudo apt upgrade -y
sudo apt install -y openjdk-25-jre-headless jq wget curl git ufw

# 2. Verzeichnis erstellen
MINECRAFT_DIR="$HOME/minecraft-server"
mkdir -p "$MINECRAFT_DIR"
cd "$MINECRAFT_DIR"

# 3. PaperMC herunterladen
echo 'Lade PaperMC herunter...'
wget -O paper.jar "https://papermc.io/downloads/paper" || true

# 4. EULA & Konfiguration
echo "eula=true" > eula.txt

cat << 'EOF' > server.properties
server-port=25565
motd=Mein Raspberry Pi 5 Minecraft Server
max-players=10
view-distance=8
simulation-distance=6
online-mode=true
difficulty=normal
gamemode=survival
level-name=world
EOF

# 5. Startscript erstellen
cat << 'EOF' > start.sh
#!/usr/bin/env bash
java -Xms2G -Xmx2G -XX:+UseG1GC -jar paper.jar --nogui
EOF
chmod +x start.sh

# 6. Plugins für Crossplay
mkdir -p plugins
cd plugins
wget -O Geyser-Spigot.jar "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot" || true
wget -O Floodgate-Spigot.jar "https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot" || true
cd ..

# 7. Autostart & Firewall
CURRENT_USER=$(whoami)
sudo bash -c "cat << EOF > /etc/systemd/system/minecraft.service
[Unit]
Description=Minecraft PaperMC Server
After=network.target

[Service]
User=${CURRENT_USER}
WorkingDirectory=${MINECRAFT_DIR}
ExecStart=${MINECRAFT_DIR}/start.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl daemon-reload
sudo systemctl enable minecraft.service
sudo ufw allow 25565/tcp
sudo ufw allow 19132/udp

echo 'Installation abgeschlossen!'
