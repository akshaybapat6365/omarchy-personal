#!/usr/bin/env bash
# ytm-patch.sh — idempotent re-applier of the Phase-9 track_table.py patch.
# Run after `uv tool upgrade ytm-player` or any time ytm misbehaves
# with "More values provided than there are columns" on album/playlist nav.
set -euo pipefail

TARGET="$HOME/.local/share/uv/tools/ytm-player/lib/python3.11/site-packages/ytm_player/ui/widgets/track_table.py"

if [[ ! -f "$TARGET" ]]; then
    echo "ytm-patch: target not found: $TARGET" >&2
    exit 1
fi

# Check if patch is already in place
if grep -q "Phase-9 defensive patch" "$TARGET"; then
    echo "ytm-patch: already applied"
    exit 0
fi

# Apply the patch using python (handles edge cases better than sed)
python3 <<PYEOF
import re
from pathlib import Path

target = Path("$TARGET")
src = target.read_text()

old = '''        video_id = track.get("video_id", f"row_{index}")
        # Pass label=" " on every row so Textual reserves the row-label
        # column once any row has a non-None label. _highlight_playing
        # mutates this slot to show ▶ on the playing row.
        return self.add_row(*cells, key=f"{video_id}_{index}", label=" ")'''

new = '''        video_id = track.get("video_id", f"row_{index}")
        # Pass label=" " on every row so Textual reserves the row-label
        # column once any row has a non-None label. _highlight_playing
        # mutates this slot to show ▶ on the playing row.

        # Phase-9 defensive patch: if the cell builder produced more values
        # than the table has columns (happens on certain context pages —
        # tripped a ValueError crash on album/playlist navigation), truncate
        # rather than crash the whole TUI. Truncation loses one column of
        # info on that row; crashing loses the entire view.
        try:
            n_cols = len(self.columns)
        except Exception:
            n_cols = len(cells)
        if len(cells) > n_cols and n_cols > 0:
            cells = cells[:n_cols]

        return self.add_row(*cells, key=f"{video_id}_{index}", label=" ")'''

if old not in src:
    print("ytm-patch: anchor not found — upstream may have changed; manual review needed", flush=True)
    raise SystemExit(2)

target.write_text(src.replace(old, new))
print("ytm-patch: applied to", target)
PYEOF
