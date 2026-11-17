#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
BACKUP_DIR="/var/backups/pi-server-config-$(date +%Y%m%d_%H%M%S)"

DRY_RUN=false
AUTO_YES=false
RESTORE_NETWORK=false

usage() {
  cat << 'USAGE'
Nutzung: bash scripts/restore.sh [OPTIONEN]

Optionen:
  --dry-run        Zeigt alle geplanten Schritte an, ohne Dateien zu verändern
  --yes            Führt die Wiederherstellung ohne interaktive Rückfrage aus
  --with-network   Stellt auch /etc/resolv.conf und das statische eth0-Profil wieder her
  -h, --help       Zeigt diese Hilfe an
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --yes) AUTO_YES=true ;;
    --with-network) RESTORE_NETWORK=true ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "[FEHLER] Unbekannte Option: $arg" >&2
      usage
      exit 2
      ;;
  esac
done

log_info() { echo "[INFO]  $*"; }
log_ok()   { echo "[OK]    $*"; }
log_warn() { echo "[WARN]  $*"; }

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    echo "[DRY]   $*"
  else
    "$@"
  fi
}

backup_and_copy_root() {
  local src="$1"
  local dst="$2"
  local mode="$3"

  if [ ! -f "$src" ]; then
    log_warn "Quelle nicht gefunden, überspringe: $src"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "[DRY]   install -D -m $mode -o root -g root \"$src\" \"$dst\""
    return 0
  fi

  if [ -f "$dst" ]; then
    sudo mkdir -p "$BACKUP_DIR$(dirname "$dst")"
    sudo cp -a "$dst" "$BACKUP_DIR$dst"
  fi

  sudo install -D -m "$mode" -o root -g root "$src" "$dst"
  log_ok "Wiederhergestellt: $dst"
}

backup_and_copy_user() {
  local src="$1"
  local dst="$2"
  local mode="$3"

  if [ ! -f "$src" ]; then
    log_warn "Quelle nicht gefunden, überspringe: $src"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "[DRY]   install -D -m $mode -o $TARGET_USER -g $TARGET_USER \"$src\" \"$dst\""
    return 0
  fi

  if [ -f "$dst" ]; then
    sudo mkdir -p "$BACKUP_DIR$(dirname "$dst")"
    sudo cp -a "$dst" "$BACKUP_DIR$dst"
  fi

  sudo install -D -m "$mode" -o "$TARGET_USER" -g "$TARGET_USER" "$src" "$dst"
  log_ok "Wiederhergestellt: $dst"
}

echo "================================================================="
echo " Raspberry Pi 5 Server-Restore ($REPO_DIR)"
echo " Zielbenutzer: $TARGET_USER ($TARGET_HOME)"
echo " Dry-Run: $DRY_RUN | Netzwerk-Profil: $RESTORE_NETWORK"
echo "================================================================="

if [ "$DRY_RUN" = false ] && [ "$AUTO_YES" = false ]; then
  read -r -p "System- und Dienstkonfigurationen jetzt wiederherstellen? [j/N] " REPLY
  if [[ ! "$REPLY" =~ ^[JjYy]$ ]]; then
    echo "Abgebrochen."
    exit 0
  fi
fi

# 1. Basis-Pakete prüfen und installieren
log_info "1. Prüfe Basis-Pakete..."
PACKAGES=(git curl wget rsync jq python3 unbound samba sqlite3 ca-certificates)
MISSING_PKGS=()
for pkg in "${PACKAGES[@]}"; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    MISSING_PKGS+=("$pkg")
  fi
done

if [ "${#MISSING_PKGS[@]}" -gt 0 ]; then
  log_info "Installiere fehlende Pakete: ${MISSING_PKGS[*]}"
  run_cmd sudo apt-get update -qq
  run_cmd sudo apt-get install -y "${MISSING_PKGS[@]}"
else
  log_ok "Alle Basis-Pakete sind bereits installiert."
fi

