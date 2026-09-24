# History
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Completions
fpath+=$(brew --prefix)/share/zsh-completions
autoload -Uz compinit && compinit

# Aliases
alias ll="ls -alF"
alias cc="claude --model 'claude-opus-4-6[1m]'"

# Starship prompt
eval "$(starship init zsh)"

. "$HOME/.local/bin/env"

# mise (dev tool version manager)
eval "$(mise activate zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Added by Spectra
if [[ -z ${path[(r)$HOME/.local/bin]} ]]; then
  path=("$HOME/.local/bin" $path)
fi
