#!/usr/bin/env python3
import os
import time
import psutil
import json
import struct
import subprocess
import re
from PIL import Image, ImageDraw, ImageFont

# --- KONFIGURATION ---
BASE_DIR = "/home/raspby/docker-server"
ICON_PATH = os.path.join(BASE_DIR, "display/icons")
STATUS_FILE = os.path.join(BASE_DIR, "sentinel_status.json")
FB_DEVICE = "/dev/fb0"
PHYS_WIDTH, PHYS_HEIGHT = 320, 480
HDD_PATH = "/mnt/hdd" if os.path.ismount("/mnt/hdd") else "/"

# Welche Services sollen als Icon überwacht werden?
SERVICES = {
    "pihole": "pihole",
    "unbound": "unbound",
    "jellyfin": "jellyfin",
    "samba": "samba",
    "docker": "docker"
}

def get_font(name, size):
    paths = [
        f"/usr/share/fonts/truetype/dejavu/{name}.ttf",
        f"/usr/share/fonts/truetype/liberation/{name}.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf"
    ]
    for p in paths:
        if os.path.exists(p): return ImageFont.truetype(p, size)
    return ImageFont.load_default()

def clean_log_line(line):
    """Entfernt Zeitstempel und Metadaten für sauberes Deduplizieren"""
    # Entfernt [Datum] oder ISO-Format am Anfang
    line = re.sub(r'^.*?\[.*?\]\s*', '', line) 
    line = re.sub(r'^\d{4}-\d{2}-\d{2}.*?\s+', '', line) 
    line = re.sub(r'^\d{2}:\d{2}:\d{2}\s+', '', line)
    # Entfernt Prozess-IDs wie [123]
    line = re.sub(r'\[\d+\]:\s*', '', line)
    return line.strip()

def get_top_errors():
    """Aggregiert Fehler aus Docker und System"""
    error_list = []
    seen_errors = set()
    
    # 1. DOCKER LOGS
    try:
        # Hole Namen aller laufenden Container
        containers = subprocess.check_output("docker ps --format '{{.Names}}'", shell=True).decode().splitlines()
        
        for c in containers:
            try:
                # --tail 20: Nur die allerneuesten Zeilen prüfen
                logs = subprocess.check_output(f"docker logs --tail 20 {c} 2>&1", shell=True).decode()
                for line in logs.splitlines():
                    # Suche nach signifikanten Keywords
                    if any(x in line.lower() for x in ["error", "failed", "fatal", "panic", "exception", "critical"]):
                        clean = clean_log_line(line)
                        # Nur aufnehmen wenn lang genug und noch nicht gesehen
                        if clean not in seen_errors and len(clean) > 5:
                            seen_errors.add(clean)
                            # Format: [Container] Fehler...
                            error_list.append(f"[{c[:6]}] {clean[:30]}") 
            except: pass
    except: pass

    # 2. SYSTEM LOGS (journalctl)
    try:
        # -p 3 (Error level), -n 20 (letzte 20)
        syslogs = subprocess.check_output("journalctl -p 3 -n 20 -o cat", shell=True).decode()
        for line in syslogs.splitlines():
            clean = clean_log_line(line)
            if clean not in seen_errors and len(clean) > 5:
                seen_errors.add(clean)
                error_list.append(f"[SYS] {clean[:30]}")
    except: pass

    # Die neuesten 5 Fehler zurückgeben
    return error_list[-5:][::-1]

