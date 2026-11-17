#!/usr/bin/env python3
import hmac
import html
import json
import os
import subprocess
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

BIND_IP = os.environ.get("BIND_IP", "192.168.2.128")
PORT = int(os.environ.get("PORT", "8765"))
EXPECTED_AUTH = os.environ.get("WEBHOOK_TOKEN", "")
AUTO_OFF_SECONDS = int(os.environ.get("AUTO_OFF_SECONDS", "1800"))

if not EXPECTED_AUTH:
    raise SystemExit("WEBHOOK_TOKEN fehlt in der Umgebung.")

lock = threading.Lock()
auto_off_timer = None


def call_toggle_cli(action):
    res = subprocess.run(
        ["/usr/local/bin/pihole-games-toggle", action],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(res.stdout.strip())


def auto_disable():
    with lock:
        call_toggle_cli("off")


def execute_action(action):
    global auto_off_timer
    with lock:
        state = call_toggle_cli(action)
        if auto_off_timer is not None:
            auto_off_timer.cancel()
            auto_off_timer = None
        if state["enabled"] and AUTO_OFF_SECONDS > 0:
            auto_off_timer = threading.Timer(AUTO_OFF_SECONDS, auto_disable)
            auto_off_timer.daemon = True
            auto_off_timer.start()
        state["auto_off_minutes"] = AUTO_OFF_SECONDS // 60 if state["enabled"] else 0
        return state


class WebhookHandler(BaseHTTPRequestHandler):
    def is_authorized(self, query):
        incoming_auth = query.get("token", [""])[0]
        auth_header = self.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            incoming_auth = auth_header[7:].strip()
        return hmac.compare_digest(incoming_auth.encode("utf-8"), EXPECTED_AUTH.encode("utf-8"))

    def handle_request(self):
        parsed = urlparse(self.path)
        query = parse_qs(parsed.query)
        if not self.is_authorized(query):
            self.send_response(403)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(b"403 Forbidden: Ungueltiges Token")
            return

        route = parsed.path.strip("/") or "status"
        if route not in {"on", "off", "toggle", "status"}:
            self.send_response(404)
            self.end_headers()
            return

        state = execute_action(route)
        accept = self.headers.get("Accept", "")
        if "application/json" in accept:
            payload = json.dumps(state).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return

        enabled = state["enabled"]
        bg = "#14532d" if enabled else "#7f1d1d"
        status_text = "AKTIVIERT (Werbung erlaubt)" if enabled else "DEAKTIVIERT (Werbung blockiert)"
        next_action = "off" if enabled else "on"
        btn_text = "Jetzt wieder blockieren" if enabled else "Für Spiele freischalten (30 Min.)"
        escaped_auth = html.escape(EXPECTED_AUTH, quote=True)

        page = f"""<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pi-hole Android-Spiele</title>
  <style>
    body {{ font-family: system-ui, sans-serif; background: #0f172a; color: #f8fafc;
           display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }}
    .card {{ background: #1e293b; padding: 2rem; border-radius: 1rem; text-align: center;
            max-width: 360px; width: 90%; box-shadow: 0 10px 25px rgba(0,0,0,.4); }}
    .badge {{ background: {bg}; padding: .75rem 1rem; border-radius: .6rem; font-weight: 700; margin: 1rem 0; }}
    a.btn {{ display: block; background: #2563eb; color: #fff; text-decoration: none;
            padding: 1rem; border-radius: .6rem; font-weight: 700; margin-top: 1.25rem; }}
  </style>
</head>
<body>
  <div class="card">
    <h2>Gruppe: Android-Spiele</h2>
    <div class="badge">{status_text}</div>
    <a class="btn" href="/{next_action}?token={escaped_auth}">{btn_text}</a>
  </div>
</body>
</html>""".encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(page)))
        self.end_headers()
        self.wfile.write(page)

    def do_GET(self):
        self.handle_request()

    def do_POST(self):
        self.handle_request()

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    server = ThreadingHTTPServer((BIND_IP, PORT), WebhookHandler)
    server.serve_forever()
