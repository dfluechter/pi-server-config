#!/usr/bin/env bash
# Minecraft PaperMC Server Installation für Raspberry Pi 5 (v2)
# Inklusive UFW Firewall-Regeln für Pi-hole & Unbound sowie manuellem Start per Shell-Befehl

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}=====================================================${NC}"
echo -e "${CYAN}  Minecraft PaperMC Server Setup - Raspberry Pi 5    ${NC}"
echo -e "${CYAN}=====================================================${NC}"

# 1. Paketupdates & Abhängigkeiten
echo -e "\n${YELLOW}[1/7] Aktualisiere Paketlisten und installiere Abhängigkeiten...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y openjdk-25-jre-headless jq wget curl git ufw

# 2. Server-Verzeichnis anlegen
MINECRAFT_DIR="$HOME/minecraft-server"
echo -e "\n${YELLOW}[2/7] Erstelle Server-Verzeichnis unter $MINECRAFT_DIR...${NC}"
mkdir -p "$MINECRAFT_DIR"
cd "$MINECRAFT_DIR"

# 3. PaperMC herunterladen
echo -e "\n${YELLOW}[3/7] Lade PaperMC-Serverdatei herunter...${NC}"
PAPER_VERSION="1.20.4"
API_URL="https://fill.papermc.io/v3/projects/paper/versions/$PAPER_VERSION/builds/latest"
DOWNLOAD_URL=$(curl -s "$API_URL" | jq -r '.downloads."server:default".url' 2>/dev/null || echo "")

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
    echo -e "${YELLOW}Nutze direkten Download-Link für PaperMC...${NC}"
    wget -O paper.jar "https://papermc.io/downloads/paper" || true
else
    wget -O paper.jar "$DOWNLOAD_URL"
fi

# 4. EULA & Konfiguration
echo -e "\n${YELLOW}[4/7] Akzeptiere EULA und erstelle server.properties...${NC}"
echo "eula=true" > eula.txt

cat << 'EOF' > server.properties
# Performance-optimierte Einstellungen für Raspberry Pi 5
server-port=25565
motd=Mein Raspberry Pi 5 Minecraft Server
max-players=10
view-distance=8
simulation-distance=6
online-mode=true
difficulty=normal
gamemode=survival
level-name=world
network-compression-threshold=256
entity-broadcast-range-percentage=75
enable-rcon=false
EOF

# 5. Optimiertes Startskript (start.sh) & globaler Shell-Befehl
echo -e "\n${YELLOW}[5/7] Erstelle Startskript (start.sh) und Shell-Befehl 'mc-start'...${NC}"
cat << 'EOF' > start.sh
#!/usr/bin/env bash
# Optimierter manueller Start für Raspberry Pi (ARM64)
java \
  -Xms2G -Xmx2G \
  -XX:+UseG1GC \
  -XX:+ParallelRefProcEnabled \
  -XX:MaxGCPauseMillis=200 \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC \
  -XX:G1HeapRegionSize=32M \
  -XX:G1NewSizePercent=30 \
  -XX:G1MaxNewSizePercent=40 \
  -XX:G1ReservePercent=20 \
  -XX:InitiatingHeapOccupancyPercent=15 \
  -jar paper.jar --nogui
EOF
chmod +x start.sh

# Erstelle optional einen globalen Shell-Befehl 'mc-start' in /usr/local/bin/
sudo bash -c "cat << EOF > /usr/local/bin/mc-start
#!/usr/bin/env bash
cd ${MINECRAFT_DIR} && ./start.sh
EOF"
sudo chmod +x /usr/local/bin/mc-start

# 6. Plugins für Crossplay (GeyserMC & Floodgate)
echo -e "\n${YELLOW}[6/7] Lade GeyserMC & Floodgate herunter...${NC}"
mkdir -p plugins
cd plugins
wget -O Geyser-Spigot.jar "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot" || true
wget -O Floodgate-Spigot.jar "https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot" || true
cd ..

# 7. systemd-Dienst (OHNE Autostart) & UFW-Firewall (inkl. Pi-hole & Unbound)
echo -e "\n${YELLOW}[7/7] Richte systemd-Dienst (ohne Autostart) & UFW-Firewall ein...${NC}"
CURRENT_USER=$(whoami)

sudo bash -c "cat << EOF > /etc/systemd/system/minecraft.service
[Unit]
Description=Minecraft PaperMC Server
After=network.target

[Service]
User=${CURRENT_USER}
WorkingDirectory=${MINECRAFT_DIR}
ExecStart=${MINECRAFT_DIR}/start.sh
ExecStop=/bin/kill -s SIGINT \$MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl daemon-reload
# WICHTIG: Autostart ist deaktiviert (systemctl disable)
sudo systemctl disable minecraft.service 2>/dev/null || true

# --- UFW Firewall-Regeln ---
# Minecraft Ports
sudo ufw allow 25565/tcp comment 'Minecraft Java Port'
sudo ufw allow 19132/udp comment 'Minecraft Bedrock GeyserMC Port'

# Pi-hole Ports
sudo ufw allow 53/tcp comment 'Pi-hole DNS TCP'
sudo ufw allow 53/udp comment 'Pi-hole DNS UDP'
sudo ufw allow 80/tcp comment 'Pi-hole Web Interface'
sudo ufw allow 67/udp comment 'Pi-hole DHCP Server'

# Unbound Port
sudo ufw allow 5335/tcp comment 'Unbound DNS Port'
sudo ufw allow 5335/udp comment 'Unbound DNS Port'

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}  Installation erfolgreich abgeschlossen!            ${NC}"
echo -e "${GREEN}=====================================================${NC}"
echo -e "Hinweis: Der automatische Systemstart beim Booten ist DEAKTIVIERT."
echo -e "Du kannst den Minecraft-Server manuell mit einem der folgenden Befehle starten:"
echo -e "  - Shell-Befehl von überall:   ${CYAN}mc-start${NC}"
echo -e "  - Im Server-Ordner:           ${CYAN}cd ~/minecraft-server && ./start.sh${NC}"
echo -e "  - Manuell via systemd:        ${CYAN}sudo systemctl start minecraft${NC}"
