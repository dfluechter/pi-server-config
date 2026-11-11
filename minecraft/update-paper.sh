#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# PaperMC Auto-Updater (Fill v3 API mit Farb-Output, SHA256-Check & Symlink)
# Verwendung: ./update-paper.sh [MC_VERSION] (Standard: "latest")
# ==============================================================================

SERVER_DIR="${HOME}/minecraft-server"
PROJECT="paper"
REQUESTED_VERSION="${1:-latest}"
SYMLINK_NAME="paper.jar"
API_BASE="https://fill.papermc.io/v3/projects/${PROJECT}"
USER_AGENT="PaperMC-Updater-Raspi5/1.0 (https://github.com/dfluechter/pi-server-config)"

# ANSI-Farbcodes für übersichtliche Logs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${CYAN}[$(date +'%H:%M:%S')] [INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[$(date +'%H:%M:%S')] [OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[$(date +'%H:%M:%S')] [WARN]${NC} $*"; }
log_error() { echo -e "${RED}[$(date +'%H:%M:%S')] [ERROR]${NC} $*" >&2; }

# Prüfen, ob benötigte Tools installiert sind
for cmd in curl jq sha256sum sort; do
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Das Programm '$cmd' fehlt. Bitte installieren mit: sudo apt install -y $cmd"
        exit 1
    fi
done

mkdir -p "$SERVER_DIR"
cd "$SERVER_DIR"

# Hilfsfunktion für API-Abfragen mit Pflicht-User-Agent
api_get() {
    curl -fsSL -A "$USER_AGENT" -H "Accept: application/json" "$1"
}

