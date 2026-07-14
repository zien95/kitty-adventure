#!/usr/bin/env python3
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import argparse
import os


class CorsRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()


def main():
    parser = argparse.ArgumentParser(
        description="Serve Kitty Adventure update files from your Mac."
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=str(Path.home() / "KittyAdventureUpdates"),
        help="Directory containing latest.json and release files.",
    )
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8081)
    args = parser.parse_args()

    directory = Path(args.directory).expanduser().resolve()
    directory.mkdir(parents=True, exist_ok=True)
    os.chdir(directory)

    server = ThreadingHTTPServer((args.host, args.port), CorsRequestHandler)
    print(f"Serving {directory} on http://{args.host}:{args.port}/")
    print(
        f"Use http://YOUR_MAC_IP:{args.port}/latest.json "
        "in Kitty Adventure Settings."
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
