#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Datei: scripts/git-sync-configs.sh
# Beschreibung: Synchronisiert System-, Netzwerk-, Pi-hole- & Minecraft-Configs
# Host: raspi5
# ==============================================================================

# ANSI-Farbcodes für übersichtliche Statusmeldungen
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_DIR="${HOME}/pi-server-config"
CONFIG_DIR="${REPO_DIR}/config"
MC_SOURCE_DIR="${HOME}/minecraft-server"
MC_DEST_DIR="${REPO_DIR}/minecraft"
CURRENT_USER="$(id -un)"
CURRENT_GROUP="$(id -gn)"

log_info()    { echo -e "${CYAN}[$(date +'%H:%M:%S')] [INFO]${NC}  $*"; }
log_ok()      { echo -e "${GREEN}[$(date +'%H:%M:%S')] [OK]${NC}    $*"; }
log_skip()    { echo -e "${YELLOW}[$(date +'%H:%M:%S')] [SKIP]${NC}  $*"; }
log_section() { echo -e "\n${CYAN}--- $* ---${NC}"; }

echo -e "${BLUE}=================================================================${NC}"
log_info "Starte Konfigurations-Backup für Host: $(hostname)"
echo -e "${BLUE}=================================================================${NC}"

# Nicht mehr benötigte Altlasten (X11/TFT & Docker) aus dem Repo entfernen
rm -rf "${CONFIG_DIR}/system/xorg.conf.d" \
       "${CONFIG_DIR}/docker" \
       "${REPO_DIR}/docker"

# Ziel-Ordnerstruktur sicherstellen
mkdir -p "${CONFIG_DIR}"/{system/{systemd,usr_local_bin},samba,pihole,unbound/unbound.conf.d}
mkdir -p "${REPO_DIR}/scripts"
mkdir -p "${MC_DEST_DIR}"/{config,plugins/{Geyser-Spigot,squaremap,Chunky},worlds}

# Hilfsfunktion zum sicheren Kopieren einzelner Dateien
copy_file() {
    local src="$1"
    local dest="$2"
    if [[ -f "$src" ]]; then
        sudo cp "$src" "$dest"
        sudo chown "${CURRENT_USER}:${CURRENT_GROUP}" "$dest"
        log_ok "Gesichert: $src -> ${dest#"${REPO_DIR}/"}"
    else
        log_skip "Nicht gefunden: $src"
    fi
}

log_section "1. Shell & Benutzer-Konfiguration"
copy_file "${HOME}/.bashrc" "${CONFIG_DIR}/system/bashrc"
copy_file "${HOME}/.bash_aliases" "${CONFIG_DIR}/system/bash_aliases"
copy_file "${HOME}/.profile" "${CONFIG_DIR}/system/profile"
copy_file "${HOME}/.gitconfig" "${CONFIG_DIR}/system/gitconfig"

log_section "2. Boot, System & SSH"
if [[ -f "/boot/firmware/config.txt" ]]; then
    copy_file "/boot/firmware/config.txt" "${CONFIG_DIR}/system/config.txt"
    copy_file "/boot/firmware/cmdline.txt" "${CONFIG_DIR}/system/cmdline.txt"
else
    copy_file "/boot/config.txt" "${CONFIG_DIR}/system/config.txt"
    copy_file "/boot/cmdline.txt" "${CONFIG_DIR}/system/cmdline.txt"
fi
copy_file "/etc/hostname" "${CONFIG_DIR}/system/hostname"
copy_file "/etc/hosts" "${CONFIG_DIR}/system/hosts"
copy_file "/etc/modules" "${CONFIG_DIR}/system/modules"
copy_file "/etc/rc.local" "${CONFIG_DIR}/system/rc.local"
copy_file "/etc/ssh/sshd_config" "${CONFIG_DIR}/system/sshd_config"

log_section "3. Mounts, Samba & Eigene Systemd-Dateien (ohne Symlinks)"
if [[ -f "/etc/fstab" ]]; then
    sudo cp "/etc/fstab" "${CONFIG_DIR}/system/fstab"
    sudo chown "${CURRENT_USER}:${CURRENT_GROUP}" "${CONFIG_DIR}/system/fstab"
    sed -i -E 's/(password|pass)=[^,[:space:]]+/\1=**********/g' "${CONFIG_DIR}/system/fstab"
    log_ok "Gesichert & Passwörter maskiert: /etc/fstab -> config/system/fstab"
fi
copy_file "/etc/samba/smb.conf" "${CONFIG_DIR}/samba/smb.conf"

