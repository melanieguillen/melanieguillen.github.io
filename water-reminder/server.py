#!/usr/bin/env python3

from __future__ import annotations

import http.server
import socketserver
from pathlib import Path


ROOT = Path(__file__).resolve().parent
WEB_DIR = ROOT / "web"
HOST = "127.0.0.1"
PORT = 8765


class WaterReminderHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_DIR), **kwargs)

    def do_GET(self) -> None:
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(b"ok")
            return

        super().do_GET()

    def log_message(self, format: str, *args) -> None:
        return


class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


def main() -> None:
    with ReusableTCPServer((HOST, PORT), WaterReminderHandler) as httpd:
        print(f"Serving Water Reminder at http://{HOST}:{PORT}")
        httpd.serve_forever()


if __name__ == "__main__":
    main()
