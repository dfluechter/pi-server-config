#!/usr/bin/env python3
import json, os, time

STATUS_FILE = "/home/raspby/docker-server/sentinel_status.json"

def display():
    if not os.path.exists(STATUS_FILE):
        print("Warte auf Daten vom Hintergrund-Dienst...")
        return

    try:
        with open(STATUS_FILE, "r") as f:
            d = json.load(f)
        
        cpu = d.get('cpu', 0)
        temp = d.get('temp', 0.0)
        disk = d.get('disk_free', 'N/A')
        ph_pct = d.get('ph_pct', 0)
        ph_cnt = d.get('ph_count', 0)
        ai_msg = d.get('ai_output', 'Analyse läuft...')
        update = d.get('last_update', 'Unbekannt')

        os.system('clear')
        print("\033[94m" + "="*60)
        print(f" AI-SENTINEL DASHBOARD | Letztes Update: {update}")
        print("="*60 + "\033[0m")
        
        # Temp wird Gelb ab 70, Rot ab 75
        t_color = "\033[92m" # Grün
        if temp >= 70: t_color = "\033[93m" # Gelb
        if temp >= 75: t_color = "\033[91m" # Rot

        print(f"CPU: {cpu}%  |  Temp: {t_color}{temp:.1f}°C\033[0m  |  Disk: {disk}GB frei")
        
        # Pi-hole Status
        ph_color = "\033[92m" if ph_cnt > 0 else "\033[91m"
        print(f"Pi-hole: {ph_color}{ph_pct}% geblockt\033[0m ({ph_cnt} Anfragen heute)")
        
        print("\033[93m" + "-"*60)
        print(" TOP 5 ANALYSE (Gemini AI)")
        print("-"*60 + "\033[0m")
        print(ai_msg)
        print("\033[94m" + "="*60 + "\033[0m")
        
    except Exception as e:
        print(f"Fehler: {e}")

if __name__ == "__main__":
    try:
        while True:
            display()
            time.sleep(5)
    except KeyboardInterrupt:
        print("\nView beendet.")