# Systemd: Vorher leeren und NUR echte Dateien (-type f, keine Symlinks) sichern
rm -rf "${CONFIG_DIR}/system/systemd/"*
if [[ -d "/etc/systemd/system" ]]; then
    while IFS= read -r -d '' unit_file; do
        rel_path="${unit_file#/etc/systemd/system/}"
        target_dir="${CONFIG_DIR}/system/systemd/$(dirname "$rel_path")"
        mkdir -p "$target_dir"
        sudo cp "$unit_file" "$target_dir/"
        log_ok "Systemd-Unit: /etc/systemd/system/$rel_path"
    done < <(sudo find /etc/systemd/system -maxdepth 2 -type f \( -name "*.service" -o -name "*.timer" -o -name "*.conf" -o -name "*.mount" \) -print0)
    sudo chown -R "${CURRENT_USER}:${CURRENT_GROUP}" "${CONFIG_DIR}/system/systemd"
fi

log_section "4. Eigene Skripte (/usr/local/bin)"
rm -rf "${CONFIG_DIR}/system/usr_local_bin/"*
if [[ -d "/usr/local/bin" ]]; then
    sudo find /usr/local/bin -maxdepth 1 -type f ! -name "pihole" -exec cp {} "${CONFIG_DIR}/system/usr_local_bin/" \;
    sudo chown -R "${CURRENT_USER}:${CURRENT_GROUP}" "${CONFIG_DIR}/system/usr_local_bin"
    log_ok "Gesichert: Eigene Skripte aus /usr/local/bin/"
fi

log_section "5. Netzwerk, Pi-hole v6 & Unbound"
copy_file "/etc/resolv.conf" "${CONFIG_DIR}/system/resolv.conf"
copy_file "/etc/pihole/pihole.toml" "${CONFIG_DIR}/pihole/pihole.toml"
copy_file "/etc/pihole/dnsmasq.conf" "${CONFIG_DIR}/pihole/dnsmasq.conf"
copy_file "/etc/pihole/hosts/custom.list" "${CONFIG_DIR}/pihole/custom.list"

if [[ -d "/etc/unbound/unbound.conf.d" ]]; then
    rm -rf "${CONFIG_DIR}/unbound/unbound.conf.d/"*
    sudo find /etc/unbound/unbound.conf.d -maxdepth 1 -type f -exec cp {} "${CONFIG_DIR}/unbound/unbound.conf.d/" \;
    sudo chown -R "${CURRENT_USER}:${CURRENT_GROUP}" "${CONFIG_DIR}/unbound/unbound.conf.d"
    log_ok "Gesichert: /etc/unbound/unbound.conf.d/*"
fi

log_section "6. Minecraft Server Konfigurationen (~/minecraft-server)"
if [[ -d "$MC_SOURCE_DIR" ]]; then
    mc_files=(
        "server.properties"
        "bukkit.yml"
        "spigot.yml"
        "permissions.yml"
        "update-paper.sh"
        "config/paper-global.yml"
        "config/paper-world-defaults.yml"
        "plugins/Geyser-Spigot/config.yml"
        "plugins/squaremap/config.yml"
        "plugins/Chunky/config.yml"
    )
    for rel_mc in "${mc_files[@]}"; do
        copy_file "${MC_SOURCE_DIR}/${rel_mc}" "${MC_DEST_DIR}/${rel_mc}"
    done
else
    log_skip "Minecraft-Verzeichnis ${MC_SOURCE_DIR} nicht gefunden."
fi

log_section "7. Crontabs"
if crontab -l > "${CONFIG_DIR}/system/user_crontab.txt" 2>/dev/null; then
    log_ok "Benutzer-Crontab gesichert."
else
    rm -f "${CONFIG_DIR}/system/user_crontab.txt"
    log_skip "Keine Benutzer-Crontab vorhanden."
fi

if sudo crontab -l > "${CONFIG_DIR}/system/root_crontab.txt" 2>/dev/null; then
    sudo chown "${CURRENT_USER}:${CURRENT_GROUP}" "${CONFIG_DIR}/system/root_crontab.txt"
    log_ok "Root-Crontab gesichert."
else
    sudo rm -f "${CONFIG_DIR}/system/root_crontab.txt"
    log_skip "Keine Root-Crontab vorhanden."
fi

echo -e "\n${BLUE}=================================================================${NC}"
echo -e "${GREEN}[$(date +'%H:%M:%S')] [FERTIG] Alle Konfigurationen nach ${REPO_DIR} synchronisiert!${NC}"
echo -e "${BLUE}=================================================================${NC}"

cd "$REPO_DIR"
echo -e "\n${CYAN}[GIT STATUS] Aktuelle Änderungen im Repository:${NC}"
git status -s
