# 日常操作；make help 看全部
.DEFAULT_GOAL := help
SHELL := /bin/bash
.PHONY: help install apply diff status re-add update upgrade brew-dump cleanup check

help: ## 列出指令
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: ## 新機器一鍵建置（同 ./install.sh）
	./install.sh

apply: ## repo → 家目錄（Brewfile/mise 有變會自動重跑安裝腳本）
	chezmoi apply

diff: ## 看 apply 會改什麼
	chezmoi diff

status: ## 列出家目錄與 repo 不一致的檔案
	chezmoi status

re-add: ## 家目錄 → repo（直接改了家目錄的設定檔後用）
	chezmoi re-add

update: ## git pull 後 apply
	git pull --rebase
	chezmoi apply

upgrade: ## 升級 brew 與 mise 的套件
	brew update && brew upgrade
	mise upgrade

brew-dump: ## 把目前 brew 裝的東西寫回 Brewfile（記得留下手動調整）
	brew bundle dump --global --no-vscode --force
	chezmoi re-add ~/.Brewfile
	git diff -- home/dot_Brewfile

cleanup: ## 列出不在 Brewfile 的 brew 套件；FORCE=1 才真的移除
	brew bundle cleanup --global $(if $(FORCE),--force,|| true)

check: ## 檢查所有 chezmoi 腳本的語法
	@for f in home/.chezmoiscripts/* install.sh; do \
	  chezmoi execute-template < "$$f" | bash -n && echo "ok  $$f" || exit 1; \
	done
