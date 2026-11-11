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
* **Display & Kühlung:** 3,5-Zoll SPI TFT-Touchscreen (ILI9486 / XPT2046) mit aktivem Gehäuselüfter

---

## 📂 Verzeichnisstruktur

### 1. Im Git-Repository (`~/pi-server-config`)
```text
pi-server-config/
├── .github/
│   └── workflows/
│       └── validate-configs.yml   # GitHub Actions CI-Pipeline (Bash- & YAML-Check)
├── config/
│   ├── samba/                     # Samba-Freigaben (smb.conf)
│   ├── system/                    # Systemdateien (bashrc, bash_aliases, config.txt, fstab, sshd_config)
│   │   ├── systemd/               # Eigene Systemd-Services & Timer (/etc/systemd/system)
│   │   ├── usr_local_bin/         # Eigene System-Skripte wie mc-start (/usr/local/bin)
│   │   └── xorg.conf.d/           # TFT-Display Kalibrierung
│   └── unbound/                   # Unbound DNS-Resolver Konfigurationen
├── minecraft/
│   └── worlds/                    # Archiv für heruntergeladene Custom-Maps (.zip)
├── scripts/
│   └── git-sync-configs.sh        # Farbiger Backup-Sync aller Systemdateien ins Git-Repo
└── README.md                      # System-Dokumentation & Befehlsreferenz
