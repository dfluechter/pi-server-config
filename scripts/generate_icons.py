import base64
import os

icon_path = os.path.expanduser("~/docker-server/display/icons")
os.makedirs(icon_path, exist_ok=True)

# Wir erstellen einfache, farbige Icons direkt aus Hex-Daten/Platzhaltern
# damit dein Display sofort funktioniert.
def create_icon(name, color):
    from PIL import Image, ImageDraw
    img = Image.new('RGBA', (48, 48), color=(0,0,0,0))
    draw = ImageDraw.Draw(img)
    draw.ellipse((2, 2, 45, 45), fill=color, outline=(255,255,255))
    # Anfangsbuchstabe draufschreiben
    draw.text((18, 12), name[0].upper(), fill=(255,255,255))
    img.save(os.path.join(icon_path, f"{name}.png"))
    print(f"Icon erstellt: {name}.png")

icons = {
    "pihole": (220, 0, 0),    # Rot
    "unbound": (0, 100, 200), # Blau
    "docker": (10, 100, 250), # Hellblau
    "jellyfin": (150, 50, 200),# Lila
    "samba": (255, 165, 0)    # Orange
}

for name, color in icons.items():
    create_icon(name, color)
