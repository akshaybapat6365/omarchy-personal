#!/usr/bin/env bash
# Claude Code statusLine script.
# Keep this Claude-only: ~/.claude/settings.json invokes this file.

set -u

input="$(cat)"

jq_get() {
  jq -er "$1 // empty" <<<"$input" 2>/dev/null | head -n 1
}

short_dir() {
  local path="${1:-$PWD}"
  path="${path/#$HOME/~}"

  if [[ "$path" == "~" || "$path" != */* ]]; then
    printf '%s' "$path"
    return
  fi

  IFS='/' read -r -a parts <<<"$path"
  local count="${#parts[@]}"
  if (( count > 2 )); then
    printf '.../%s/%s' "${parts[count-2]}" "${parts[count-1]}"
  else
    printf '%s' "$path"
  fi
}

git_summary() {
  local repo="$1"
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  local branch status upstream ahead behind pieces dirty
  branch="$(git -C "$repo" branch --show-current 2>/dev/null)"
  [[ -z "$branch" ]] && branch="$(git -C "$repo" rev-parse --short HEAD 2>/dev/null)"
  [[ -z "$branch" ]] && return 0

  status="$(git -C "$repo" status --porcelain 2>/dev/null)"
  pieces=("$branch")

  if [[ -n "$status" ]]; then
    dirty="$(awk '
      BEGIN {m=0; u=0; s=0; d=0}
      /^\?\?/ {u++; next}
      substr($0,1,1) ~ /[MADRCU]/ {s++}
      substr($0,2,1) ~ /[MD]/ {m++}
      substr($0,1,1) == "D" || substr($0,2,1) == "D" {d++}
      END {
        out="";
        if (s) out=out " +" s;
        if (m) out=out " ~" m;
        if (u) out=out " ?" u;
        if (d) out=out " -" d;
        print out;
      }
    ' <<<"$status")"
    [[ -n "$dirty" ]] && pieces+=("$dirty")
  fi

  upstream="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
  if [[ -n "$upstream" ]]; then
    read -r ahead behind < <(git -C "$repo" rev-list --left-right --count HEAD..."$upstream" 2>/dev/null || printf '0 0')
    [[ "${ahead:-0}" != "0" ]] && pieces+=("up ${ahead}")
    [[ "${behind:-0}" != "0" ]] && pieces+=("down ${behind}")
  fi

  printf '%s' "${pieces[*]}"
}

pct() {
  local value="$1"
  [[ -z "$value" || "$value" == "null" ]] && return 1
  awk -v n="$value" 'BEGIN { if (n ~ /^[0-9.]+$/) printf "%.0f%%", n; else exit 1 }'
}

reset=$'\033[0m'
cyan=$'\033[36m'
bold_cyan=$'\033[1;36m'
dim=$'\033[2m'
yellow=$'\033[33m'

cwd="$(jq_get '.cwd')"
[[ -z "$cwd" ]] && cwd="$(jq_get '.workspace.current_dir')"
[[ -z "$cwd" ]] && cwd="$PWD"

model="$(jq_get '.model.display_name')"
[[ -z "$model" ]] && model="$(jq_get '.model.name')"
[[ -z "$model" ]] && model="$(jq_get '.model.id')"

# Window size: claude-opus-4-7[1m] → "1M", everything else → "200K".
# Real, derivable info — not fake; skip entirely if model.id is unknown.
model_id="$(jq_get '.model.id')"
ctx_window=""
case "$model_id" in
  *"[1m]"*|*"-1m"*) ctx_window="1M" ;;
  "") ;;
  *) ctx_window="200K" ;;
esac

effort="$(jq_get '.model.effort')"
[[ -z "$effort" ]] && effort="$(jq_get '.effort')"

# Output style ("max", "concise" …); skip when default — not informative.
output_style="$(jq_get '.output_style.name')"
[[ "$output_style" == "default" ]] && output_style=""

ctx_remaining="$(jq_get '.context_window.remaining_percentage')"
ctx_used="$(jq_get '.context_window.used_percentage')"
ctx_tokens="$(jq_get '.context_window.used_tokens')"
ctx_max="$(jq_get '.context_window.max_tokens')"

limit_5h="$(jq_get '.rate_limits.five_hour.used_percentage')"
[[ -z "$limit_5h" ]] && limit_5h="$(jq_get '.rate_limits["5h"].used_percentage')"
[[ -z "$limit_5h" ]] && limit_5h="$(jq_get '.rate_limits.primary.used_percentage')"

limit_week="$(jq_get '.rate_limits.seven_day.used_percentage')"
[[ -z "$limit_week" ]] && limit_week="$(jq_get '.rate_limits.weekly.used_percentage')"
[[ -z "$limit_week" ]] && limit_week="$(jq_get '.rate_limits["7d"].used_percentage')"
[[ -z "$limit_week" ]] && limit_week="$(jq_get '.rate_limits.secondary.used_percentage')"

session_id="$(jq_get '.session_id')"
[[ -z "$session_id" ]] && session_id="$(jq_get '.sessionId')"
[[ -z "$session_id" ]] && session_id="${CLAUDE_CODE_SESSION_ID:-}"

# Session name: Claude Code names each session (e.g. "restore-hyprland-config-backup")
# and writes it to the terminal title via OSC. It is not in the statusline JSON,
# so we read the parent terminal's window title from Hyprland and strip the
# leading status glyph (⠐ / ✳ / ⠈ / similar Braille spinners) Claude Code
# prepends to the title.
session_name=""
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  # Walk up to 6 levels of parent PIDs looking for a Hyprland window
  walk_pid=$PPID
  for _ in 1 2 3 4 5 6; do
    [[ -z "$walk_pid" || "$walk_pid" == "0" || "$walk_pid" == "1" ]] && break
    title="$(hyprctl clients -j 2>/dev/null | jq -r --arg p "$walk_pid" '.[] | select(.pid|tostring == $p) | .title' 2>/dev/null | head -n1)"
    if [[ -n "$title" && "$title" != "null" ]]; then
      # Strip the leading status glyph + space.  Claude Code uses Braille spinners
      # (U+2800–U+28FF) and other indicators; remove the first run of non-ASCII
      # printable + trailing space.
      session_name="$(printf '%s' "$title" | sed -E 's/^[^[:alnum:]_-]+[[:space:]]*//' | head -c 80)"
      break
    fi
    walk_pid="$(awk '{print $4}' "/proc/$walk_pid/stat" 2>/dev/null)"
  done
fi

permission_mode="$(jq_get '.permission_mode')"
[[ -z "$permission_mode" ]] && permission_mode="$(jq_get '.permissionMode')"

version="$(jq_get '.version')"
if [[ -z "$version" ]] && command -v claude >/dev/null 2>&1; then
  version="$(claude --version 2>/dev/null | awk '{print $1}' | head -n 1)"
fi

parts=()
parts+=("${bold_cyan}$(short_dir "$cwd")${reset}")

git="$(git_summary "$cwd")"
[[ -n "$git" ]] && parts+=("${cyan}${git}${reset}")

model_part=""
[[ -n "$model" ]] && model_part="$model"
[[ -n "$ctx_window" ]] && model_part="${model_part:+$model_part }${ctx_window}"
[[ -n "$effort" ]] && model_part="${model_part:+$model_part }${effort}"
[[ -n "$model_part" ]] && parts+=("${cyan}${model_part}${reset}")
[[ -n "$output_style" ]] && parts+=("${yellow}${output_style}${reset}")

if ctx="$(pct "$ctx_remaining")"; then
  parts+=("${cyan}ctx ${ctx} left${reset}")
elif ctx="$(pct "$ctx_used")"; then
  parts+=("${cyan}ctx ${ctx} used${reset}")
elif [[ -n "$ctx_tokens" && -n "$ctx_max" ]]; then
  ctx_calc="$(awk -v used="$ctx_tokens" -v max="$ctx_max" 'BEGIN { if (max > 0) printf "%.0f%% left", 100 - (used / max * 100); else exit 1 }' 2>/dev/null)"
  [[ -n "$ctx_calc" ]] && parts+=("${cyan}ctx ${ctx_calc}${reset}")
fi

if limit="$(pct "$limit_5h")"; then
  parts+=("${yellow}5h ${limit}${reset}")
fi

if limit="$(pct "$limit_week")"; then
  parts+=("${yellow}weekly ${limit}${reset}")
fi

[[ -n "$version" ]] && parts+=("${dim}v${version}${reset}")
[[ -n "$permission_mode" ]] && parts+=("${dim}${permission_mode}${reset}")
# Session id: show the FULL UUID (per user preference). If a session name was
# resolved from the terminal title, show it before the UUID for context.
if [[ -n "$session_name" ]]; then
  parts+=("${bold_cyan}${session_name}${reset}")
fi
if [[ -n "$session_id" ]]; then
  parts+=("${dim}${session_id}${reset}")
fi

out=""
for part in "${parts[@]}"; do
  if [[ -z "$out" ]]; then
    out="$part"
  else
    out="${out} · ${part}"
  fi
done

printf '%s' "$out"
