#!/usr/bin/env bash
# 新機器一鍵建置：./install.sh
# 只想重建 symlink：./install.sh link
# 已存在的設定檔、已手動安裝的 App 都會先問過才覆蓋
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# 問 y/N，預設 N；沒有 tty（非互動執行）一律當 N
ask() {
  local reply
  [[ -t 0 ]] || return 1
  read -r -p "$1 [y/N] " reply
  [[ $reply == [yY]* ]]
}

OVERWRITE_ALL=0

# 目標已存在時問要不要覆蓋；d 看差異、a 之後全部覆蓋
confirm_overwrite() {
  local src=$1 dst=$2 reply
  ((OVERWRITE_ALL)) && return 0
  [[ -t 0 ]] || return 1
  [[ -L "$dst" ]] && info "$dst 目前連到 $(readlink "$dst")"
  while true; do
    read -r -p "$dst 已存在，要覆蓋嗎？（原檔會備份）[y]是 [N]否 [d]看差異 [a]全部覆蓋 " reply
    case $reply in
      [yY]) return 0 ;;
      [aA]) OVERWRITE_ALL=1; return 0 ;;
      [dD]) diff -u "$dst" "$src" | less || true ;;
      *) return 1 ;;
    esac
  done
}

# repo 路徑 -> 家目錄裡的目標路徑
LINKS=(
  "zsh/.zshrc|$HOME/.zshrc"
  "zsh/.zprofile|$HOME/.zprofile"
  "git/.gitconfig|$HOME/.gitconfig"
  "git/ignore|$HOME/.config/git/ignore"
  "mise/config.toml|$HOME/.config/mise/config.toml"
  "starship/starship.toml|$HOME/.config/starship.toml"
  "ghostty/config.ghostty|$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
  "cmux/cmux.json|$HOME/.config/cmux/cmux.json"
  "claude/keybindings.json|$HOME/.claude/keybindings.json"
  "claude/statusline.sh|$HOME/.claude/statusline.sh"
)

link_all() {
  for pair in "${LINKS[@]}"; do
    src="$DOTFILES/${pair%%|*}"
    dst="${pair#*|}"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
      continue
    fi
    if [[ -e "$dst" || -L "$dst" ]]; then
      if ! confirm_overwrite "$src" "$dst"; then
        info "略過 $dst"
        continue
      fi
      mkdir -p "$BACKUP"
      mv "$dst" "$BACKUP/"
      info "備份 $dst -> $BACKUP/"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    info "連結 $dst"
  done
}

install_homebrew() {
  if ! xcode-select -p >/dev/null 2>&1; then
    info "安裝 Xcode Command Line Tools（裝完再重跑一次本腳本）"
    xcode-select --install
    exit 0
  fi
  if ! command -v brew >/dev/null 2>&1; then
    info "安裝 Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

# 列出 App 已存在、但不是 brew 裝的 cask（例如手動下載的 cmux）
existing_app_casks() {
  local casks
  casks=$(sed -nE 's/^cask "([^"]+)".*/\1/p' "$DOTFILES/Brewfile")
  [[ -n "$casks" ]] || return 0
  # shellcheck disable=SC2086
  brew info --cask --json=v2 $casks | /usr/bin/python3 -c '
import json, os, sys
for c in json.load(sys.stdin)["casks"]:
    if c.get("installed"):
        continue
    for a in c["artifacts"]:
        if "app" in a:
            target = a.get("target") or os.path.join("/Applications", a["app"][0])
            if os.path.exists(target):
                print(c["token"])
                break
'
}

install_packages() {
  # 已有 App 的 cask 會讓 brew bundle 失敗：問要不要讓 brew 接管，不要就從 Brewfile 濾掉
  local brewfile="$DOTFILES/Brewfile" skip="" cask
  for cask in $(existing_app_casks); do
    if ask "$cask 已手動安裝，要改由 brew 管理嗎？（--adopt，App 會被 brew 的版本覆蓋）"; then
      brew install --cask --adopt "$cask"
    else
      skip="${skip:+$skip|}$cask"
    fi
  done
  if [[ -n "$skip" ]]; then
    info "跳過 cask：${skip//|/ }"
    brewfile="$(mktemp)"
    grep -vE "^cask \"($skip)\"" "$DOTFILES/Brewfile" >"$brewfile"
  fi

  info "brew bundle"
  brew bundle --file="$brewfile"

  # .zshrc 會 source ~/.local/bin/env，由 uv 的安裝程式產生
  command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh
  command -v claude >/dev/null 2>&1 || curl -fsSL https://claude.ai/install.sh | bash
  command -v bun >/dev/null 2>&1 || curl -fsSL https://bun.sh/install | bash

  # mods 以本機資料夾 marketplace 安裝：直接讀 repo 內的檔案，改完 /reload-plugins 生效
  info "Claude Code mods"
  claude plugin marketplace add "$DOTFILES/claude/mods"
  claude plugin install ports-backlog@dotfiles

  info "mise install"
  mise install
  mise exec -- npm install -g pnpm
}

case "${1:-all}" in
  link) link_all ;;
  all)
    install_homebrew
    link_all
    install_packages
    info "完成，重開 terminal 生效"
    ;;
  *) echo "usage: $0 [all|link]" >&2; exit 1 ;;
esac
