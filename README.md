# Raspberry Pi 5 Home-Server Konfiguration (`raspi5`)

<p align="left">
  <img src="https://img.shields.io/badge/Hardware-Raspberry%20Pi%205%20(4GB%20RAM)-C51A4A?style=flat-square&logo=raspberry-pi&logoColor=white" height="20" alt="Hardware Raspberry Pi 5" />
  <img src="https://img.shields.io/badge/OS-Debian%2013%20(Trixie)-A81D33?style=flat-square&logo=debian&logoColor=white" height="20" alt="OS Debian 13" />
  <img src="https://img.shields.io/badge/Storage-128GB%20NVMe%20SSD-0071C5?style=flat-square&logo=ssd&logoColor=white" height="20" alt="Storage 128GB NVMe SSD" />
  <img src="https://img.shields.io/badge/DNS-Pi--hole%20v6%20%26%20Unbound-96060C?style=flat-square&logo=pihole&logoColor=white" height="20" alt="DNS Pi-hole v6 and Unbound" />
  <img src="https://img.shields.io/badge/Media-Jellyfin%20Server-00A4DC?style=flat-square&logo=jellyfin&logoColor=white" height="20" alt="Media Jellyfin Server" />
  <img src="https://img.shields.io/badge/NAS-Samba%20%26%20Speedport%20SMB-4A90E2?style=flat-square&logo=linux&logoColor=white" height="20" alt="NAS Samba and Speedport SMB" />
  <img src="https://img.shields.io/badge/Gaming-PaperMC%2026.3%20%26%20Geyser-62B47A?style=flat-square&logo=minecraft&logoColor=white" height="20" alt="Gaming PaperMC 26.3 and Geyser" />
  <img src="https://img.shields.io/github/actions/workflow/status/dfluechter/pi-server-config/validate-configs.yml?style=flat-square&logo=github&label=Config%20Validation" height="20" alt="GitHub Actions Config Validation" />
</p>

Zentrales Konfigurations-, Skript- und Dokumentations-Repository für meinen Raspberry Pi 5 Home-Server (`raspi5`). Alle System-, Netzwerk-, DNS-, Medien- und Minecraft-Server-Einstellungen werden hier versioniert und über automatisierte Skripte gesichert.

---

## 🔗 Aufrufbare URLs, Ports & Dienste im Heimnetz

* **Hostname:** `raspi5` (bzw. `pi.hole`)
* **Lokale IPv4-Adresse:** `192.168.2.128`
* **Gateway / Router:** `192.168.2.1` (Telekom Speedport Smart 3)

| Dienst / Applikation | Port & Protokoll | Aufruf über Hostname | Aufruf über IP-Adresse | Beschreibung |
| :--- | :---: | :--- | :--- | :--- |
| **Pi-hole v6 Web-Admin (HTTP)** | `80/TCP` | `http://raspi5/admin` | `http://192.168.2.128/admin` | Netzwerkweiter Adblocker, DHCP & DNS-Dashboard |
| **Pi-hole v6 Web-Admin (HTTPS)** | `443/TCP` | `https://raspi5/admin` | `https://192.168.2.128/admin` | Verschlüsseltes Pi-hole Web-Interface |
| **Jellyfin Media Server** | `8096/TCP` | `http://raspi5:8096` | `http://192.168.2.128:8096` | Streaming-Server für Filme, Serien & Musik |
| **Squaremap (Minecraft Live-Map)** | `8080/TCP` | `http://raspi5:8080` | `http://192.168.2.128:8080` | Interaktive 2D-Echtzeitkarte der Minecraft-Welt im Browser |
| **Minecraft Server (Java Edition)** | `25565/TCP` | `raspi5:25565` | `192.168.2.128:25565` | PaperMC 26.3 Server für PC-Spieler |
| **Minecraft Bedrock (GeyserMC)** | `19132/UDP` | `raspi5` (Port `19132`) | `192.168.2.128` (Port `19132`) | Crossplay-Zugang für Nintendo Switch, Xbox One & Mobile |
| **Samba Dateifreigabe (SMB)** | `445/TCP` | `\\raspi5` | `\\192.168.2.128` | Windows-Netzwerkfreigabe (`wsdd2` & `smbd` aktiv) |
| **Pi-hole DNS-Server** | `53/TCP+UDP` | `raspi5` | `192.168.2.128` | Primärer DNS-Resolver im lokalen Netzwerk |
| **Unbound DNS-Upstream** | `5335/TCP+UDP` | `127.0.0.1#5335` | `127.0.0.1#5335` | Lokaler rekursiver DNS-Server (nur intern für Pi-hole) |
| **SSH-Fernwartung** | `22/TCP` | `ssh raspi@raspi5` | `ssh raspi@192.168.2.128` | Konsolenzugriff auf den Raspberry Pi 5 |

