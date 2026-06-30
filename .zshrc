# ─────────────────────────────────────────
# Instant Prompt
# ─────────────────────────────────────────

# must stay near the top - nothing requiring console input above this block
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─────────────────────────────────────────
# Path
# ─────────────────────────────────────────

# -- prepend ~/.local/bin so user-installed binaries take precedence over system paths
export PATH="$HOME/.local/bin:$PATH"

# -- macOS: ensure Homebrew is in PATH (required on Apple Silicon without .zprofile)
if [[ "$OSTYPE" == darwin* ]] && [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ─────────────────────────────────────────
# History
# ─────────────────────────────────────────

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_REDUCE_BLANKS

# ─────────────────────────────────────────
# Plugin Manager (zinit)
# ─────────────────────────────────────────

ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"

if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone --depth 1 https://github.com/zdharma-continuum/zinit "$ZINIT_HOME" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

if [[ -f "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"
  autoload -Uz _zinit
  (( ${+_comps} )) && _comps[zinit]=_zinit

  # ─────────────────────────────────────────
  # Shell Setup
  # ─────────────────────────────────────────

  # -- Plugins (order matters: completions → autosuggestions → syntax-highlighting last)
  zinit light zsh-users/zsh-completions
  zinit light zsh-users/zsh-autosuggestions
  zinit light zsh-users/zsh-syntax-highlighting
  zinit ice as"completion"; zinit snippet "https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker"

  # -- Theme
  zinit ice depth=1
  zinit light romkatv/powerlevel10k

  # -- Completions (skip security audit when dump is less than 24 hours old)
  autoload -Uz compinit
  if [[ -n ${HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
  else
    compinit -C
  fi
  zinit cdreplay -q

  # -- Prompt (run `p10k configure` or edit ~/.p10k.zsh to customise)
  [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
fi

# -- fzf (CTRL-R, CTRL-T, ALT-C) - cache init output to avoid forking every startup
if command -v fzf >/dev/null 2>&1; then
  _fzf_cache="${XDG_CACHE_HOME:-$HOME/.cache}/fzf.zsh"
  if [[ ! -f "$_fzf_cache" ]] || [[ "$(command -v fzf)" -nt "$_fzf_cache" ]]; then
    mkdir -p "$(dirname "$_fzf_cache")"
    fzf --zsh > "$_fzf_cache" 2>/dev/null
  fi
  source "$_fzf_cache"
  unset _fzf_cache
fi

# -- zoxide (z, zi) - cache init output to avoid forking every startup
if command -v zoxide >/dev/null 2>&1; then
  _zoxide_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide.zsh"
  if [[ ! -f "$_zoxide_cache" ]] || [[ "$(command -v zoxide)" -nt "$_zoxide_cache" ]]; then
    mkdir -p "$(dirname "$_zoxide_cache")"
    zoxide init zsh > "$_zoxide_cache" 2>/dev/null
  fi
  source "$_zoxide_cache"
  unset _zoxide_cache
fi

# ─────────────────────────────────────────
# NVM
# ─────────────────────────────────────────

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"

# Fast path: resolve nvm's default alias chain and add the node bin dir to PATH
# so globally installed CLIs (claude, pnpm, etc.) are available without sourcing nvm
if [[ -f "$NVM_DIR/alias/default" ]]; then
  _nvm_ver="$(cat "$NVM_DIR/alias/default")"
  # resolve up to 2 levels of alias indirection (default → lts/* → lts/iron → version)
  [[ -f "$NVM_DIR/alias/$_nvm_ver" ]] && _nvm_ver="$(cat "$NVM_DIR/alias/$_nvm_ver")"
  [[ -f "$NVM_DIR/alias/$_nvm_ver" ]] && _nvm_ver="$(cat "$NVM_DIR/alias/$_nvm_ver")"
  [[ "$_nvm_ver" != v* ]] && _nvm_ver="v${_nvm_ver}"
  _nvm_bin="$NVM_DIR/versions/node/${_nvm_ver}/bin"
  [[ -d "$_nvm_bin" ]] && export PATH="$_nvm_bin:$PATH"
  unset _nvm_ver _nvm_bin
fi

# Lazy-load full nvm on first use - avoids 100-500 ms startup cost from sourcing nvm.sh
_load_nvm() {
  unset -f nvm node npm npx pnpm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}
nvm()  { _load_nvm; nvm  "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm  "$@"; }
npx()  { _load_nvm; npx  "$@"; }
pnpm() { _load_nvm; pnpm "$@"; }

# Auto-switch Node version when entering a project with an .nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
  # if nvm isn't loaded yet, only trigger a load if there's a local .nvmrc
  if ! command -v nvm_find_nvmrc >/dev/null 2>&1; then
    [[ -f .nvmrc ]] && _load_nvm || return 0
  fi
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
  export GPG_TTY=$TTY
  if command -v gpgconf >/dev/null 2>&1; then
    # only redirect SSH auth to gpg-agent on machines where SSH support is configured
    if [[ -f "$HOME/.gnupg/gpg-agent.conf" ]] && grep -q "enable-ssh-support" "$HOME/.gnupg/gpg-agent.conf" 2>/dev/null; then
      export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    fi
    # backgrounded (&!): launching the agent, waiting for its socket, and registering
    # this terminal's TTY for pinentry are only needed before the first git/ssh command,
    # not before the prompt renders - doing this synchronously added up to ~1s plus
    # several subprocess spawns to every shell startup. SSH_AUTH_SOCK above stays
    # synchronous since it's just a path computation, not a live agent round-trip, and
    # other commands may read it immediately.
    (
      gpgconf --launch gpg-agent 2>/dev/null
      _gpg_sock="$(gpgconf --list-dirs agent-socket 2>/dev/null)"
      _gpg_retries=0
      until [[ -S "$_gpg_sock" ]] || (( _gpg_retries++ >= 10 )); do
        sleep 0.1
      done
      gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
    ) &!
  fi
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