def main():
    try: fb = open(FB_DEVICE, "wb")
    except: fb = None

    font_head = get_font("DejaVuSans-Bold", 16)
    font_sub  = get_font("DejaVuSans-Bold", 14)
    font_log  = get_font("DejaVuSans-Bold", 12)
    font_foot = get_font("DejaVuSans-Bold", 15)

    last_log_scan = 0
    top_errors = []
    blink_state = True

    while True:
        # --- SYSTEM DATEN ---
        cpu = psutil.cpu_percent()
        ram = psutil.virtual_memory().percent
        with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
            temp = int(f.read()) / 1000
        
        hdd = psutil.disk_usage(HDD_PATH)
        hdd_free = int(hdd.free / (1024**3))

        # Check laufende Container für Icons
        running = []
        try:
            cmd = "docker ps --format '{{.Names}}'"
            running = subprocess.check_output(cmd, shell=True).decode().lower().splitlines()
        except: pass

        # --- LOG SCAN (Alle 30 Sek) ---
        if time.time() - last_log_scan > 30:
            top_errors = get_top_errors()
            last_log_scan = time.time()

        # --- ZEICHNEN ---
        img = Image.new("RGB", (480, 320), (10, 10, 10)) # Dunkler Hintergrund
        draw = ImageDraw.Draw(img)

        # 1. Header & CPU
        draw.text((10, 5), "MEDIAPI SENTINEL", font=font_sub, fill=(180, 180, 180))
        draw.rectangle((10, 28, 470, 42), outline=(80, 80, 80))
        
        # CPU Farbe (Blau -> Rot bei Last)
        bar_col = (0, 180, 255) if cpu < 80 else (255, 50, 0)
        draw.rectangle((10, 28, 10 + (cpu * 4.6), 42), fill=bar_col)
        draw.text((380, 5), f"CPU: {cpu}%", font=font_sub, fill=(255, 255, 255))

        # 2. Service Icons (Mitte Oben)
        x_off = 20
        y_ico = 60
        for name, key in SERVICES.items():
            path = os.path.join(ICON_PATH, f"{name}.png")
            if os.path.exists(path):
                try:
                    icon = Image.open(path).convert("RGBA").resize((48, 48))
                    img.paste(icon, (x_off, y_ico), icon)
                    
                    active = any(key in c for c in running)
                    col = (0, 255, 0) if active else (255, 0, 0)
                    if not active and blink_state: col = (150, 0, 0) # Blinken bei Down
                    
                    draw.ellipse((x_off+38, y_ico+38, x_off+46, y_ico+46), fill=col, outline=(0,0,0))
                except: pass
            x_off += 90

        # 3. LOG BEREICH (Mitte Unten)
        y_log = 130
        draw.line((10, y_log, 470, y_log), fill=(60, 60, 60))
        
        if not top_errors:
            # Alles OK
            draw.text((10, y_log+10), "SYSTEM STATUS: HEALTHY", font=font_head, fill=(0, 255, 0))
            draw.text((10, y_log+40), "No critical errors found.", font=font_log, fill=(150, 200, 150))
            draw.text((10, y_log+60), f"Monitoring {len(running)} Containers.", font=font_log, fill=(150, 200, 150))
            draw.text((10, y_log+80), f"RAM Usage: {ram}%", font=font_log, fill=(150, 200, 150))
        else:
            # Fehler Anzeigen
            title_col = (255, 50, 50) if blink_state else (255, 150, 150)
            draw.text((10, y_log+5), f"DETECTED ERRORS ({len(top_errors)})", font=font_head, fill=title_col)
            
            y_err = y_log + 35
            for err in top_errors:
                # Format: [SOURCE] Message
                try:
                    if "]" in err:
                        src, msg = err.split("]", 1)
                        src += "]"
                    else:
                        src, msg = "", err
                    
                    # Quelle in Orange/Gelb
                    draw.text((10, y_err), src, font=font_log, fill=(255, 200, 0))
                    # Nachricht in Weiß
                    draw.text((85, y_err), msg, font=font_log, fill=(230, 230, 230))
                except:
                    draw.text((10, y_err), err, font=font_log, fill=(255, 255, 255))
                y_err += 22

        # 4. FUSSZEILE (2 Spalten: Temp & HDD)
        y_foot = 285
        draw.line((0, 280, 480, 280), fill=(60, 60, 60))
        
        # Temp Links
        temp_col = (255, 255, 0) if temp < 70 else (255, 0, 0)
        draw.text((20, y_foot), f"TEMP: {temp:.0f}°C", font=font_foot, fill=temp_col)
        
        # HDD Rechts
        hdd_col = (0, 255, 0) if hdd_free > 50 else (255, 100, 0)
        draw.text((280, y_foot), f"HDD: {hdd_free} GB", font=font_foot, fill=hdd_col)

        # 5. OUTPUT
        if fb:
            out = img.rotate(270, expand=True)
            pixels = out.load()
            blob = bytearray()
            for py in range(PHYS_HEIGHT):
                for px in range(PHYS_WIDTH):
                    r, g, b = pixels[px, py]
                    val = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)
                    blob.extend(struct.pack('<H', val))
            fb.seek(0)
            fb.write(blob)
            fb.flush()

        # Status JSON für CLI Tool
        with open(STATUS_FILE, "w") as f:
            log_msg = "Healthy" if not top_errors else f"{len(top_errors)} Errors"
            json.dump({"ai_output": log_msg, "ph_pct": 0}, f)

        blink_state = not blink_state
        time.sleep(5)

if __name__ == "__main__":
    main()
