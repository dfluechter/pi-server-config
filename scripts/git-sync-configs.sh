#!/bin/bash
# ==============================================================================
# Datei: scripts/git-sync-configs.sh
# Beschreibung: Synchronisiert alle wichtigen System-, Docker- & eigene Configs ins Git-Repo
# Host: raspi5
# ==============================================================================

# Farbdefinitionen für das Log
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

REPO_DIR="$HOME/pi-server-config"
CONFIG_DIR="$REPO_DIR/config"

echo -e "${BLUE}=================================================================${NC}"
echo -e "${CYAN}[INFO] Starte Konfigurations-Backup für Host: $(hostname)${NC}"
echo -e "${BLUE}=================================================================${NC}"

# Ordnerstruktur sicherstellen
mkdir -p "$CONFIG_DIR"/{system/{systemd,usr_local_bin,xorg.conf.d},samba,pihole,unbound,docker}
mkdir -p "$REPO_DIR"/{scripts,minecraft}

# Hilfsfunktion zum sicheren Kopieren von Dateien
copy_file() {
    local src="$1"
    local dest="$2"
    if [ -f "$src" ]; then
        sudo cp "$src" "$dest"
        sudo chown "$USER:$USER" "$dest"
        echo -e "${GREEN}[OK]${NC}     Gesichert: $src -> ${dest#$REPO_DIR/}"
    else
        echo -e "${YELLOW}[SKIP]${NC}   Nicht gefunden: $src"
    fi
}

echo -e "\n${CYAN}--- 1. Shell & Benutzer-Konfiguration ---${NC}"
copy_file "$HOME/.bashrc" "$CONFIG_DIR/system/bashrc"
copy_file "$HOME/.bash_aliases" "$CONFIG_DIR/system/bash_aliases"
copy_file "$HOME/.profile" "$CONFIG_DIR/system/profile"
copy_file "$HOME/.gitconfig" "$CONFIG_DIR/system/gitconfig"

echo -e "\n${CYAN}--- 2. Boot, Hardware (TFT Display / Lüfter) & SSH ---${NC}"
if [ -f "/boot/firmware/config.txt" ]; then
    copy_file "/boot/firmware/config.txt" "$CONFIG_DIR/system/config.txt"
    copy_file "/boot/firmware/cmdline.txt" "$CONFIG_DIR/system/cmdline.txt"
else
    copy_file "/boot/config.txt" "$CONFIG_DIR/system/config.txt"
    copy_file "/boot/cmdline.txt" "$CONFIG_DIR/system/cmdline.txt"
fi
copy_file "/etc/hostname" "$CONFIG_DIR/system/hostname"
copy_file "/etc/hosts" "$CONFIG_DIR/system/hosts"
copy_file "/etc/modules" "$CONFIG_DIR/system/modules"
copy_file "/etc/rc.local" "$CONFIG_DIR/system/rc.local"
copy_file "/etc/ssh/sshd_config" "$CONFIG_DIR/system/sshd_config"

# X11 / 3.5" TFT Display Kalibrierung (falls vorhanden)
if [ -d "/etc/X11/xorg.conf.d" ]; then
    sudo cp -r /etc/X11/xorg.conf.d/* "$CONFIG_DIR/system/xorg.conf.d/" 2>/dev/null
    sudo chown -R "$USER:$USER" "$CONFIG_DIR/system/xorg.conf.d"
    echo -e "${GREEN}[OK]${NC}     Gesichert: /etc/X11/xorg.conf.d/*"
fi

echo -e "\n${CYAN}--- 3. Mounts, Samba & Eigene Systemd-Services ---${NC}"
# fstab kopieren und eventuelle Passwörter maskieren
if [ -f "/etc/fstab" ]; then
    sudo cp "/etc/fstab" "$CONFIG_DIR/system/fstab"
    sudo chown "$USER:$USER" "$CONFIG_DIR/system/fstab"
    sed -i -E 's/(password|pass)=[^,[:space:]]+/\1=**********/g' "$CONFIG_DIR/system/fstab"
    echo -e "${GREEN}[OK]${NC}     Gesichert & bereinigt: /etc/fstab -> config/system/fstab"
fi
copy_file "/etc/samba/smb.conf" "$CONFIG_DIR/samba/smb.conf"