# 1. Minecraft-Version ermitteln (entweder "latest" oder spezifische Übergabe)
if [[ "$REQUESTED_VERSION" == "latest" ]]; then
    log_info "Frage neueste Minecraft-Version über die PaperMC Fill v3 API ab..."
    PROJECT_JSON=$(api_get "$API_BASE" || true)
    if [[ -z "$PROJECT_JSON" ]]; then
        log_error "Konnte die PaperMC Fill v3 API unter ${API_BASE} nicht erreichen."
        exit 1
    fi

    # Extrahiert alle verfügbaren Versionen, filtert reine Release-Versionen (Zahlen + Punkte)
    # und sortiert sie per 'sort -V' natürlich aufsteigend (höchste Version steht ganz unten)
    MC_VERSION=$(echo "$PROJECT_JSON" | jq -r '
        if (.versions | type) == "object" then
            .versions[] | .[]
        elif (.versions[0] | type) == "object" then
            .versions[] | (.version.id // .id)
        else
            .versions[]
        end
    ' | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$' | sort -V | tail -n 1)
else
    MC_VERSION="$REQUESTED_VERSION"
fi

if [[ -z "$MC_VERSION" || "$MC_VERSION" == "null" ]]; then
    log_error "Konnte keine gültige Version für '${REQUESTED_VERSION}' ermitteln."
    exit 1
fi
log_info "Ziel-Version: Minecraft ${MC_VERSION}"

# 2. Neuesten Build und Metadaten (Dateiname, URL + SHA256) abrufen
BUILDS_JSON=$(api_get "${API_BASE}/versions/${MC_VERSION}/builds" || true)
if [[ -z "$BUILDS_JSON" ]]; then
    log_error "Version ${MC_VERSION} wurde in der PaperMC-API nicht gefunden."
    exit 1
fi

# Wählt garantiert das Build-Objekt mit der höchsten Build-Nummer (max_by)
LATEST_BUILD_OBJ=$(echo "$BUILDS_JSON" | jq -c '
    (if type == "array" then . else .builds end) | max_by(.id // .build)
')

LATEST_BUILD=$(echo "$LATEST_BUILD_OBJ" | jq -r '.id // .build')

DOWNLOAD_URL=$(echo "$LATEST_BUILD_OBJ" | jq -r '
    .downloads."server:default".url // .downloads.application.url // empty
')

DOWNLOAD_FILE=$(echo "$LATEST_BUILD_OBJ" | jq -r '
    .downloads."server:default".name // .downloads.application.name // empty
')

EXPECTED_SHA256=$(echo "$LATEST_BUILD_OBJ" | jq -r '
    .downloads."server:default".checksums.sha256 // .downloads."server:default".sha256 // .downloads.application.sha256
')

if [[ -z "$LATEST_BUILD" || "$LATEST_BUILD" == "null" ]]; then
    log_error "Kein Build für Version ${MC_VERSION} verfügbar."
    exit 1
fi

# Fallback für Dateiname und Download-URL
if [[ -z "$DOWNLOAD_FILE" || "$DOWNLOAD_FILE" == "null" ]]; then
    DOWNLOAD_FILE="paper-${MC_VERSION}-${LATEST_BUILD}.jar"
fi

if [[ -z "$DOWNLOAD_URL" || "$DOWNLOAD_URL" == "null" ]]; then
    DOWNLOAD_URL="${API_BASE}/versions/${MC_VERSION}/builds/${LATEST_BUILD}/downloads/${DOWNLOAD_FILE}"
fi

log_info "Neuester Build: #${LATEST_BUILD} (${DOWNLOAD_FILE})"

# 3. Prüfen, ob die Datei bereits existiert und der SHA256-Hash übereinstimmt
if [[ -f "$DOWNLOAD_FILE" ]]; then
    CURRENT_SHA256=$(sha256sum "$DOWNLOAD_FILE" | awk '{print $1}')
    if [[ "$CURRENT_SHA256" == "$EXPECTED_SHA256" ]]; then
        log_ok "Paper ist bereits auf dem neuesten Stand (${DOWNLOAD_FILE}). Kein Download nötig."
        ln -sf "$DOWNLOAD_FILE" "$SYMLINK_NAME"
        # Trotzdem alte JARs aufräumen (z. B. die versehentlich geladene 1.7.10)
        find . -maxdepth 1 -type f -name "paper-*.jar" ! -name "$DOWNLOAD_FILE" -exec rm -v {} +
        exit 0
    else
        log_warn "Lokale Datei beschädigt oder veraltet. Lade Build #${LATEST_BUILD} neu herunter..."
    fi
fi

# 4. Neuen Build herunterladen
log_info "Starte Download von: ${DOWNLOAD_URL}"
curl -fL -A "$USER_AGENT" --progress-bar -o "${DOWNLOAD_FILE}.tmp" "$DOWNLOAD_URL"

# 5. SHA256-Prüfsumme verifizieren
log_info "Prüfe SHA256-Signatur..."
DOWNLOADED_SHA256=$(sha256sum "${DOWNLOAD_FILE}.tmp" | awk '{print $1}')

if [[ "$DOWNLOADED_SHA256" != "$EXPECTED_SHA256" ]]; then
    log_error "SHA256-Prüfsumme stimmt nicht überein! Lösche temporäre Datei."
    log_error "Erwartet: ${EXPECTED_SHA256}"
    log_error "Erhalten: ${DOWNLOADED_SHA256}"
    rm -f "${DOWNLOAD_FILE}.tmp"
    exit 1
fi

mv "${DOWNLOAD_FILE}.tmp" "$DOWNLOAD_FILE"
log_ok "SHA256-Prüfung erfolgreich!"

# 6. Symlink aktualisieren und ältere Builds (inkl. 1.7.10) aufräumen
ln -sf "$DOWNLOAD_FILE" "$SYMLINK_NAME"
log_ok "Symlink aktualisiert: ${SYMLINK_NAME} -> ${DOWNLOAD_FILE}"

# Alte paper-*.jar Dateien entfernen (behält nur den aktuellen Build)
find . -maxdepth 1 -type f -name "paper-*.jar" ! -name "$DOWNLOAD_FILE" -exec rm -v {} +

log_ok "Update auf Paper ${MC_VERSION} (Build #${LATEST_BUILD}) erfolgreich abgeschlossen!"
