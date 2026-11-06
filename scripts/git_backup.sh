#!/bin/bash
TARGET_DIR="/home/raspby/docker-server"
LOG_FILE="/home/raspby/scripts/backup.log"

echo "[$(date)] --- Start Backup ---" >> "$LOG_FILE"

# 1. System-Configs sichern
cp /etc/fstab "$TARGET_DIR/system_fstab.bak"
cp -r /home/raspby/scripts "$TARGET_DIR/"

# 2. Git Operationen
cd "$TARGET_DIR"
git add .

if ! git diff-index --quiet HEAD --; then
    git commit -m "Auto-Backup: Samba fix & System configs $(date +'%Y-%m-%d %H:%M')"
    git push origin main >> "$LOG_FILE" 2>&1
    echo "[$(date)] Push erfolgreich." >> "$LOG_FILE"
else
    echo "[$(date)] Keine Änderungen." >> "$LOG_FILE"
fi
