# ─────────────────────────────────────────
# Dev Environment
# ─────────────────────────────────────────

# -- Zsh Plugins (zinit)

setup_zsh_plugins() {
    section "Dev Environment — Zsh Plugins (zinit)"

    local ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"

    if [ -d "$ZINIT_HOME" ]; then
        skip "zinit is already installed."
    else
        step "Installing zinit plugin manager..."
        mkdir -p "$(dirname "$ZINIT_HOME")"
        git clone --depth 1 --quiet https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
        echo ""
        ok "zinit installed."
        note "Plugins will be downloaded on first shell launch."
    fi
}

# -- Node.js (nvm)

setup_nvm() {
    section "Dev Environment — Node.js (nvm)"

    NVM_DIR="${HOME}/.nvm"

    if [ -s "${NVM_DIR}/nvm.sh" ]; then
        skip "nvm is already installed."
    else
        step "Installing nvm (Node Version Manager)..."
        note "Skipping shell profile changes — your .zshrc already includes the nvm loader."
        # PROFILE=/dev/null prevents nvm's installer from modifying .zshrc,
        # since the nvm loader is already maintained in dotfiles
        local _nvm_log
        _nvm_log="$(mktemp)"
        if curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh" | PROFILE=/dev/null bash > "$_nvm_log" 2>&1; then
            rm -f "$_nvm_log"
        else
            cat "$_nvm_log"
            rm -f "$_nvm_log"
            return 1
        fi
        echo ""
        ok "nvm installed."
    fi

    # nvm references unbound variables internally, which trips set -u
    set +u
    \. "${NVM_DIR}/nvm.sh"

    if nvm ls --no-colors 2>/dev/null | grep -q 'lts/\*'; then
        skip "Node.js LTS is already installed."
    else
        step "Installing the latest Node.js LTS release..."
        nvm install --lts
        ok "Node.js LTS installed."
    fi

    nvm alias default 'lts/*' >/dev/null
    ok "Node.js LTS set as the default version."
    set -u
}

# -- pnpm

setup_pnpm() {
    section "Dev Environment — pnpm"

    set +u
    [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ] && \. "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
    set -u

    if command -v pnpm >/dev/null 2>&1; then
        skip "pnpm is already installed."
    else
        step "Installing pnpm..."
        npm install -g pnpm
        ok "pnpm installed."
    fi
}

# -- Claude Code CLI

setup_claude() {
    section "Dev Environment — Claude Code CLI"

    set +u
    [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ] && \. "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
    set -u

    if command -v claude >/dev/null 2>&1; then
        skip "Claude Code is already installed."
    else
        step "Installing Claude Code CLI..."
        npm install -g @anthropic-ai/claude-code
        echo ""
        ok "Claude Code installed."
    fi
}
