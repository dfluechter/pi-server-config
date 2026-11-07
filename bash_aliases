# Einzelabfrage mit sudo-Rechten fuer NVMe-Temperatur
alias status='sudo /usr/local/bin/status'

# Live-Monitor alle 2 Sekunden ueber watch
status-live() {
    sudo -v
    sudo watch -c -t -n 2 /usr/local/bin/status
}
alias bat='batcat'
alias cat='batcat'