---

## 🛠️ Hardware-Ausstattung & System-Architektur

* **System:** Raspberry Pi 5 Model B Rev 1.0 (ARM Cortex-A76 Quad-Core @ 2.4 GHz, **4 GB RAM**)
* **Betriebssystem:** Debian GNU/Linux 13 (64-Bit `aarch64`, Kernel `6.18.x-v8-16k+`)
* **Systemspeicher:** 128 GB X15 Lite NVMe SSD via PCIe (`/dev/nvme0n1p2`)
* **Netzwerkspeicher (NAS):** 1 TB USB-Speicher am Telekom Speedport Smart 3, eingebunden unter `/mnt/speedport-usb` via CIFS/SMB
* **Kühlung:** Aktiver Gehäuselüfter (PWM-gesteuert)

---

## 📂 Verzeichnisstruktur

### 1. Im Git-Repository (`~/pi-server-config`)
```text
pi-server-config/
├── .github/
│   └── workflows/
│       └── validate-configs.yml   # GitHub Actions CI-Pipeline (Bash- & YAML-Check)
├── config/
│   ├── pihole/                    # Pi-hole Konfigurationen (pihole.toml, dnsmasq.conf, custom.list)
│   ├── samba/                     # Samba-Freigaben (smb.conf)
│   ├── system/                    # Systemdateien (bashrc, bash_aliases, config.txt, fstab, sshd_config)
│   │   ├── systemd/               # Eigene Systemd-Units & Drop-ins (ohne System-Symlinks)
│   │   └── usr_local_bin/         # Eigene System-Skripte wie mc-start & status (/usr/local/bin)
│   └── unbound/                   # Unbound DNS-Resolver Konfigurationen
├── minecraft/
│   ├── config/                    # PaperMC globale & Welten-Konfigurationen
│   ├── plugins/                   # Konfigurationsdateien für Geyser-Spigot, squaremap & Chunky
│   ├── bukkit.yml                 # Bukkit-Grundeinstellungen
│   ├── permissions.yml            # Server-Berechtigungen
│   ├── server.properties          # Minecraft Haupteinstellungen
│   ├── spigot.yml                 # Spigot-Optimierungen
│   └── update-paper.sh            # Skript zum Aktualisieren von PaperMC
├── scripts/
│   └── git-sync-configs.sh        # Farbiger Backup-Sync aller System- & Minecraft-Configs
└── README.md                      # System-Dokumentation & Befehlsreferenz


2. Produktives Minecraft-Serververzeichnis (~/minecraft-server)Der Server wird bewusst manuell bei Bedarf über /usr/local/bin/mc-start gestartet (kein dauerhafter Hintergrund-Dienst), um die 4 GB RAM im Normalbetrieb zu schonen.Heruntergeladene Welten-Archive (.zip) liegen lokal unter ~/minecraft-server/worlds/, damit das Git-Repository schlank bleibt.Installierte Plugins:Geyser-Spigot & Floodgate: Ermöglicht Spielern auf Nintendo Switch und Xbox One (Bedrock) das Mitspielen auf dem Java-Server ohne zusätzlichen Java-Account.Squaremap: Ressourcenschonender interner Webserver (Port 8080) für die 2D-Live-Weltkarte im Browser.Chunky: Vorab-Generierung von Welten zur Vermeidung von CPU-Spitzen beim Erkunden.spark: Integrierter Performance- & CPU-Profiler (Flame Graph Analyse).🎮 Minecraft Server Verwaltung & Befehle (4 GB RAM Setup)1. Server starten & beenden (Linux-Shell)BefehlAusführungsortBeschreibungmc-startLinux-Terminal (überall)Startet PaperMC 26.3 mit Java 25, Aikar's Flags und 2500M RAM (/usr/local/bin/mc-start)sudo nano /usr/local/bin/mc-startLinux-TerminalStartskript und RAM-Zuweisung (MEMORY="2500M") bearbeitennano ~/minecraft-server/server.propertiesLinux-TerminalWeltnamen (level-name=adventure_world), Sichtweite (view-distance=8) & Spielmodus anpassenstopMinecraft-ServerkonsoleSpeichert alle Welten/Spielerdaten und fährt den Server sauber herunter2. Wichtige Befehle in der laufenden Minecraft-ServerkonsoleKonsolen-Befehl (ohne /)Funktion & Zwecksquaremap fullrender minecraft:overworldRendert die gesamte Oberwelt für die Browser-Karte unter http://raspi5:8080squaremap fullrender minecraft:the_netherRendert den Nether für die Browser-Kartesquaremap fullrender minecraft:the_endRendert das Ende für die Browser-Kartechunky world minecraft:overworldWählt die Oberwelt für die Chunk-Vorabgenerierung auschunky radius 2000Setzt den Radius für die Vorabgenerierung auf 2000 Blöckechunky start / chunky progressStartet die Weltgenerierung bzw. zeigt den aktuellen Fortschritt anspark healthZeigt sofort TPS (Soll: 20.0), MSPT, CPU-Last und aktuellen RAM-Verbrauchspark profiler openErstellt sofort einen Link zum interaktiven spark Web-Viewer (Flame Graph)spark profiler start --timeout 60Zeichnet 60 Sekunden lang ein detailliertes CPU-Profil auf und gibt die URL ausspark profiler start --only-ticks-over 50 --timeout 120Zeichnet über 2 Minuten nur Lag-Spitzen (Ticks > 50 ms) aufgeyser help / geyser listZeigt Geyser-Befehle und alle aktuell verbundenen Bedrock-/Konsolenspieler an3. Neue Custom-Map (.zip) entpacken & einbindenBash# 1. In das lokale Welten-Archiv wechseln und Inhalt prüfen
cd ~/minecraft-server/worlds
ls -la

# 2. ZIP-Archiv in einen temporären Ordner entpacken
unzip deine-welt.zip -d extracted_world/

# 3. Entpackten Welt-Ordner in das aktive Minecraft-Serververzeichnis verschieben
mv extracted_world/* ~/minecraft-server/adventure_world
rm -rf extracted_world

# 4. In der server.properties "level-name=adventure_world" eintragen
nano ~/minecraft-server/server.properties
4. IMDb-ID Benennungsschema für JellyfinDamit Jellyfin Filme beim Scan sofort zu 100 % eindeutig zuordnet, wird die IMDb-ID aus der URL (imdb.com/title/ttXXXXXXX/) im Format [imdbid-ttXXXXXXX] an den Ordner- und Dateinamen gehängt:Ordner: Matrix (1999) [imdbid-tt0133093]Datei: Matrix (1999) [imdbid-tt0133093].mkv💻 Allgemeine Bash-Befehlsreferenz (raspi5)1. Konfigurations-Backup ausführen & zu GitHub pushenBash# Backup-Skript starten (synchronisiert System-, Pi-hole-, Samba- & Minecraft-Configs)
~/pi-server-config/scripts/git-sync-configs.sh

# Änderungen prüfen, signiert committen und zu GitHub pushen
cd ~/pi-server-config
git status
git add .
git commit -m "docs(readme): remove tft display references and update directory tree"
git pull --rebase origin main
git push origin main
2. Pi-hole v6 & Unbound DiagnoseBash# Vollständigen Pi-hole Diagnosebericht erstellen
pihole -d

# Pi-hole FTL & Unbound Dienststatus prüfen
sudo systemctl status pihole-FTL
sudo systemctl status unbound

# Pi-hole v6 Hauptkonfiguration bearbeiten
sudo nano /etc/pihole/pihole.toml
3. System, Speicher, Netzwerk & Samba verwaltenBash# Hostname anpassen
sudo hostnamectl set-hostname raspi5

# System aktualisieren
sudo apt update && sudo apt full-upgrade -y

# Arbeitsspeicher (RAM), Temperatur und Speicherplatz prüfen
free -h
vcgencmd measure_temp
df -h

# Alle Netzwerk-Mounts aus der /etc/fstab neu einbinden (z. B. /mnt/speedport-usb)
sudo mount -a
findmnt -t cifs,ext4

# Samba-Konfiguration prüfen und Dienste neu starten
testparm
sudo systemctl restart smbd nmbd
4. Git-Konfiguration & SSH-Signierung (Verified Commits)Bash# Git-Identität, Rebase-Standard und SSH-Signierung einrichten
git config --global user.name "Dominik Flüchter"
git config --global user.email "dominik.fluechter@googlemail.com"
git config --global pull.rebase true
git config --global gpg.format ssh
git config --global commit.gpgsign true

🔒 Sicherheitshinweis für Backups
Das Skript scripts/git-sync-configs.sh ersetzt beim Kopieren der /etc/fstab automatisch alle Klartext-Passwörter (password=... oder pass=...) durch **********.

Große Laufzeitdaten (wie Welten-Ordner, .zip-Archive, .jar-Dateien oder Logs) sind über die .gitignore vom Upload ausgeschlossen.
