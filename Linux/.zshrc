# 1. Copy .zshrc over 
# 2. Install nvm fresh 
# 3. exec zsh - zinit + plugins auto-install on first launch



# ---------------------
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# ---------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# ---------------------
# Zinit Package Manager
# ---------------------
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit


# ---------------------
# Plug-ins
# ---------------------
# Load essential Zsh community plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit snippet OMZP::docker/docker.plugin.zsh
zinit snippet OMZP::docker-compose/docker-compose.plugin.zsh

# Initialize the completion system
autoload -Uz compinit && compinit
zinit cdreplay -q

# Load theme
zinit ice depth=1
zinit light romkatv/powerlevel10k


# ---------------------
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# ---------------------
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# ---------------------
# NVM loader 
# ---------------------
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # loads nvm completions

# Auto-switch Node version when entering a project folder with an .nvmrc
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

# ---------------------
# Start/reuse ssh-agent and load key via keychain
# (WSL2 has no Keychain like macOS, so this does the same job —
# reuses one agent across all terminals instead of prompting every tab)
# ---------------------
eval "$(keychain --eval --quiet ~/.ssh/id_ed25519)"


# ---------------------
# Tell zsh which TTY this session is using, so GPG's pinentry can find it
# ---------------------
export GPG_TTY=$TTY


# ---------------------
# Docker Aliases 
# ---------------------
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcl="docker compose logs -f"
alias nrd="npm run dev"


# ---------------------
# Claude Code 
# ---------------------
export PATH="$HOME/.local/bin:$PATH"