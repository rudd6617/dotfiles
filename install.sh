#!/usr/bin/env bash
# 新機器一鍵建置：git clone 後執行 ./install.sh
# 之後日常用 make（見 make help），或直接用 chezmoi
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

if ! xcode-select -p >/dev/null 2>&1; then
  info "安裝 Xcode Command Line Tools（裝完再跑一次 ./install.sh）"
  xcode-select --install
  exit 0
fi

# chezmoi 之後會由 Homebrew 接手；第一次先抓一個暫用的
if command -v chezmoi >/dev/null 2>&1; then
  CHEZMOI=chezmoi
elif [[ -x /opt/homebrew/bin/chezmoi ]]; then
  CHEZMOI=/opt/homebrew/bin/chezmoi
else
  tmp="$(mktemp -d)"
  info "下載暫用的 chezmoi"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$tmp"
  CHEZMOI="$tmp/chezmoi"
fi

# source 指向這個 repo；已存在的設定檔 chezmoi 會先問過才覆蓋（可選 diff）
"$CHEZMOI" init --source "$DOTFILES"
"$CHEZMOI" apply "$@"
info "完成，重開 terminal 生效"
