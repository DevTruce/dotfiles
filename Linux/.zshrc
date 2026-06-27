# 1. Copy .zshrc over 
# 2. Install nvm fresh 
# 3. exec zsh - zinit + plugins auto-install on first launch
# 4. Regenerate docker completions:
# mkdir -p ~/.zsh/completions
# docker completion zsh > ~/.zsh/completions/_docker


# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# ---------------------
# Add custom completions folder, then initialize zsh's tab-completion system
# ---------------------
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit


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

# Initialize the completion system
autoload -Uz compinit && compinit
zinit cdreplay -q

# Load theme
source ~/powerlevel10k/powerlevel10k.zsh-theme 


# ---------------------
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# ---------------------
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# ---------------------
# NVM loader 
# ---------------------
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 


# ---------------------
# Load SSH key into a persistent agent
# ---------------------
eval "$(keychain --eval --quiet id_ed25519)"


# ---------------------
# Tell zsh which TTY this session is using, so GPG's pinentry can find it
# ---------------------
export GPG_TTY=$TTY