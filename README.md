# Hi there 👋 I'm Dominik


## 🏗️ Stack & Services

The server runs on **Docker Compose** and hosts the following services:

* **Jellyfin**: Media Server (Movies, TV Shows).
* **Pi-hole + Unbound**: Network-wide Ad Blocking & Recursive DNS.
* **Samba**: Network Attached Storage (NAS) access.
* **Monitoring**: Doozle, InfluxDB & Grafana (for data logging).

## 📟 "The Sentinel" - OLED Display Script

A custom Python script (`scripts/display_stats.py`) controls the attached OLED display to show real-time metrics:

* **CPU & RAM Usage**
* **Disk Storage**
* **CPU Temperature** (with color-coded warnings)
* **Uptime & IP Address**

The script handles button inputs to toggle the display (saving OLED lifetime).

## 🚀 Setup & Deployment

1.  **Clone the repository:**
    ```bash
    git clone git@github.com:dfluechter/pi-server-config.git
    cd pi-server-config
    ```

2.  **Create Environment Variables:**
    Create a `.env` file (excluded from Git for security):
    ```ini
    PIHOLE_PASSWORD=secret
    SAMBA_USER=user
    SAMBA_PASS=secret
    ```

3.  **Start Services:**
    ```bash
    docker-compose up -d
    ```

## 📂 Structure

* `docker-compose.yml`: Main service definition.
* `scripts/`: Python scripts for hardware automation.
* `etc-*/`: Configuration files mapped to containers.

<img width="720" height="1280" alt="Designer (1)" src="https://github.com/user-attachments/assets/a319430b-fb75-43e0-83ef-f17d70c8a3df" />
=======
> Building reliable home labs, Raspberry Pi servers, and delightful developer tooling.


I'm a passionate maker and software engineer who loves turning ideas into reliable systems — from Pi-based home servers to small-scale media and networking stacks. This README is a living snapshot of what I'm building, my skills, and how to collaborate.

---
*Created by Dominik Flüchter 2026*
=======

## 🔭 Currently
- Maintaining and improving my Raspberry Pi server config and services (Pi-hole, Unbound, Jellyfin, Samba, etc.).
- Experimenting with lightweight, resilient home infrastructure and automation.
- Learning more about container security and efficient CI/CD for edge devices.

## ⚡ Highlights
- Reliable local DNS + ad-blocking with unbound + Pi-hole.
- Self-hosted media streaming with Jellyfin.
- Headless NAS and media sharing via Samba on cheap hardware.
- Focus on minimal, maintainable configs and clear documentation.

## 🛠️ Top skills
- Linux / Raspberry Pi administration
- Docker & docker-compose
- DNS & networking (Unbound, Pi-hole, dnsmasq)
- Media servers (Jellyfin)
- Shell scripting & small automation
- Backup strategies and disk management

## ⭐ Featured projects
- [pi-server-config](https://github.com/dfluechter/pi-server-config) — My Raspberry Pi server configuration and docker-compose setup (Pi-hole, Unbound, Jellyfin, Samba).


(If you'd like these to be real links and descriptions, send me the repo names and a 1–2 line summary for each.)

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
- Want badges, more automation (like GitHub Actions status), or a different style? I can generate those once I have your preferred services and links.

---
Thank you for visiting — let's build something practical and well-documented!
