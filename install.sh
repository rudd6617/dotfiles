#!/usr/bin/env bash
# 新機器一鍵建置：./install.sh
# 只想重建 symlink：./install.sh link
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# repo 路徑 -> 家目錄裡的目標路徑
LINKS=(
  "zsh/.zshrc|$HOME/.zshrc"
  "zsh/.zprofile|$HOME/.zprofile"
  "git/.gitconfig|$HOME/.gitconfig"
  "git/ignore|$HOME/.config/git/ignore"
  "mise/config.toml|$HOME/.config/mise/config.toml"
  "starship/starship.toml|$HOME/.config/starship.toml"
  "ghostty/config.ghostty|$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
)

link_all() {
  for pair in "${LINKS[@]}"; do
    src="$DOTFILES/${pair%%|*}"
    dst="${pair#*|}"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
      continue
    fi
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" || -L "$dst" ]]; then
      mkdir -p "$BACKUP"
      mv "$dst" "$BACKUP/"
      info "備份 $dst -> $BACKUP/"
    fi
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

install_packages() {
  info "brew bundle"
  brew bundle --file="$DOTFILES/Brewfile"

  # .zshrc 會 source ~/.local/bin/env，由 uv 的安裝程式產生
  command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh
  command -v claude >/dev/null 2>&1 || curl -fsSL https://claude.ai/install.sh | bash
  command -v bun >/dev/null 2>&1 || curl -fsSL https://bun.sh/install | bash

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
