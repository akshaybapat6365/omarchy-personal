# Trackpad Tuner

Calibration game that measures your hand movement, screen distance, and preferred speed — then derives the right pointer-acceleration curve for `input.touchpad.accel_profile` instead of guessing.

## Quick start

```bash
trackpad-tune
```

Browser opens at `http://127.0.0.1:38483/`. Play 3 rounds (~5 min total). Save the winner.

## What the rounds do

1. **Round 1 — Precision (20 trials, ~1 min)**
   Small targets (12 px radius) at distances 200-600 px. Calibrates slow-speed mapping. Logs Fitts's Law throughput, mean miss distance, std deviation, effective width.

2. **Round 2 — Cross-screen Travel (10 trials, ~30 sec)**
   Large targets (40 px radius) at 600-900 px. Calibrates high-speed amplification. Same metrics, different region of the curve.

3. **Round 3 — A/B Subjective (~2 min)**
   Four candidate curves (Conservative / Balanced / Snappy / Aggressive). Click "Try this curve" — it live-applies via `hyprctl keyword input.touchpad.accel_profile`. Move your cursor freely for 30 sec, rate 1-5 stars. The highest-rated wins.

## Saving

On the final screen, **Save to config** edits `~/.config/hypr/input.conf` in place — specifically the `accel_profile = custom ...` line inside the touchpad `device { ... }` block — and creates a backup at `~/.config/hypr/input.conf.bak.YYYYMMDD-HHMMSS`.

`Copy` puts the curve string on your clipboard for manual paste.

`Restart calibration` reloads the page from scratch.

## Reset / undo

- The **Reset to file defaults** button (top-right) calls `hyprctl reload` to drop any live keyword change and restore whatever is in your input.conf.
- Pressing **Ctrl+C** on the launcher terminal does the same.
- The launcher trap also runs `hyprctl reload` on normal exit, so if you close the browser tab without saving, your file curve takes over again on next reload.
- To undo a Save: replace the `accel_profile` line with the one from the most recent `.bak.*` file.

## Architecture

```
~/.local/bin/trackpad-tune              bash launcher (starts server, opens browser)
~/.local/share/trackpad-tuner/
  server.py                             local HTTP server (~150 lines)
  index.html                            single-file game (~400 lines)
  README.md                             this file
```

The server binds **127.0.0.1 only** — no remote attack surface.

POST endpoints the game uses:
- `POST /set-curve {curve}` → `hyprctl keyword input.touchpad.accel_profile "<curve>"`
- `POST /save {curve}` → backs up input.conf, sed-replaces the accel_profile line
- `POST /reset` → `hyprctl reload`

## Tuning notes

The accel curve format is `custom STEP IN1 OUT1 IN2 OUT2 ...` — input is finger speed in unit/ms, output is the cursor velocity multiplier. The candidates sweep the high-speed amplification (the last point's output) because that's the dominant subjective lever:

- **Conservative** `3.0 2.0` — gentle, precise, takes more strokes to cross the screen
- **Balanced** `3.0 2.8` — moderate amplification, good for most work
- **Snappy** `3.0 3.6` — quick cross-screen travel, can feel twitchy
- **Aggressive** `3.0 4.4` — very quick, requires steady hand

If none feel right, re-run and look at the throughput numbers — higher = better. If both rounds had high overshoot, the curve is over-amplifying.

## Why this exists

Default Hyprland accel curves are designed by upstream for an "average" user. Yours isn't average — high-DPI retina display, specific hand size, specific muscle memory from MacBook trackpads. Measurement-driven tuning gets you to optimal in 5 minutes vs hours of guess-and-tweak.

## Limitations

- **Chromium / Brave only** — Firefox doesn't expose raw pre-acceleration deltas via Pointer Lock's `unadjustedMovement: true`. Not relevant on this machine (no Firefox installed).
- **Touchpad only** — doesn't calibrate the mouse or other input devices.
- **`hyprctl keyword` per-device syntax doesn't work** — Round 3 uses the global `input.touchpad.accel_profile`. When you Save, the per-device block in input.conf is updated. The two should be numerically identical.

## Re-run any time

If your preferences shift (longer use sessions, new external monitor, different posture), just run `trackpad-tune` again. The previous curve is preserved as a `.bak.*` file, so it's a safe loop.
