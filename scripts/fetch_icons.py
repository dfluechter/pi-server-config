import os
import requests
from PIL import Image
from io import BytesIO

# Speicherort
ICON_PATH = os.path.expanduser("~/docker-server/display/icons")
os.makedirs(ICON_PATH, exist_ok=True)

# URLs zu offiziellen/passenden Logos (PNG/Transparent bevorzugt)
URLS = {
    "pihole": "https://upload.wikimedia.org/wikipedia/commons/0/00/Pi-hole_Logo.png",
    "docker": "https://cdn-icons-png.flaticon.com/512/919/919853.png",
    "jellyfin": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/Jellyfin_-_icon-transparent.svg/960px-Jellyfin_-_icon-transparent.svg.png",
    "samba": "https://freepngimg.com/thumb/penguin/63229-samba-installation-servers-computer-build-linux-software.png",
    "unbound": "https://www.netdata.cloud/img/unbound.png" 
}

def process_icon(name, url):
    try:
        print(f"Lade {name}...", end="")
        headers = {'User-Agent': 'Mozilla/5.0'}
        r = requests.get(url, headers=headers, timeout=10)
        
        if r.status_code == 200:
            img = Image.open(BytesIO(r.content))
            
            # Konvertieren und Resizen
            img = img.convert("RGBA")
            img = img.resize((48, 48), Image.Resampling.LANCZOS)
            
            save_path = os.path.join(ICON_PATH, f"{name}.png")
            img.save(save_path, "PNG")
            print(f" OK -> {save_path}")
        else:
            print(f" Fehler: HTTP {r.status_code}")
    except Exception as e:
        print(f" Fehler: {e}")

if __name__ == "__main__":
    print("--- Lade Service Icons ---")
    for name, url in URLS.items():
        process_icon(name, url)
