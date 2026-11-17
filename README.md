<a id="readme-top"></a>

<div align="center">

[![Validate Configs](https://github.com/dfluechter/pi-server-config/actions/workflows/validate-configs.yml/badge.svg)](https://github.com/dfluechter/pi-server-config/actions/workflows/validate-configs.yml)
[![Platform](https://img.shields.io/badge/Hardware-Raspberry%20Pi%205-C51A4A?logo=raspberrypi&logoColor=white)](https://github.com/dfluechter/pi-server-config)
[![OS](https://img.shields.io/badge/OS-Debian%20%2F%20Raspberry%20Pi%20OS-A81D33?logo=debian&logoColor=white)](https://github.com/dfluechter/pi-server-config)
[![DNS](https://img.shields.io/badge/DNS-Pi--hole%20v6%20%2B%20Unbound-96060C?logo=pihole&logoColor=white)](https://github.com/dfluechter/pi-server-config)
[![Minecraft](https://img.shields.io/badge/Minecraft-PaperMC%20%2B%20Geyser%2FFloodgate-62B47A)](https://github.com/dfluechter/pi-server-config)

<br />

<a href="https://github.com/dfluechter/pi-server-config">
  <img src="docs/assets/hero-banner.png" alt="pi-server-config Hero Banner" width="100%">
</a>

<br /><br />

<h1 align="center">pi-server-config</h1>

  <p align="center">
    Zentrales Konfigurations-, Automatisierungs- und Disaster-Recovery-Repository für meinen produktiven Raspberry Pi 5 Heimserver.
    <br />
    <a href="#repository-struktur"><strong>Struktur erkunden »</strong></a>
    <br />
    <br />
    <a href="#über-das-projekt">Architektur</a>
    &middot;
    <a href="#erste-schritte">Installation</a>
    &middot;
    <a href="#verwendung">Verwendung</a>
    &middot;
    <a href="#sicherheitskonzept">Sicherheit</a>
  </p>
</div>

<details>
  <summary>Inhaltsverzeichnis</summary>
  <ol>
    <li>
      <a href="#über-das-projekt">Über das Projekt</a>
      <ul>
        <li><a href="#kernkomponenten">Kernkomponenten</a></li>
        <li><a href="#technologien--tech-stack">Technologien & Tech-Stack</a></li>
      </ul>
    </li>
    <li><a href="#repository-struktur">Repository-Struktur</a></li>
    <li>
      <a href="#erste-schritte">Erste Schritte</a>
      <ul>
        <li><a href="#voraussetzungen">Voraussetzungen</a></li>
        <li><a href="#einrichtung">Einrichtung</a></li>
      </ul>
    </li>
    <li><a href="#verwendung">Verwendung</a></li>
    <li><a href="#sicherheitskonzept">Sicherheitskonzept</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#kontakt">Kontakt</a></li>
    <li><a href="#danksagungen">Danksagungen</a></li>
  </ol>
</details>

---

## Über das Projekt

Dieses Repository versioniert sämtliche System-, Netzwerk-, Dienst- und Gaming-Konfigurationen meines **Raspberry Pi 5** (`raspi5`). Ziel ist ein reproduzierbares, abgesichertes Setup mit automatisierter Konfigurations-Synchronisation (`git-sync-configs.sh`), lokalem Secret-Filtering per Git-Hook und kontinuierlicher Validierung über GitHub Actions.

### Kernkomponenten

* **DNS, Ad-Blocking & DHCP (Pi-hole v6 + Unbound):**
  * Autoritativer DHCP-Server im Heimnetzwerk (statische Host-IPv4 auf `eth0`).
  * Lokaler rekursiver DNS-Resolver über **Unbound** (`127.0.0.1#5335`) mit aktiver **DNSSEC**-Validierung.
  * Getrennte Filtergruppen (`Default` für alle Clients, `Android-Spiele` für temporäre Rewarded-Ad-Ausnahmen) inkl. CLI-Toggle (`pihole-games-toggle`) und token-geschütztem LAN-Webhook (`pihole-games-webhook`) mit 30-Minuten-Auto-Off.
* **Media & Dateifreigaben (Jellyfin & Samba):**
  * **Jellyfin Media Server** mit angepassten Systemd-Overrides.
  * **Samba** (`smb.conf`) für lokale Netzwerkfreigaben und persistente Speicher-Mounts (`fstab`).
* **Minecraft Cross-Play Server (PaperMC + Geyser + Floodgate):**
  * Performanter **PaperMC**-Server inklusive **GeyserMC** und **Floodgate** für nahtloses Bedrock-Cross-Play.
  * Karten-Rendering mit **Squaremap**, Welt-Vorberechnung mit **Chunky** und Update-Skript (`update-paper.sh`).
* **Backup, Security & CI:**
  * Automatische Übernahme produktiver Systemdateien nach `~/pi-server-config` inklusive Maskierung sensibler Zugangsdaten.
  * Lokaler `pre-commit`-Hook und GitHub-Actions-CI-Pipeline gegen Syntaxfehler und versehentliche Secret-Leaks.
* **Automatisierte System-Dokumentation (`oh-my-pi` / `omp`):**
  * Ergänzend zum Konfigurations-Backup kommt in einer bewusst getrennten lokalen Arbeitsumgebung (`~/pi-workspace`) der CLI-Agent **`oh-my-pi` (`omp`)** zum Einsatz.
  * Über den spezialisierten Audit-Skill `server-doc-auditor` werden Dienste wie Pi-hole v6, Unbound, Jellyfin, Samba und PaperMC strikt lesend (`read-only`) erfasst, sensible Werte (IPs, UUIDs, Tokens, Zugangsdaten) maskiert und als strukturierte Markdown-Notizen in einem lokalen Obsidian-Vault abgelegt.
  * Durch die Trennung der Verzeichnisse bleiben Arbeitsumgebung, Vault-Notizen und Modell-Konfigurationen strikt vom öffentlichen Server-Repository isoliert.

### Technologien & Tech-Stack

<div align="center">

[![Tech Stack Icoziv](https://i.icoziv.workers.dev/icons?i=raspberrypi,debian,linux,bash,py,git,github,githubactions,sqlite&theme=dark)](https://github.com/thuongtruong109/icoziv)

</div>

<br />

* **Hardware & OS:** Raspberry Pi 5 (`aarch64`), Debian / Raspberry Pi OS, NetworkManager (`nmcli`), Systemd
* **Netzwerk & DNS:** Pi-hole v6 (`pihole-FTL`), Unbound (DNSSEC), `dnsmasq`
* **Dienste:** Jellyfin, Samba, PaperMC, GeyserMC, Floodgate, Squaremap, Chunky
* **Automatisierung, Doku & CI:** Bash, Python 3.13, `oh-my-pi` (`omp`), Git Hooks, GitHub Actions, ShellCheck, yamllint

<p align="right">(<a href="#readme-top">nach oben</a>)</p>

---

## Repository-Struktur

```text
pi-server-config/
├── .github/
│   └── workflows/
│       └── validate-configs.yml       # CI-Validierung (Shell, Python, TOML, YAML, Systemd, Secrets)
├── config/
│   ├── pihole/                        # Pi-hole v6 Konfigurationen (pihole.toml, dnsmasq.conf, custom.list)
│   ├── samba/                         # Samba Freigabe-Konfiguration (smb.conf)
│   ├── system/
│   │   ├── systemd/                   # Eigene Systemd-Units & Overrides (Pi-hole, Jellyfin, Webhook)
│   │   ├── usr_local_bin/             # Eigene CLI-Tools & Webhook-Dienste (pihole-games-*)
│   │   ├── bashrc / bash_aliases      # Shell-Umgebung & Aliase
│   │   ├── config.txt / cmdline.txt   # Boot- & Kernel-Parameter
│   │   ├── fstab                      # Mount-Konfiguration (Passwörter maskiert)
│   │   ├── resolv.conf                # Lokale DNS-Resolver-Konfiguration
│   │   ├── sshd_config                # SSH-Server-Konfiguration
│   │   └── wired-connection-1.nmconnection # Statisches IPv4-Profil (eth0)
│   └── unbound/                       # Rekursiver DNS-Resolver (/etc/unbound/unbound.conf.d/*)
├── docs/
│   └── assets/
│       └── hero-banner.png            # README Hero-Banner
├── minecraft/
│   ├── config/                        # PaperMC Konfigurationen (paper-global.yml, paper-world-defaults.yml)
│   ├── plugins/                       # Plugin-Configs (Geyser-Spigot, Squaremap, Chunky)
│   ├── server.properties              # Minecraft Server-Eigenschaften
│   └── update-paper.sh                # Automatisches PaperMC-Update-Skript
├── scripts/
│   ├── hooks/pre-commit               # Lokaler Secret- & Token-Scanner vor jedem Commit
│   ├── install-minecraft-server.sh    # Installationsskript für PaperMC
│   └── status.sh                      # System- & Dienst-Statusübersicht
├── shell/
│   └── functions.sh                   # Wiederverwendbare Shell-Funktionen
├── git-sync-configs.sh                # Hauptskript zur Synchronisation aller System-Configs
└── README.md
```

<p align="right">(<a href="#readme-top">nach oben</a>)</p>

---

## Erste Schritte

### Voraussetzungen

* Raspberry Pi 5 mit Debian / Raspberry Pi OS (`aarch64`)
* Installiertes `git`, `python3` (ab 3.11 für `tomllib`) und `rsync`
* Konfigurierter SSH-Key (`Ed25519`) für GitHub-Commits

### Einrichtung

1. Repository auf dem Raspberry Pi klonen:
   ```bash
   git clone [https://github.com/dfluechter/pi-server-config.git](https://github.com/dfluechter/pi-server-config.git) ~/pi-server-config
   cd ~/pi-server-config
   ```
2. Lokalen Pre-Commit-Hook aktivieren, damit keine Secrets committet werden können:
   ```bash
   cp scripts/hooks/pre-commit .git/hooks/pre-commit
   chmod +x .git/hooks/pre-commit
   ```
3. Erste Synchronisation der lokalen Konfigurationsdateien ausführen:
   ```bash
   bash git-sync-configs.sh
   ```

<p align="right">(<a href="#readme-top">nach oben</a>)</p>

---

## Verwendung

* **Systemkonfigurationen sichern:**
  ```bash
  cd ~/pi-server-config && bash git-sync-configs.sh
  git status -s
  git add . && git commit -m "chore(config): sync server configurations" && git push
  ```
* **Pi-hole-Gruppe `Android-Spiele` per CLI steuern:**
  ```bash
  sudo pihole-games-toggle status   # Aktuellen Status abfragen
  sudo pihole-games-toggle on       # Gruppe aktivieren
  sudo pihole-games-toggle off      # Gruppe deaktivieren
  sudo pihole-games-toggle toggle   # Zustand umschalten
  ```
* **Pi-hole-Gruppe per LAN-Webhook vom Smartphone umschalten:**
  ```text
  http://<PI-IPv4>:8765/toggle?token=<WEBHOOK_TOKEN>
  ```
* **Server-Status prüfen:**
  ```bash
  bash ~/pi-server-config/scripts/status.sh
  ```

<p align="right">(<a href="#readme-top">nach oben</a>)</p>

---

## Sicherheitskonzept

* **Striktes Secret-Management:** Geheime Tokens (z. B. `WEBHOOK_TOKEN` in `/etc/default/pihole-games-webhook`) und Zugangsdaten verbleiben ausschließlich lokal auf dem Raspberry Pi (`chmod 600`) und werden nicht im Klartext ins Repository kopiert.
* **Automatische Maskierung:** `git-sync-configs.sh` bereinigt Passwörter und API-Keys in Dateien wie `/etc/fstab` oder `.bashrc` vor dem Kopieren.
* **Read-Only-System-Audits:** Dokumentationsläufe über `omp` (`server-doc-auditor`) greifen außerhalb von `~/pi-workspace` ausschließlich lesend auf das System zu und maskieren alle Netzwerk- und Authentifizierungsdaten.
* **Zweistufige Prüfung:** Sowohl der lokale Git-Hook (`scripts/hooks/pre-commit`) als auch der GitHub-Actions-Workflow (`.github/workflows/validate-configs.yml`) blockieren Commits bzw. Pull Requests, sobald verdächtige Schlüssel oder Tokens erkannt werden.

<p align="right">(<a href="#readme-top">nach oben</a>)</p>

---

## Roadmap

- [x] Pi-hole v6 mit Unbound (DNSSEC auf Port `5335`) & autoritativem DHCP einrichten
- [x] Client-spezifische Filtergruppen (`Default` & `Android-Spiele`) inkl. 1-Klick-Webhook implementieren
- [x] PaperMC Minecraft-Server mit GeyserMC, Floodgate, Squaremap und Chunky konfigurieren
- [x] Konfigurations-Sync (`git-sync-configs.sh`), Pre-Commit-Hook und CI-Validierung aufsetzen
- [x] Automatisierte System-Audits via `oh-my-pi` (`omp`) für den lokalen Obsidian-Vault einrichten
- [ ] Monatlichen Systemd-Timer für automatische Unbound Root-Hints-Updates ergänzen
- [ ] Wöchentlichen GitHub-Actions-Check für neue PaperMC- und Plugin-Versionen hinzufügen

<p align="right">(<a href="#readme-top">nach oben</a>)</p>

---

## Kontakt

**Dominik Flüchter** – [@dfluechter](https://github.com/dfluechter)

Projekt-Link: [https://github.com/dfluechter/pi-server-config](https://github.com/dfluechter/pi-server-config)

<p align="right">(<a href="#readme-top">nach oben</a>)</p>

---

## Danksagungen

* [Best-README-Template](https://github.com/othneildrew/Best-README-Template) – Strukturvorlage für diese Dokumentation
* [Icoziv Icons](https://github.com/thuongtruong109/icoziv) & [ReadmeCodeGen SVG Icons Generator](https://www.readmecodegen.com/icons/github-svg-icons-generator) – Tech-Stack-Icons
* [Pi-hole](https://pi-hole.net/) & [NLnet Labs Unbound](https://nlnetlabs.nl/projects/unbound/about/)
* [PaperMC](https://papermc.io/) & [GeyserMC](https://geysermc.org/)

<p align="right">(<a href="#readme-top">nach oben</a>)</p>
