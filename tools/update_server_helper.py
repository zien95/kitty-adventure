#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
import time
from urllib.request import urlopen


class UpdateServerSupervisor:
    def __init__(
        self,
        project_dir: Path,
        update_dir: Path,
        port: int,
        ngrok: str,
        tunnel_url: str,
    ) -> None:
        self.project_dir = project_dir
        self.update_dir = update_dir
        self.port = port
        self.ngrok = ngrok
        self.tunnel_url = tunnel_url.rstrip("/")
        self.running = True
        self.server_process: subprocess.Popen[str] | None = None
        self.tunnel_process: subprocess.Popen[str] | None = None
        self.public_base_url = ""

        self.logs_dir = update_dir / "logs"
        self.run_dir = update_dir / "run"
        self.logs_dir.mkdir(parents=True, exist_ok=True)
        self.run_dir.mkdir(parents=True, exist_ok=True)

    def stop(self, *_: object) -> None:
        self.running = False
        self._stop_children()

    def run(self) -> None:
        signal.signal(signal.SIGTERM, self.stop)
        signal.signal(signal.SIGINT, self.stop)

        while self.running:
            try:
                self.public_base_url = ""
                self._start_file_server()
                self._start_tunnel()
                self._write_server_info()

                while self.running:
                    if (
                        self.server_process
                        and self.server_process.poll() is not None
                    ):
                        break
                    if (
                        self.tunnel_process
                        and self.tunnel_process.poll() is not None
                    ):
                        break
                    time.sleep(2)
            except Exception as error:
                print(
                    f"Update helper restart after error: {error}",
                    file=sys.stderr,
                    flush=True,
                )
            finally:
                self._stop_children()

            if self.running:
                time.sleep(3)

    def _start_file_server(self) -> None:
        server_log = (self.logs_dir / "update-server.log").open("a")
        command = [
            sys.executable,
            str(self.project_dir / "tools" / "serve_updates.py"),
            str(self.update_dir),
            "--host",
            "0.0.0.0",
            "--port",
            str(self.port),
        ]
        self.server_process = subprocess.Popen(
            command,
            stdout=server_log,
            stderr=subprocess.STDOUT,
            text=True,
        )
        (self.run_dir / "update-server.pid").write_text(
            f"{self.server_process.pid}\n"
        )

        deadline = time.time() + 15
        while time.time() < deadline:
            if self.server_process.poll() is not None:
                raise RuntimeError("Update file server stopped during startup.")
            try:
                with urlopen(
                    f"http://127.0.0.1:{self.port}/latest.json", timeout=1
                ):
                    return
            except Exception:
                time.sleep(0.25)
        raise RuntimeError("Update file server did not become ready.")

    def _start_tunnel(self) -> None:
        if (
            not self.ngrok
            or not Path(self.ngrok).exists()
            or not self.tunnel_url
        ):
            return

        tunnel_log_path = self.logs_dir / "ngrok.log"
        tunnel_log = tunnel_log_path.open("w")
        command = [
            self.ngrok,
            "http",
            "--url",
            self.tunnel_url,
            str(self.port),
            "--log",
            "stdout",
            "--log-format",
            "json",
        ]
        self.tunnel_process = subprocess.Popen(
            command,
            stdout=tunnel_log,
            stderr=subprocess.STDOUT,
            text=True,
        )
        (self.run_dir / "ngrok.pid").write_text(
            f"{self.tunnel_process.pid}\n"
        )

        deadline = time.time() + 30
        while time.time() < deadline:
            tunnel_log.flush()
            try:
                log_text = tunnel_log_path.read_text()
            except OSError:
                log_text = ""

            if (
                '"msg":"started tunnel"' in log_text
                and f'"url":"{self.tunnel_url}"' in log_text
            ):
                self.public_base_url = self.tunnel_url
                return

            if self.tunnel_process.poll() is not None:
                return

            time.sleep(0.25)

        self.tunnel_process.terminate()
        try:
            self.tunnel_process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.tunnel_process.kill()

    def _write_server_info(self) -> None:
        local_ip = self._local_ip()
        public_ip = self._public_ip()
        lan_base_url = f"http://{local_ip}:{self.port}"
        direct_public_base_url = (
            f"http://{public_ip}:{self.port}" if public_ip else ""
        )
        worldwide_ready = "yes" if self.public_base_url else "no"

        values = {
            "GENERATED_AT": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
            "UPDATE_DIR": str(self.update_dir),
            "PORT": str(self.port),
            "LOCAL_IP": local_ip,
            "PUBLIC_IP": public_ip,
            "LAN_BASE_URL": lan_base_url,
            "LAN_MANIFEST_URL": f"{lan_base_url}/latest.json",
            "DIRECT_PUBLIC_BASE_URL": direct_public_base_url,
            "DIRECT_PUBLIC_MANIFEST_URL": (
                f"{direct_public_base_url}/latest.json"
                if direct_public_base_url
                else ""
            ),
            "PUBLIC_BASE_URL": self.public_base_url,
            "PUBLIC_MANIFEST_URL": (
                f"{self.public_base_url}/latest.json"
                if self.public_base_url
                else ""
            ),
            "WORLDWIDE_READY": worldwide_ready,
            "HELPER_PID": str(os.getpid()),
            "SERVER_PID": (
                str(self.server_process.pid) if self.server_process else ""
            ),
            "TUNNEL_PID": (
                str(self.tunnel_process.pid) if self.tunnel_process else ""
            ),
            "SERVER_LOG": str(self.logs_dir / "update-server.log"),
            "TUNNEL_LOG": str(self.logs_dir / "ngrok.log"),
        }

        lines = [
            "Kitty Adventure Update Server",
            "=============================",
            *(f"{key}={value}" for key, value in values.items()),
            "",
            "Notes:",
            "- LAN_MANIFEST_URL works on the same Wi-Fi.",
            "- PUBLIC_MANIFEST_URL works worldwide when WORLDWIDE_READY=yes.",
            "- PUBLIC_IP alone still needs router forwarding and may fail with CGNAT.",
            "- The ngrok dev-domain URL stays the same after helper restarts.",
            "",
        ]
        text = "\n".join(lines)

        (self.project_dir / "UPDATE_SERVER_INFO.txt").write_text(text)
        (self.update_dir / "UPDATE_SERVER_INFO.txt").write_text(text)
        (self.update_dir / "server-info.json").write_text(
            json.dumps(values, indent=2) + "\n"
        )

    def _stop_children(self) -> None:
        for process in (self.tunnel_process, self.server_process):
            if process and process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
        self.tunnel_process = None
        self.server_process = None

    @staticmethod
    def _local_ip() -> str:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            sock.connect(("8.8.8.8", 80))
            return sock.getsockname()[0]
        except OSError:
            return "127.0.0.1"
        finally:
            sock.close()

    @staticmethod
    def _public_ip() -> str:
        try:
            result = subprocess.run(
                [
                    "/usr/bin/curl",
                    "-4",
                    "-fsS",
                    "--max-time",
                    "8",
                    "https://api.ipify.org",
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            return result.stdout.strip()
        except (OSError, subprocess.SubprocessError):
            return ""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-dir", required=True)
    parser.add_argument("--directory", required=True)
    parser.add_argument("--port", type=int, default=8081)
    parser.add_argument("--ngrok", default="")
    parser.add_argument("--tunnel-url", default="")
    args = parser.parse_args()

    supervisor = UpdateServerSupervisor(
        project_dir=Path(args.project_dir).expanduser().resolve(),
        update_dir=Path(args.directory).expanduser().resolve(),
        port=args.port,
        ngrok=args.ngrok,
        tunnel_url=args.tunnel_url,
    )
    supervisor.run()


if __name__ == "__main__":
    main()
