#!/usr/bin/env python3
import http.server, subprocess, os, re, urllib.parse

SCRIPT = os.path.expanduser("~/.config/waybar/scripts/dict-open.fish")

class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        u = urllib.parse.urlparse(self.path)
        svc = u.path.strip("/")
        if svc == "ping":
            self.send_response(200)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(b'{"ok":true}')
            return
        if svc in ("cambridge", "google", "duck"):
            word = urllib.parse.parse_qs(u.query).get("w", [""])[0]
            word = re.sub(r"[^\w\s\-.']", "", word)[:5000]
            env = dict(os.environ, WORD=word)
            subprocess.Popen(["fish", SCRIPT, svc], env=env,
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(b'{"ok":true}')
    def log_message(self, *a): pass

http.server.ThreadingHTTPServer(("127.0.0.1", 7634), H).serve_forever()
