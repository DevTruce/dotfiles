# ─────────────────────────────────────────
# Instant Prompt
# ─────────────────────────────────────────

# must stay near the top — nothing requiring console input above this block
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─────────────────────────────────────────
# Path
# ─────────────────────────────────────────

# -- prepend ~/.local/bin so user-installed binaries take precedence over system paths
export PATH="$HOME/.local/bin:$PATH"

# ─────────────────────────────────────────
# Plugin Manager (zinit)
# ─────────────────────────────────────────

if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone --depth 1 https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# ─────────────────────────────────────────
# Shell Setup
# ─────────────────────────────────────────

# -- Community
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit ice as"completion"; zinit snippet "https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker"

# -- Theme
zinit ice depth=1
zinit light romkatv/powerlevel10k

# -- Completions
autoload -Uz compinit && compinit
zinit cdreplay -q

# -- Prompt
# run `p10k configure` or edit ~/.p10k.zsh to customise
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# -- fzf (CTRL-R, CTRL-T, ALT-C)
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

# -- zoxide (z, zi)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# ─────────────────────────────────────────
# NVM
# ─────────────────────────────────────────

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# -- Auto-switch Node version when entering a project with an .nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [[ -n "$nvmrc_path" ]]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [[ "$nvmrc_node_version" = "N/A" ]]; then
      nvm install
    elif [[ "$nvmrc_node_version" != "$(nvm version)" ]]; then
      nvm use --silent
    fi
  elif [[ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ]] && [[ "$(nvm version)" != "$(nvm version default)" ]]; then
    echo "Reverting to nvm default version"
    nvm use default --silent
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# ─────────────────────────────────────────
# GPG Agent
# ─────────────────────────────────────────

if [[ "$OSTYPE" != "darwin"* ]]; then
  # -- SSH + GPG passphrase caching on Linux
  if command -v gpgconf >/dev/null 2>&1; then
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    gpgconf --launch gpg-agent 2>/dev/null
    # push the current terminal into the running daemon so pinentry-curses can find it
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
  fi
  export GPG_TTY=$TTY
fi

# ─────────────────────────────────────────
# Aliases
# ─────────────────────────────────────────

# -- Docker
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcl="docker compose logs -f"

# -- npm
alias nrd="npm run dev"

# -- bat
if [[ "$OSTYPE" == "darwin"* ]]; then
  command -v bat >/dev/null 2>&1 && alias cat="bat"
else
  if command -v batcat >/dev/null 2>&1; then
    alias bat="batcat"
    alias cat="batcat"
  fi
fi
