#!/usr/bin/env bash
# ==============================================================================
# Vollständiges Installationsskript für Minecraft (PaperMC) auf Raspberry Pi 5
# Version 3: Inkl. maximaler Performance-Einstellungen für server.properties,
# UFW-Regeln für Pi-hole & Unbound, sowie manueller Start per 'mc-start'.
# ==============================================================================

set -e

# Farben für Konsolenausgabe
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}=====================================================${NC}"
echo -e "${CYAN}  Minecraft PaperMC Setup (v3) - Raspberry Pi 5      ${NC}"
echo -e "${CYAN}=====================================================${NC}"

# 1. Systempakete & Abhängigkeiten
echo -e "\n${YELLOW}[1/7] Aktualisiere Paketlisten und installiere Abhängigkeiten...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y openjdk-25-jre-headless jq wget curl git ufw

# 2. Server-Verzeichnis anlegen
MINECRAFT_DIR="$HOME/minecraft-server"
echo -e "\n${YELLOW}[2/7] Erstelle Server-Verzeichnis unter $MINECRAFT_DIR...${NC}"
mkdir -p "$MINECRAFT_DIR"
cd "$MINECRAFT_DIR"

# 3. Neueste PaperMC Build herunterladen
PAPER_VERSION="1.20.4"
echo -e "\n${YELLOW}[3/7] Lade neueste PaperMC-Serverdatei herunter...${NC}"
wget -O paper.jar "https://papermc.io/downloads/paper" || true

# 4. EULA akzeptieren & server.properties für maximale Performance schreiben
echo -e "\n${YELLOW}[4/7] Akzeptiere EULA und erstelle optimierte server.properties...${NC}"
echo "eula=true" > eula.txt

cat << 'EOF' > server.properties
# Performance-optimierte Einstellungen für Raspberry Pi 5
server-port=25565
motd=Mein Raspberry Pi 5 Minecraft Server
max-players=8
view-distance=6
simulation-distance=4
entity-broadcast-range-percentage=75
network-compression-threshold=256
max-tick-time=60000
online-mode=true
difficulty=normal
gamemode=survival
level-name=world
enable-rcon=false
white-list=true
enforce-whitelist=true
EOF

# 5. Startskript (start.sh) erstellen
echo -e "\n${YELLOW}[5/7] Erstelle start.sh mit optimierten JVM-Flags...${NC}"
cat << 'EOF' > start.sh
#!/usr/bin/env bash
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

# 6. GeyserMC & Floodgate Plugins für Crossplay herunterladen
echo -e "\n${YELLOW}[6/7] Lade GeyserMC & Floodgate Plugins für Crossplay herunter...${NC}"
mkdir -p plugins
cd plugins
wget -O Geyser-Spigot.jar "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot" || true
wget -O Floodgate-Spigot.jar "https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot" || true
cd ..

# 7. Systemd-Dienst (kein Autostart) & Shell-Befehl 'mc-start' & UFW Firewall
echo -e "\n${YELLOW}[7/7] Konfiguriere Shell-Befehl 'mc-start' und UFW Firewall (inkl. Pi-hole & Unbound)...${NC}"
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
# Autostart explizit deaktiviert
sudo systemctl disable minecraft.service

# Globalen Befehl 'mc-start' anlegen
sudo bash -c "cat << EOF > /usr/local/bin/mc-start
#!/usr/bin/env bash
cd ${MINECRAFT_DIR} && ./start.sh
EOF"
sudo chmod +x /usr/local/bin/mc-start

# UFW Firewall-Regeln für Minecraft, Pi-hole und Unbound
sudo ufw allow 25565/tcp comment 'Minecraft Java Port'
sudo ufw allow 19132/udp comment 'Minecraft Bedrock GeyserMC Port'
sudo ufw allow 53/tcp comment 'Pi-hole DNS TCP'
sudo ufw allow 53/udp comment 'Pi-hole DNS UDP'
sudo ufw allow 80/tcp comment 'Pi-hole Web Dashboard'
sudo ufw allow 67/udp comment 'Pi-hole DHCP Server'
sudo ufw allow 5335/tcp comment 'Unbound DNS TCP'
sudo ufw allow 5335/udp comment 'Unbound DNS UDP'

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}  Installation (v3) erfolgreich abgeschlossen!       ${NC}"
echo -e "${GREEN}=====================================================${NC}"
echo -e "Starten mit: ${CYAN}mc-start${NC} oder ${CYAN}cd ~/minecraft-server && ./start.sh${NC}"
