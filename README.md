# dotfiles

macOS 開發環境設定。

## 新機器

```sh
git clone https://github.com/rudd6617/dotfiles.git ~/Documents/dotfiles
cd ~/Documents/dotfiles && ./install.sh
```

`install.sh` 會確認 Xcode CLT、抓暫用的 [chezmoi](https://chezmoi.io)，再 `chezmoi init --source <repo> && chezmoi apply`。apply 依序跑 `home/.chezmoiscripts/`：Homebrew → 寫入設定檔（已存在的會先問）→ `brew bundle --global` + 註冊 Nerd Fonts → `mise install` → Claude Code + mods。

## 結構

- `home/` 對應家目錄（`.chezmoiroot`），檔名規則見 [chezmoi 文件](https://chezmoi.io/reference/source-state-attributes/)：`dot_zshrc` → `~/.zshrc`
- **Homebrew**（`home/dot_Brewfile` → `~/.Brewfile`）：cask、字型、mise 裝不了的東西
- **mise**（`home/dot_config/mise/config.toml`）：node/python 與 CLI 工具（rg、fd、fzf、gh、jq、starship、zoxide、uv、bun、pnpm）
- Claude Code 用官方安裝程式（會自動更新）；mods 在 `claude/mods/`，不會複製到家目錄

## 日常

`make help` 列出所有指令：

| 指令 | 做什麼 |
|---|---|
| `make diff` / `make apply` | 看差異 / repo → 家目錄 |
| `make status` | 家目錄和 repo 不一致的檔案 |
| `make re-add` | 直接改了家目錄的設定檔後，寫回 repo |
| `make update` | `git pull` 後 apply |
| `make upgrade` | 升級 brew 與 mise 的套件 |
| `make brew-dump` | 目前 brew 裝的東西寫回 Brewfile（記得留下手動調整） |
| `make cleanup` | 列出不在 Brewfile 的 brew 套件，`make cleanup FORCE=1` 才移除 |
| `make check` | 檢查所有安裝腳本的語法 |

- 設定檔是**複製**不是 symlink：用 `chezmoi edit --apply ~/.zshrc`，或改完家目錄再 `make re-add`，然後在 repo commit
- 新增 CLI 工具：`mise use -g <tool>` 後 `make re-add`
- Brewfile / mise 設定變動時，`make apply` 會自動重跑對應的安裝腳本
- 新增 Claude Code mod：在 `claude/mods/.claude-plugin/marketplace.json` 登記，並在 `home/.chezmoiscripts/run_onchange_after_40-claude.sh.tmpl` 加一行 `claude plugin install <mod>@dotfiles`；改既有 mod 直接改，`/reload-plugins` 生效

## 未納入（需手動處理）

- `~/.config/gh`：含 token，用 `gh auth login`
- `~/.config/zed/settings.json`：含 SSH 主機資訊，repo 是 public
- `~/.claude/settings.json`：含專案相關設定
- `~/.codex/config.toml`：含專案路徑與信任設定，repo 是 public
- App Store、非 brew 安裝的 App（見 Brewfile 底部註解）
