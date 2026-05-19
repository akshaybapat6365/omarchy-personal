#!/usr/bin/env bash
# rmpc on_song_change hook → regenerate theme from album art
# 1. Extract current cover via `rmpc albumart`
# 2. K-means cluster colors → WCAG-AA-mapped theme RON
# 3. rmpc hot-reloads themes/current-song.ron automatically
set -euo pipefail

THEME_GEN="$HOME/.cargo/bin/rmpc-theme-gen"
COVER_DIR="/tmp/rmpc"
COVER="$COVER_DIR/current_cover"
THEME_OUT="$HOME/.config/rmpc/themes/current-song.ron"

mkdir -p "$COVER_DIR" "$(dirname "$THEME_OUT")"

# Extract cover (rmpc writes the binary cover image to $COVER)
if ! rmpc albumart --output "$COVER" 2>/dev/null; then
    # No cover available (no track playing or art missing) — leave existing theme
    exit 0
fi

# Skip work if cover image is identical to last run (saves ~1ms on repeats)
SHA_FILE="$COVER_DIR/last_cover.sha256"
NEW_SHA="$(sha256sum "$COVER" 2>/dev/null | awk '{print $1}')"
if [[ -f "$SHA_FILE" ]] && [[ "$NEW_SHA" == "$(cat "$SHA_FILE")" ]] && [[ -z "${RMPC_THEME_FORCE:-}" ]]; then
    exit 0
fi
echo "$NEW_SHA" > "$SHA_FILE"

# Generate the theme (CIELAB K-means → WCAG-AA contrast solver)
"$THEME_GEN" \
    --image "$COVER" \
    --theme-output "$THEME_OUT" \
    --space CIELAB \
    --k 30 \
    >/dev/null 2>&1 || true
