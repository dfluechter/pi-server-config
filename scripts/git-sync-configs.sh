#!/bin/bash
set -e

REPO_DIR="/home/raspi/pi-server-config"
NOW=$(date +"%Y-%m-%d %H:%M:%S")

echo -e "\e[1;36m==========================================================\e[0m"
echo -e "\e[1;36m       STARTE GIT-SYNC FUER RASPI5 (${NOW})       \e[0m"
echo -e "\e[1;36m==========================================================\e[0m"

# Unterordner fuer eine saubere Struktur im Repo anlegen
mkdir -p "${REPO_DIR}/configs" "${REPO_DIR}/scripts"

# 1. System-Konfigurationen kopieren (falls vorhanden)
echo -e "\e[1;33m[1/4] Kopiere aktuelle Konfigurationsdateien...\e[0m"
sudo cp /boot/firmware/config.txt "${REPO_DIR}/configs/config.txt" 2>/dev/null || true
sudo cp /etc/fstab "${REPO_DIR}/configs/fstab" 2>/dev/null || true
sudo cp /etc/samba/smb.conf "${REPO_DIR}/configs/smb.conf" 2>/dev/null || true
sudo cp /etc/unbound/unbound.conf.d/pi-hole.conf "${REPO_DIR}/configs/pi-hole.conf" 2>/dev/null || true
cp /home/raspi/.bashrc "${REPO_DIR}/configs/bashrc" 2>/dev/null || true
cp /home/raspi/.bash_aliases "${REPO_DIR}/configs/bash_aliases" 2>/dev/null || true

# 2. Eigene Skripte kopieren
echo -e "\e[1;33m[2/4] Kopiere System-Skripte...\e[0m"
sudo cp /usr/local/bin/status "${REPO_DIR}/scripts/status.sh" 2>/dev/null || true
sudo cp /usr/local/bin/nas-backup "${REPO_DIR}/scripts/nas-backup.sh" 2>/dev/null || true
sudo cp /usr/local/bin/git-sync-configs "${REPO_DIR}/scripts/git-sync-configs.sh" 2>/dev/null || true

# 3. Dateirechte auf den Benutzer raspi setzen
sudo chown -R raspi:raspi "${REPO_DIR}"

# 4. Git-Status pruefen, committen, rebases abholen und pushen (als Benutzer raspi)
echo -e "\e[1;33m[3/4] Pruefe auf Aenderungen im Git-Repository...\e[0m"
cd "${REPO_DIR}"

if [ -n "$(sudo -u raspi git status --porcelain)" ]; then
    sudo -u raspi git add -A
    sudo -u raspi git commit -m "chore(config): auto-sync raspi5 configs (${NOW})"
fi

echo -e "\e[1;33m[4/4] Synchronisiere mit GitHub (Pull & Push)...\e[0m"
sudo -u raspi git pull --rebase origin main
sudo -u raspi git push origin main
echo -e "\e[1;32m[ERFOLG] Alle Konfigurationen sind synchron mit GitHub!\e[0m"
echo -e "\e[1;36m==========================================================\e[0m"
