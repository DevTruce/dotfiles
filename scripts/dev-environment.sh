# ─────────────────────────────────────────
# Dev Environment
# ─────────────────────────────────────────

# -- Zsh Plugins (zinit)

setup_zsh_plugins() {
    section "Dev Environment — Zsh Plugins (zinit)"

    local ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"

    if [ -d "$ZINIT_HOME" ]; then
        echo "  zinit is already installed."
    else
        echo "  Installing zinit plugin manager..."
        mkdir -p "$(dirname "$ZINIT_HOME")"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
        echo "  zinit installed. Plugins will be downloaded on first shell launch."
    fi
}

# -- Node.js (nvm)

setup_nvm() {
    section "Dev Environment — Node.js (nvm)"

    NVM_DIR="${HOME}/.nvm"

    if [ -s "${NVM_DIR}/nvm.sh" ]; then
        echo "  nvm is already installed."
    else
        echo "  Installing nvm (Node Version Manager)..."
        echo "  The .zshrc loader is already in your dotfiles — skipping shell profile edits."
        # PROFILE=/dev/null prevents nvm's installer from modifying .zshrc,
        # since the nvm loader is already maintained in dotfiles
        PROFILE=/dev/null bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh)"
        echo "  nvm installed."
    fi

    # nvm references unbound variables internally, which trips set -u
    set +u
    \. "${NVM_DIR}/nvm.sh"

    if nvm ls --no-colors 2>/dev/null | grep -q 'lts/\*'; then
        echo "  Node.js LTS is already installed."
    else
        echo "  Installing the latest Node.js LTS release..."
        nvm install --lts
        echo "  Node.js LTS installed."
    fi

    nvm alias default 'lts/*' >/dev/null
    echo "  Node.js LTS set as the default version."
    set -u
}

# -- Claude Code CLI

setup_claude() {
    section "Dev Environment — Claude Code CLI"

    if command -v claude >/dev/null 2>&1; then
        echo "  Claude Code is already installed."
    else
        echo "  Installing Claude Code CLI..."
        npm install -g @anthropic-ai/claude-code
        echo "  Claude Code installed."
    fi
}
