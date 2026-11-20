<a id="workflow-readme-top"></a>

<div align="center">

[![Upstream Updates](https://github.com/dfluechter/pi-server-config/actions/workflows/check-upstream-updates.yml/badge.svg)](https://github.com/dfluechter/pi-server-config/actions/workflows/check-upstream-updates.yml)
[![Validate Configs](https://github.com/dfluechter/pi-server-config/actions/workflows/validate-configs.yml/badge.svg)](https://github.com/dfluechter/pi-server-config/actions/workflows/validate-configs.yml)
![Schedule](https://img.shields.io/badge/Schedule-Montags%2007%3A00%20UTC-2088FF?logo=githubactions&logoColor=white)
![Python](https://img.shields.io/badge/Runtime-Python%203.13%20Stdlib-3776AB?logo=python&logoColor=white)

<h1>Workflow: Check Upstream Server & Plugin Updates</h1>

<p>
  Automatisierte wöchentliche Versionsprüfung für alle produktiven Server-Komponenten und Minecraft-Plugins auf dem Raspberry Pi 5.
</p>

[![Tech Stack Icoziv](https://i.icoziv.workers.dev/icons?i=githubactions,py,linux,raspberrypi&theme=dark)](https://github.com/thuongtruong109/icoziv)

</div>

---

## Überblick

Der Workflow `.github/workflows/check-upstream-updates.yml` fragt einmal pro Woche die offiziellen Release- und Download-APIs aller eingesetzten Dienste ab und erzeugt eine kompakte Übersichtstabelle im **GitHub Actions Job Summary** (`$GITHUB_STEP_SUMMARY`).

* **Keine Drittanbieter-Abhängigkeiten:** Das Prüfskript nutzt ausschließlich die Python-3.13-Standardbibliothek (`urllib.request`, `json`, `os`).
* **Minimale Berechtigungen:** Läuft mit `permissions: contents: read` und verändert keine Dateien im Repository.
* **Fehlertolerante Abfragen:** Schlägt eine einzelne API temporär fehl, wird der Fehler in der entsprechenden Tabellenzeile protokolliert, ohne die übrigen Prüfungen abzubrechen.

---

## Überwachte Komponenten & API-Quellen

| Komponente | API-Endpunkt / Quelle | Ermittelte Information |
| :--- | :--- | :--- |
| **PaperMC Server** | `fill.papermc.io/v3/projects/paper` | Neueste Minecraft-Version & letzter `STABLE`-Build |
| **GeyserMC (Spigot)** | `download.geysermc.org/v2/projects/geyser/...` | Aktuellste Version & Build-Nummer |
| **Floodgate (Spigot)** | `download.geysermc.org/v2/projects/floodgate/...` | Aktuellste Version & Build-Nummer |
| **Squaremap** | `api.modrinth.com/v2/project/squaremap/version` | Aktuelles Release & kompatible MC-Versionen |
| **Chunky** | `api.modrinth.com/v2/project/chunky/version` | Aktuelles Release & kompatible MC-Versionen |
| **Pi-hole Core** | `api.github.com/repos/pi-hole/pi-hole/releases/latest` | Aktuelles Release-Tag & Veröffentlichungsdatum |
| **Pi-hole FTL** | `api.github.com/repos/pi-hole/FTL/releases/latest` | Aktuelles Release-Tag & Veröffentlichungsdatum |
| **Pi-hole Web** | `api.github.com/repos/pi-hole/web/releases/latest` | Aktuelles Release-Tag & Veröffentlichungsdatum |

---

## Auslöser & Ausführung

* **Automatischer Zeitplan (`schedule`):** Jeden Montag um `07:00 UTC` (`08:00 Uhr` MEZ bzw. `09:00 Uhr` MESZ) über `cron: "0 7 * * 1"`.
* **Manueller Start (`workflow_dispatch`):**
  * **GitHub Web-UI:** *Actions* &rarr; *Check Upstream Server & Plugin Updates* &rarr; *Run workflow* (`main`).
  * **GitHub CLI (`gh`):**
    ```bash
    gh workflow run check-upstream-updates.yml --repo dfluechter/pi-server-config --ref main
    ```

---

## Ergebnis auslesen & Updates einspielen

1. Öffne unter **Actions** den abgeschlossenen Lauf von **Check Upstream Server & Plugin Updates** und scrolle zum Abschnitt **Summary**.
2. Vergleiche die dort gelisteten Build- und Versionsnummern mit deinem Produktivsystem auf dem Raspberry Pi 5:
   * **PaperMC aktualisieren:** `bash ~/minecraft-server/update-paper.sh`
   * **Pi-hole aktualisieren:** `sudo pihole -up`
3. Sichere geänderte Konfigurationsstände anschließend wie gewohnt über `bash ~/pi-server-config/git-sync-configs.sh`.

<p align="right">(<a href="#workflow-readme-top">nach oben</a>)</p>
