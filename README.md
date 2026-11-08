# Raspberry Pi 5 Home-Server Konfiguration (`raspi5`)

![Raspberry Pi 5](https://img.shields.io/badge/Hardware-Raspberry%20Pi%205-C51A4A?style=flat-square&logo=raspberry-pi&logoColor=white)
![Debian Linux](https://img.shields.io/badge/OS-Debian%20Linux-A81D33?style=flat-square&logo=debian&logoColor=white)
[Pi-hole](https://img.shields.io/badge/DNS-Pi--hole%20%26%20Unbound-96060C?style=flat-square&logo=pihole&logoColor=white)
![Jellyfin](https://img.shields.io/badge/Media-Jellyfin%20Server-00A4DC?style=flat-square&logo=jellyfin&logoColor=white)
![Samba](https://img.shields.io/badge/Storage-Samba%20NAS-4A90E2?style=flat-square&logo=linux&logoColor=white)
![Minecraft](https://img.shields.io/badge/Gaming-Minecraft%20Server-62B47A?style=flat-square&logo=minecraft&logoColor=white)

Dieses Repository enthält alle wichtigen System-, Netzwerk- und Hardware- Konfigurationsdateien sowie Wartungsskripte für meinen Raspberry Pi 5 Home-Server (`raspi5`).

---

##📂 Verzeichnisstruktur

```text
pi-server-config/
├── config/
│   ├── pihole/          # Pi-hole Konfigurationen (pihole-FTL.conf, setupVars.conf, dnsmasq.d)
│   ├── samba/           # Samba-Freigaben (smb.conf)
│   ├── system/          # Systemdateien (bashrc, bash_aliases, config.txt, fstab, hosts, xorg)
│   └── unbound/         # Unbound DNS-Resolver Konfigurationen
├── minecraft/           # Minecraft-Server Setup, Plan-Skript & Server-Configs
├── scripts/
│   └── git-sync-configs.sh  # Automatisches Backup-Skript für alle modifizierten Dateien
└── README.md            # Dokumentation & Befehlsreferenz

## ⚡ Highlights
- Reliable local DNS + ad-blocking with unbound + Pi-hole.
- Self-hosted media streaming with Jellyfin.
- Headless NAS and media sharing via Samba on cheap hardware.
- Focus on minimal, maintainable configs and clear documentation.

## 🛠️ Top skills
- Linux / Raspberry Pi administration
- DNS & networking (Unbound, Pi-hole, dnsmasq)
- Media servers (Jellyfin)
- Shell scripting & small automation
- Backup strategies and disk management

## ⭐ Featured projects
- [pi-server-config](https://github.com/dfluechter/pi-server-config) — My Raspberry Pi server configuration (Pi-hole, Unbound, Jellyfin, Samba).


## 📫 How to reach me
- GitHub: [@dfluechter](https://github.com/dfluechter)
- Email: dominik.fluechter@googlemail.com
- Website / Blog: https://dfluechter.ipv64.de
- Twitter / X: @FluchterDominik

## 🤝 Open to
- Collaborating on home-lab and edge-infrastructure projects
- Consulting on small-scale server setups
- Helping maintain or document Docker-based deployments

## 📈 GitHub stats
![Top Langs](https://github-readme-stats.vercel.app/api/top-langs?username=dfluechter&layout=compact&theme=radical)
![Stats](https://github-readme-stats.vercel.app/api?username=dfluechter&show_icons=true&theme=radical)

---

## 🧩 How you can help / contribute
- Star or fork repositories you find useful.
- Open issues with reproducible steps if something breaks.
- Submit PRs for documentation, small fixes, or additional device support.

---

## 📝 Notes
- This README is a template. Replace placeholder links and text with your preferred contact info, project descriptions, and pronouns.
- Thank you for visiting — let's build something practical and well-documented!
