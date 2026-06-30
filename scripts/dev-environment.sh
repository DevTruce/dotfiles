# ─────────────────────────────────────────
# Dev Environment
# ─────────────────────────────────────────

# -- Zsh Plugins (zinit)

setup_zsh_plugins() {
    section "Dev Environment - Zsh Plugins (zinit)"

    local ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"

    if [ -d "$ZINIT_HOME" ]; then
        skip "zinit is already installed."
    else
        step "Installing zinit plugin manager"
        mkdir -p "$(dirname "$ZINIT_HOME")"
        local _log _pid
        _log="$(mktemp)"
        git clone --depth 1 --quiet https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" > "$_log" 2>&1 &
        _pid=$!
        _spinner "$_pid"
        if wait "$_pid"; then rm -f "$_log"
        else fail "${_LAST_STEP} failed."; echo ""; cat "$_log"; rm -f "$_log"; return 1; fi
        ok "zinit installed."
        note "Plugins will be downloaded on first shell launch."
    fi
}

# -- Node.js (nvm)

setup_nvm() {
    section "Dev Environment - Node.js (nvm)"

    NVM_DIR="${HOME}/.nvm"

    if [ -s "${NVM_DIR}/nvm.sh" ]; then
        skip "nvm is already installed."
    else
        note "Skipping shell profile changes - your .zshrc already includes the nvm loader."
        step "Installing nvm (Node Version Manager)"
        # PROFILE=/dev/null prevents nvm's installer from modifying .zshrc,
        # since the nvm loader is already maintained in dotfiles
        local _nvm_log _nvm_pid
        _nvm_log="$(mktemp)"
        (curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh" | PROFILE=/dev/null bash) > "$_nvm_log" 2>&1 &
        _nvm_pid=$!
        _spinner "$_nvm_pid"
        if wait "$_nvm_pid"; then
            rm -f "$_nvm_log"
        else
            fail "${_LAST_STEP} failed."
            echo ""
            cat "$_nvm_log"
            rm -f "$_nvm_log"
            return 1
        fi
        ok "nvm installed."
    fi

    # nvm references unbound variables internally, which trips set -u
    set +u
    \. "${NVM_DIR}/nvm.sh"
    set -u

    local _node_already_installed=false
    if nvm ls --no-colors 2>/dev/null | grep -q 'lts/\*'; then
        skip "Node.js LTS is already installed."
        _node_already_installed=true
    else
        step "Installing the latest Node.js LTS release"
        local _node_log _node_pid
        _node_log="$(mktemp)"
        set +u
        (nvm install --lts) > "$_node_log" 2>&1 &
        _node_pid=$!
        _spinner "$_node_pid"
        if wait "$_node_pid"; then
            rm -f "$_node_log"
        else
            fail "${_LAST_STEP} failed."
            echo ""
            cat "$_node_log"
            rm -f "$_node_log"
            set -u
            return 1
        fi
        if ! nvm use lts/* >/dev/null 2>&1; then
            fail "Failed to activate Node.js LTS after install."
            set -u
            return 1
        fi
        set -u
        local _node_ver _npm_ver
        _node_ver="$(node --version 2>/dev/null || echo "unknown")"
        _npm_ver="$(npm --version 2>/dev/null || echo "unknown")"
        ok "Node.js LTS installed."
        note "Node ${_node_ver}  ·  npm ${_npm_ver}"

        set +u
        nvm alias default 'lts/*' >/dev/null
        set -u
        ok "Default alias set to lts/*."
    fi
}

# -- pnpm

setup_pnpm() {
    section "Dev Environment - pnpm"

    set +u
    [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ] && \. "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
    set -u

    if command -v pnpm >/dev/null 2>&1; then
        skip "pnpm is already installed."
    else
        step "Installing pnpm"
        _npm install -g pnpm
        ok "pnpm installed."
    fi
}

# -- Claude Code CLI

setup_claude() {
    section "Dev Environment - Claude Code CLI"

    set +u
    [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ] && \. "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
    set -u

    if command -v claude >/dev/null 2>&1; then
        skip "Claude Code is already installed."
    else
        step "Installing Claude Code CLI"
        _npm install -g @anthropic-ai/claude-code
        ok "Claude Code installed."
    fi
}
