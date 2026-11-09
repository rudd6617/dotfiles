#!/usr/bin/env bash
# Claude Code statusline — cwd · git branch · model · token usage · context usage
#
# Input : session JSON on stdin
#         https://code.claude.com/docs/en/statusline.md
# Output: one line for the status bar (ANSI colour ok)
# Deps  : git, plus python3 (preferred) or jq for JSON — degrades gracefully
#         if none are present.
#
# install.sh links this to ~/.claude/statusline.sh; wire it up in
# ~/.claude/settings.json (global, all projects on this machine):
#   { "statusLine": { "type": "command",
#       "command": "bash ~/.claude/statusline.sh" } }

input=$(cat)

# --- parse the fields we need, tab-separated -------------------------------
# context_window / current_usage are null before the first API call and right
# after /compact, so every field has a default. python3 is far more portable
# across machines than jq, so prefer it.
parse() {
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$input" | python3 -c '
import sys, json
try: d = json.load(sys.stdin)
except Exception: d = {}
m  = d.get("model") or {}
ws = d.get("workspace") or {}
cw = d.get("context_window") or {}
co = d.get("cost") or {}
print("\t".join(str(x) for x in [
    m.get("display_name") or "?",
    ws.get("current_dir") or d.get("cwd") or ".",
    cw.get("total_input_tokens") or 0,
    cw.get("total_output_tokens") or 0,
    cw.get("context_window_size") or 200000,
    cw.get("used_percentage") or 0,
    co.get("total_cost_usd") or 0,
]))'
  elif command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r '
      [ .model.display_name                 // "?",
        .workspace.current_dir // .cwd      // ".",
        .context_window.total_input_tokens  // 0,
        .context_window.total_output_tokens // 0,
        .context_window.context_window_size // 200000,
        .context_window.used_percentage     // 0,
        .cost.total_cost_usd                // 0
      ] | @tsv'
  fi
}

IFS=$'\t' read -r model cwd tok_in tok_out ctx_max ctx_pct cost <<<"$(parse)"
: "${model:=?}"; : "${cwd:=.}"
: "${tok_in:=0}"; : "${tok_out:=0}"; : "${ctx_max:=200000}"; : "${ctx_pct:=0}"; : "${cost:=0}"

# --- cwd: shorten $HOME to ~ ------------------------------------------------
dir=$cwd
case $dir in "$HOME"*) dir="~${dir#"$HOME"}";; esac

# --- git branch (not in the JSON; ask git directly) ------------------------
branch=$(git -C "$cwd" branch --show-current 2>/dev/null) \
  || branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null) \
  || branch=""

# --- humanize: 38123 -> 38.1k, 1200000 -> 1.2M -----------------------------
human() {
  awk -v n="$1" 'BEGIN{
    if      (n>=1000000) printf "%.1fM", n/1000000
    else if (n>=1000)    printf "%.1fk", n/1000
    else                 printf "%d",    n
  }'
}

# --- price: 0.0123 -> $0.012, 5.2 -> $5.20 ---------------------------------
price() {
  awk -v c="$1" 'BEGIN{ if (c>=1) printf "$%.2f", c; else printf "$%.3f", c }'
}

# --- colours ----------------------------------------------------------------
R=$'\033[0m'; CYAN=$'\033[36m'; MAGENTA=$'\033[35m'; BLUE=$'\033[34m'
ctx_pct=${ctx_pct%.*}; ctx_pct=${ctx_pct:-0}
if   [ "$ctx_pct" -ge 80 ]; then CTX=$'\033[31m'   # red
elif [ "$ctx_pct" -ge 50 ]; then CTX=$'\033[33m'   # yellow
else                             CTX=$'\033[32m'   # green
fi

# --- compose (segments separated by spaces, no glyphs) ---------------------
sep="   "
out=""
out+="${BLUE}${dir}${R}${sep}"
[ -n "$branch" ] && out+="${CYAN}${branch}${R}${sep}"
out+="${MAGENTA}${model}${R}"
out+="${sep}↑$(human "$tok_in") ↓$(human "$tok_out")"
out+="${sep}${CTX}ctx ${ctx_pct}%${R} of $(human "$ctx_max")"
out+="${sep}$(price "$cost")"

printf '%s' "$out"
