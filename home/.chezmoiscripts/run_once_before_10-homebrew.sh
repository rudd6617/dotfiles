#!/usr/bin/env bash
# 第一次 apply 前：Xcode CLT → Homebrew
set -euo pipefail
info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

if ! xcode-select -p >/dev/null 2>&1; then
  info "安裝 Xcode Command Line Tools（裝完再跑一次 chezmoi apply）"
  xcode-select --install
  exit 1
fi
if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
  info "安裝 Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
# share 若群組可寫，compinit 會一直跳 insecure directories 提示
chmod go-w "$(brew --prefix)/share"
