#!/usr/bin/env python3
"""Trackpad-tuner local HTTP server.

Serves the calibration game UI and exposes three POST endpoints the game
calls via fetch():

  POST /set-curve  {"curve": "custom 1.0 0.0 1.0 ..."}
       -> shells out to `hyprctl keyword input.touchpad.accel_profile "<curve>"`
       -> returns {"ok": true} or {"ok": false, "error": "..."}

  POST /save       {"curve": "custom 1.0 0.0 1.0 ..."}
       -> backs up ~/.config/hypr/input.conf, replaces the accel_profile
          line inside the per-device block, returns {"ok": true, "backup": "<path>"}
       -> does NOT auto-reload Hyprland; caller decides

  POST /reset      {}
       -> shells out to `hyprctl reload` to revert any live keyword changes
       -> returns {"ok": true}

Binds 127.0.0.1 only — no remote attack surface.
"""

from __future__ import annotations
import argparse
import json
import re
import shutil
import subprocess
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

CONFIG_PATH = Path.home() / ".config" / "hypr" / "input.conf"
INDEX_PATH = Path(__file__).resolve().parent / "index.html"

CURVE_RE = re.compile(r"^custom(?:\s+[-+]?\d+(?:\.\d+)?){4,}\s*$")


def _hyprctl(*args: str) -> tuple[bool, str]:
    try:
        r = subprocess.run(
            ["hyprctl", *args],
            capture_output=True, text=True, timeout=5, check=False,
        )
        out = (r.stdout + r.stderr).strip()
        return r.returncode == 0 and "error" not in out.lower(), out
    except Exception as exc:
        return False, str(exc)


def _set_curve(curve: str) -> tuple[bool, str]:
    if not CURVE_RE.match(curve):
        return False, f"refusing malformed curve: {curve!r}"
    return _hyprctl("keyword", "input.touchpad.accel_profile", curve)


def _reset() -> tuple[bool, str]:
    return _hyprctl("reload")


def _save(curve: str) -> tuple[bool, str]:
    if not CURVE_RE.match(curve):
        return False, f"refusing malformed curve: {curve!r}"
    if not CONFIG_PATH.exists():
        return False, f"missing {CONFIG_PATH}"
    backup = CONFIG_PATH.with_suffix(
        f".conf.bak.{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    )
    shutil.copy2(CONFIG_PATH, backup)
    text = CONFIG_PATH.read_text()
    # Replace any `accel_profile = custom ...` inside the touchpad device block.
    # We're permissive: any accel_profile line that starts with `custom` is replaced.
    new_text, n = re.subn(
        r"(?m)^(\s*)accel_profile\s*=\s*custom\s+[\d.\s]+$",
        rf"\1accel_profile = {curve}",
        text,
    )
    if n == 0:
        return False, "no accel_profile = custom ... line found to replace"
    CONFIG_PATH.write_text(new_text)
    return True, str(backup)


class Handler(BaseHTTPRequestHandler):
    server_version = "TrackpadTuner/1.0"

    def log_message(self, fmt, *args):  # quieter
        pass

    def _json(self, code: int, body: dict) -> None:
        data = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self) -> None:  # noqa: N802
        if self.path in ("/", "/index.html"):
            try:
                body = INDEX_PATH.read_bytes()
            except OSError as exc:
                self._json(500, {"ok": False, "error": str(exc)})
                return
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)
            return
        self._json(404, {"ok": False, "error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        length = int(self.headers.get("Content-Length", "0") or 0)
        try:
            payload = json.loads(self.rfile.read(length).decode()) if length else {}
        except json.JSONDecodeError as exc:
            self._json(400, {"ok": False, "error": f"bad json: {exc}"})
            return

        if self.path == "/set-curve":
            ok, msg = _set_curve(str(payload.get("curve", "")))
            self._json(200 if ok else 400, {"ok": ok, "msg": msg})
            return
        if self.path == "/save":
            ok, msg = _save(str(payload.get("curve", "")))
            self._json(200 if ok else 400, {"ok": ok, "backup": msg if ok else "", "error": "" if ok else msg})
            return
        if self.path == "/reset":
            ok, msg = _reset()
            self._json(200 if ok else 400, {"ok": ok, "msg": msg})
            return
        self._json(404, {"ok": False, "error": "unknown endpoint"})


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=38483)
    ap.add_argument("--host", default="127.0.0.1")
    args = ap.parse_args()

    httpd = HTTPServer((args.host, args.port), Handler)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        _reset()


if __name__ == "__main__":
    main()
