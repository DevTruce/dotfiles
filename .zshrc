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
# cache init output to avoid forking brew + re-evaluating its full shellenv every startup
if [[ "$OSTYPE" == darwin* ]]; then
  # Apple Silicon installs to /opt/homebrew, Intel to /usr/local - check both,
  # since scripts/package-managers.sh's setup_homebrew supports either
  if [[ -x /opt/homebrew/bin/brew ]]; then
    _brew_bin="/opt/homebrew/bin/brew"
  elif [[ -x /usr/local/bin/brew ]]; then
    _brew_bin="/usr/local/bin/brew"
  fi
  if [[ -n "${_brew_bin:-}" ]]; then
    _brew_cache="${XDG_CACHE_HOME:-$HOME/.cache}/brew-shellenv.zsh"
    if [[ ! -f "$_brew_cache" ]] || [[ "$_brew_bin" -nt "$_brew_cache" ]]; then
      mkdir -p "$(dirname "$_brew_cache")"
      "$_brew_bin" shellenv > "$_brew_cache" 2>/dev/null
    fi
    source "$_brew_cache"
  fi
  unset _brew_bin _brew_cache
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

  # -- Theme (loaded synchronously, before the turbo-mode plugins below: renders the
  #    prompt immediately via the instant-prompt cache at the top of this file, instead
  #    of showing an unstyled prompt for a flash on every new terminal)
  zinit ice depth=1
  zinit light romkatv/powerlevel10k

  # -- Plugins (turbo mode: `wait'0'` defers loading until zsh is idle right after the
  #    prompt has drawn; `lucid` suppresses zinit's load-time output so it doesn't
  #    clutter the prompt. Order still matters even deferred - completions before
  #    autosuggestions before syntax-highlighting, since each plugin wraps widgets the
  #    next one needs to already exist. zsh-autosuggestions needs an explicit `atload`
  #    to (re)run its own init under turbo mode - without it, suggestions silently
  #    never activate, since its normal auto-init only fires on synchronous plugin load)
  zinit ice wait'0' lucid
  zinit light zsh-users/zsh-completions

  zinit ice wait'0' lucid atload'_zsh_autosuggest_start'
  zinit light zsh-users/zsh-autosuggestions

  zinit ice wait'0' lucid
  zinit light zsh-users/zsh-syntax-highlighting

  zinit ice wait'0' lucid as"completion"
  zinit snippet "https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker"

  # -- Completions (dump missing/stale: full compinit with the docker-symlink-warning
  #    filter below; dump <24h old: compinit -C skips the security audit for a faster start)
  autoload -Uz compinit
  if [[ -n ${HOME}/.zcompdump(#qN.mh+24) ]]; then
    # Docker Desktop's WSL integration leaves a symlink at
    # /usr/share/zsh/vendor-completions/_docker pointing into a mount that
    # isn't always attached yet at shell startup; when dangling, compinit's
    # full-rebuild scan fails to read it and prints a harmless warning on
    # WSL/Linux - filter just that line, let everything else through.
    #
    # Captured to a temp file rather than `2> >(grep ...)` or `compinit |
    # grep`: process substitution spawns an async background reader zsh
    # doesn't wait for, which can get reaped after the prompt has already
    # drawn and cause zsh to redraw it (apparent duplicate prompt on new
    # terminals); a pipe forces compinit itself into a forked subshell,
    # discarding the completion definitions it's supposed to install into
    # this shell. Redirecting to a file keeps compinit unsubshelled while
    # still filtering synchronously - only runs on the rare stale-dump path.
    _compinit_err="$(mktemp)"
    compinit 2>"$_compinit_err"
    grep -v 'no such file or directory:.*vendor-completions/_docker$' "$_compinit_err" >&2
    rm -f "$_compinit_err"
    unset _compinit_err
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

# Plain constant, not XDG_CONFIG_HOME-aware: this repo never sets XDG_CONFIG_HOME
# itself, and scripts/helpers.sh hardcodes the same ~/.nvm for setup_nvm and
# doctor.sh (the two bash call sites, kept in agreement by sharing that one
# constant). This file keeps its own independent copy rather than sourcing
# helpers.sh, since .zshrc must stay self-contained even if this repo is later
# moved or deleted. If you ever make this XDG-aware, update scripts/helpers.sh's
# NVM_DIR to match, or nvm silently never loads for anyone who has
# XDG_CONFIG_HOME set in their own environment.
export NVM_DIR="${HOME}/.nvm"

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

export GPG_TTY=$TTY
if command -v gpgconf >/dev/null 2>&1; then
  # only redirect SSH auth to gpg-agent on machines where SSH support is configured
  if [[ -f "$HOME/.gnupg/gpg-agent.conf" ]] && grep -q "enable-ssh-support" "$HOME/.gnupg/gpg-agent.conf" 2>/dev/null; then
    # cache the socket path to avoid forking gpgconf every startup, same pattern as
    # brew/fzf/zoxide above - the path is derived from gnupg's homedir + version, not
    # live agent state, so it's stable until gpg-agent.conf itself changes (e.g. a
    # pinentry-path update from setup_gpg_agent_conf), which invalidates the cache
    _gpg_ssh_sock_cache="${XDG_CACHE_HOME:-$HOME/.cache}/gpg-ssh-socket.txt"
    if [[ ! -f "$_gpg_ssh_sock_cache" ]] || [[ "$HOME/.gnupg/gpg-agent.conf" -nt "$_gpg_ssh_sock_cache" ]]; then
      mkdir -p "$(dirname "$_gpg_ssh_sock_cache")"
      gpgconf --list-dirs agent-ssh-socket > "$_gpg_ssh_sock_cache" 2>/dev/null
    fi
    export SSH_AUTH_SOCK="$(<"$_gpg_ssh_sock_cache")"
    unset _gpg_ssh_sock_cache
  fi
  # backgrounded (&!): launching the agent, waiting for its socket, and registering
  # this terminal's TTY for pinentry are only needed before the first git/ssh command,
  # not before the prompt renders - doing this synchronously added up to ~1s plus
  # several subprocess spawns to every shell startup.
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
