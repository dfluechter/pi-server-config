# ==========================================
# ~/pi-server-config/bash_aliases
# ==========================================

# --- Navigation & Listing ---
alias ls='ls --color=auto'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# --- Bat als cat-Ersatz (Syntax Highlighting) ---
alias bat='batcat'
alias cat='batcat --paging=never'

# --- System, Updates & Temperatur ---
alias update='sudo apt update && sudo apt upgrade -y'
alias diskusage='df -h -T -x tmpfs -x devtmpfs'
alias pi-temp='vcgencmd measure_temp'
alias ports='sudo ss -tulpn'

# --- Farbige Logs (Pi-hole v6 & Debian Bookworm Journal) ---
alias plog='sudo pihole tail'
alias pstatus='sudo pihole status'
alias pupdate='sudo pihole -up'
alias syslog='sudo journalctl -f --output=short-precise'
alias errlog='sudo journalctl -p 3 -xb'

# --- Docker & Container Shortcuts ---
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlogs='docker logs -f --tail=100'
alias dcompose='docker compose'

# --- Git Shortcuts ---
alias gs='git status'
alias glog='git log --oneline --graph --decorate -n 20'
alias gpush='git push origin main'
alias gpull='git pull origin main'