# Eigene Systemd-Services & Timer unter /etc/systemd/system/ sichern
if [ -d "/etc/systemd/system" ]; then
    sudo cp -r /etc/systemd/system/* "$CONFIG_DIR/system/systemd/" 2>/dev/null
    sudo chown -R "$USER:$USER" "$CONFIG_DIR/system/systemd"
    echo -e "${GREEN}[OK]${NC}     Gesichert: Eigene Systemd-Services unter /etc/systemd/system/*"
fi

echo -e "\n${CYAN}--- 4. Eigene Skripte (/usr/local/bin/) ---${NC}"
if [ -d "/usr/local/bin" ]; then
    sudo cp -r /usr/local/bin/* "$CONFIG_DIR/system/usr_local_bin/" 2>/dev/null
    sudo chown -R "$USER:$USER" "$CONFIG_DIR/system/usr_local_bin"
    echo -e "${GREEN}[OK]${NC}     Gesichert: Eigene Skripte aus /usr/local/bin/*"
fi

echo -e "\n${CYAN}--- 5. Netzwerk, Pi-hole & Unbound ---${NC}"
copy_file "/etc/dhcpcd.conf" "$CONFIG_DIR/system/dhcpcd.conf"
copy_file "/etc/resolv.conf" "$CONFIG_DIR/system/resolv.conf"

for pihole_dir in "/etc/pihole" "$HOME/docker/pihole/etc-pihole" "/opt/pihole/etc-pihole"; do
    if [ -d "$pihole_dir" ]; then
        copy_file "$pihole_dir/pihole-FTL.conf" "$CONFIG_DIR/pihole/pihole-FTL.conf"
        copy_file "$pihole_dir/setupVars.conf" "$CONFIG_DIR/pihole/setupVars.conf"
        copy_file "$pihole_dir/adlists.list" "$CONFIG_DIR/pihole/adlists.list"
        copy_file "$pihole_dir/custom.list" "$CONFIG_DIR/pihole/custom.list"
    fi
done

for dnsmasq_dir in "/etc/dnsmasq.d" "$HOME/docker/pihole/etc-dnsmasq.d" "/opt/pihole/etc-dnsmasq.d"; do
    if [ -d "$dnsmasq_dir" ]; then
        mkdir -p "$CONFIG_DIR/pihole/dnsmasq.d"
        sudo cp -r "$dnsmasq_dir"/* "$CONFIG_DIR/pihole/dnsmasq.d/" 2>/dev/null
        sudo chown -R "$USER:$USER" "$CONFIG_DIR/pihole/dnsmasq.d"
        echo -e "${GREEN}[OK]${NC}     Gesichert: $dnsmasq_dir/*"
    fi
done

if [ -d "/etc/unbound/unbound.conf.d" ]; then
    mkdir -p "$CONFIG_DIR/unbound/unbound.conf.d"
    sudo cp -r /etc/unbound/unbound.conf.d/* "$CONFIG_DIR/unbound/unbound.conf.d/" 2>/dev/null
    sudo chown -R "$USER:$USER" "$CONFIG_DIR/unbound/unbound.conf.d"
    echo -e "${GREEN}[OK]${NC}     Gesichert: /etc/unbound/unbound.conf.d/*"
fi

echo -e "\n${CYAN}--- 6. Docker-Compose & Container-Configs ---${NC}"
while IFS= read -r -d '' compose_file; do
    service_name=$(basename "$(dirname "$compose_file")")
    mkdir -p "$CONFIG_DIR/docker/$service_name"
    cp "$compose_file" "$CONFIG_DIR/docker/$service_name/"
    echo -e "${GREEN}[OK]${NC}     Docker-Compose gesichert: $compose_file -> config/docker/$service_name/"
done < <(find "$HOME" /opt -maxdepth 3 \( -name "docker-compose.yml" -o -name "docker-compose.yaml" -o -name "compose.yml" \) -not -path "$REPO_DIR/*" 2>/dev/null -print0)

# Minecraft-Ordner prüfen
if [ -d "$REPO_DIR/minecraft" ] && [ "$(ls -A "$REPO_DIR/minecraft" 2>/dev/null)" ]; then
    echo -e "${GREEN}[OK]${NC}     Minecraft-Ordner enthält Dateien und wird im Git berücksichtigt."
else
    touch "$REPO_DIR/minecraft/.gitkeep"
    echo -e "${BLUE}[INFO]${NC}   Minecraft-Ordner vorbereitet (minecraft/.gitkeep angelegt)."
fi

echo -e "\n${CYAN}--- 7. Crontabs ---${NC}"
crontab -l > "$CONFIG_DIR/system/user_crontab.txt" 2>/dev/null && \
    echo -e "${GREEN}[OK]${NC}     Benutzer-Crontab gesichert." || \
    echo -e "${YELLOW}[SKIP]${NC}   Keine Benutzer-Crontab vorhanden."

sudo crontab -l > "$CONFIG_DIR/system/root_crontab.txt" 2>/dev/null && \
    sudo chown "$USER:$USER" "$CONFIG_DIR/system/root_crontab.txt" && \
    echo -e "${GREEN}[OK]${NC}     Root-Crontab gesichert." || \
    echo -e "${YELLOW}[SKIP]${NC}   Keine Root-Crontab vorhanden."

echo -e "\n${BLUE}=================================================================${NC}"
echo -e "${GREEN}[FERTIG] Alle System-, SSH-, Systemd- & Skript-Dateien gesichert!${NC}"
echo -e "${BLUE}=================================================================${NC}"

# Git Status anzeigen
cd "$REPO_DIR" || exit
echo -e "\n${CYAN}[GIT STATUS] Aktuelle Änderungen im Repository:${NC}"
git status -s