# 2. Shell-, Git- & Benutzer-Konfigurationen
log_info "2. Stelle Benutzer- und Shell-Konfigurationen wieder her..."
backup_and_copy_user "$REPO_DIR/config/system/bashrc" "$TARGET_HOME/.bashrc" 644
backup_and_copy_user "$REPO_DIR/config/system/bash_aliases" "$TARGET_HOME/.bash_aliases" 644
backup_and_copy_user "$REPO_DIR/config/system/profile" "$TARGET_HOME/.profile" 644
backup_and_copy_user "$REPO_DIR/config/system/gitconfig" "$TARGET_HOME/.gitconfig" 644

if [ -f "$REPO_DIR/scripts/hooks/pre-commit" ] && [ -d "$REPO_DIR/.git/hooks" ]; then
  run_cmd install -m 755 "$REPO_DIR/scripts/hooks/pre-commit" "$REPO_DIR/.git/hooks/pre-commit"
  log_ok "Lokaler Git Pre-Commit-Hook aktiviert."
fi

# 3. Eigene CLI-Tools (/usr/local/bin) & Systemd-Units
log_info "3. Stelle Skripte in /usr/local/bin und Systemd-Units wieder her..."
if [ -d "$REPO_DIR/config/system/usr_local_bin" ]; then
  for bin_file in "$REPO_DIR"/config/system/usr_local_bin/*; do
    [ -f "$bin_file" ] || continue
    backup_and_copy_root "$bin_file" "/usr/local/bin/$(basename "$bin_file")" 755
  done
fi

if [ -d "$REPO_DIR/config/system/systemd" ]; then
  for unit_file in "$REPO_DIR"/config/system/systemd/*; do
    [ -f "$unit_file" ] || continue
    unit_name="$(basename "$unit_file")"
    case "$unit_name" in
      autologin.conf)
        backup_and_copy_root "$unit_file" "/etc/systemd/system/getty@tty1.service.d/autologin.conf" 644
        ;;
      jellyfin.service.conf)
        backup_and_copy_root "$unit_file" "/etc/systemd/system/jellyfin.service.d/jellyfin.service.conf" 644
        ;;
      *.service|*.timer)
        backup_and_copy_root "$unit_file" "/etc/systemd/system/$unit_name" 644
        ;;
      *)
        log_warn "Unbekannte Systemd-Datei übersprungen: $unit_name"
        ;;
    esac
  done
fi

# 4. Umgebung für pihole-games-webhook initialisieren (falls noch nicht vorhanden)
if [ ! -f /etc/default/pihole-games-webhook ]; then
  log_info "4. Erzeuge initiale Umgebung /etc/default/pihole-games-webhook..."
  if [ "$DRY_RUN" = true ]; then
    echo "[DRY]   Erzeuge /etc/default/pihole-games-webhook mit neuem Zufalls-Token (chmod 600)"
  else
    NEW_SECRET="$(python3 -c 'import secrets; print(secrets.token_hex(16))')"
    sudo tee /etc/default/pihole-games-webhook > /dev/null << ENVEOF
BIND_IP=192.168.2.128
PORT=8765
WEBHOOK_TOKEN=${NEW_SECRET}
AUTO_OFF_SECONDS=1800
ENVEOF
    sudo chmod 600 /etc/default/pihole-games-webhook
    log_ok "Neu angelegt: /etc/default/pihole-games-webhook (bitte neuen Token für Handy-Shortcut notieren)"
  fi
else
  log_ok "Bestehende /etc/default/pihole-games-webhook bleibt unverändert erhalten."
fi

# 5. Unbound & Pi-hole v6 Konfigurationen
log_info "5. Stelle Unbound- und Pi-hole-v6-Konfigurationen wieder her..."
if [ -d "$REPO_DIR/config/unbound" ]; then
  for ub_file in "$REPO_DIR"/config/unbound/*; do
    [ -f "$ub_file" ] || continue
    backup_and_copy_root "$ub_file" "/etc/unbound/unbound.conf.d/$(basename "$ub_file")" 644
  done
fi

if [ -d /etc/pihole ]; then
  backup_and_copy_root "$REPO_DIR/config/pihole/pihole.toml" "/etc/pihole/pihole.toml" 640
  backup_and_copy_root "$REPO_DIR/config/pihole/dnsmasq.conf" "/etc/pihole/dnsmasq.conf" 644
  if [ -f "$REPO_DIR/config/pihole/custom.list" ]; then
    backup_and_copy_root "$REPO_DIR/config/pihole/custom.list" "/etc/pihole/hosts/custom.list" 644
  fi
else
  log_warn "/etc/pihole existiert noch nicht. Installiere zuerst Pi-hole v6 und führe restore.sh erneut aus."
fi

# 6. Samba & Speicher-Hinweise
log_info "6. Prüfe Samba-Konfiguration..."
if [ -f "$REPO_DIR/config/samba/smb.conf" ]; then
  if command -v testparm >/dev/null 2>&1 && testparm -s "$REPO_DIR/config/samba/smb.conf" >/dev/null 2>&1; then
    backup_and_copy_root "$REPO_DIR/config/samba/smb.conf" "/etc/samba/smb.conf" 644
  else
    log_warn "smb.conf konnte nicht mit testparm validiert werden – bitte manuell prüfen."
  fi
fi

if [ -f "$REPO_DIR/config/system/fstab" ]; then
  log_warn "/etc/fstab wird wegen maskierter Passwörter und Laufwerks-UUIDs nicht automatisch überschrieben."
  log_info "Referenz liegt unter: $REPO_DIR/config/system/fstab"
fi

# 7. Optional: Statisches Netzwerk-Profil
if [ "$RESTORE_NETWORK" = true ]; then
  log_info "7. Stelle statisches Ethernet-Profil und resolv.conf wieder her..."
  backup_and_copy_root "$REPO_DIR/config/system/wired-connection-1.nmconnection" \
    "/etc/NetworkManager/system-connections/Wired connection 1.nmconnection" 600
  backup_and_copy_root "$REPO_DIR/config/system/resolv.conf" "/etc/resolv.conf" 644
else
  log_info "7. Netzwerk-Profil übersprungen (nutze --with-network zum Aktivieren)."
fi

# 8. Minecraft-Server Konfigurationen (~/minecraft-server)
log_info "8. Stelle Minecraft-Konfigurationen wieder her..."
MC_DIR="$TARGET_HOME/minecraft-server"
if [ -d "$REPO_DIR/minecraft" ]; then
  for mc_file in server.properties bukkit.yml spigot.yml permissions.yml; do
    [ -f "$REPO_DIR/minecraft/$mc_file" ] && \
      backup_and_copy_user "$REPO_DIR/minecraft/$mc_file" "$MC_DIR/$mc_file" 644
  done
  [ -f "$REPO_DIR/minecraft/update-paper.sh" ] && \
    backup_and_copy_user "$REPO_DIR/minecraft/update-paper.sh" "$MC_DIR/update-paper.sh" 755

  for cfg_file in paper-global.yml paper-world-defaults.yml; do
    [ -f "$REPO_DIR/minecraft/config/$cfg_file" ] && \
      backup_and_copy_user "$REPO_DIR/minecraft/config/$cfg_file" "$MC_DIR/config/$cfg_file" 644
  done

  for plugin_rel in Geyser-Spigot/config.yml squaremap/config.yml Chunky/config.yml; do
    [ -f "$REPO_DIR/minecraft/plugins/$plugin_rel" ] && \
      backup_and_copy_user "$REPO_DIR/minecraft/plugins/$plugin_rel" "$MC_DIR/plugins/$plugin_rel" 644
  done
fi

# 9. Systemd neu laden & Dienste prüfen
log_info "9. Lade Systemd-Konfiguration neu..."
run_cmd sudo systemctl daemon-reload

echo "================================================================="
echo "[FERTIG] Wiederherstellung abgeschlossen!"
echo "Sicherung vorheriger Dateien: $BACKUP_DIR"
echo "Nächste manuelle Schritte bei kompletter Neuinstallation:"
echo "  1. Pi-hole Web-Passwort setzen:   sudo pihole setpassword"
echo "  2. Samba-Passwort setzen:         sudo smbpasswd -a $TARGET_USER"
echo "  3. Dienste aktivieren/neu starten: sudo systemctl restart unbound pihole-FTL smbd pihole-games-webhook"
echo "================================================================="
