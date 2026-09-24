# dotfiles

macOS 開發環境設定。

## 新機器

```sh
git clone https://github.com/rudd6617/dotfiles.git ~/Documents/dotfiles
cd ~/Documents/dotfiles && ./install.sh
```

會依序完成：Xcode CLT → Homebrew → 建立 symlink（原檔案備份到 `~/.dotfiles-backup/`）→ `brew bundle` → uv / Claude Code / bun → `mise install` → npm 全域套件。

## 日常

- 設定都是 symlink，直接改就好，改完在這裡 commit
- 新增 brew 套件後：`brew bundle dump --file=Brewfile --no-vscode --force`（記得把手動調整的部分留下來）
- 只重建 symlink：`./install.sh link`

## 未納入（需手動處理）

- `~/.config/gh`：含 token，用 `gh auth login`
- `~/.config/zed/settings.json`：含 SSH 主機資訊，repo 是 public
- `~/.claude/settings.json`：含專案相關設定
- App Store、非 brew 安裝的 App（見 Brewfile 底部註解）
