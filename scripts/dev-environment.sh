setup_zsh_plugins() {
    section "Dev Environment — Zsh Plugins (zinit)"

    ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"

    if [ -d "$ZINIT_HOME" ]; then
        echo "  zinit is already installed."
    else
        echo "  Installing zinit plugin manager..."
        mkdir -p "$(dirname "$ZINIT_HOME")"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
        echo "  zinit installed. Plugins will be downloaded on first shell launch."
    fi

    echo "  Ensuring zsh completions directory exists..."
    mkdir -p "${HOME}/.zsh/completions"

    if command -v docker >/dev/null 2>&1; then
        echo "  Generating Docker zsh completion..."
        docker completion zsh > "${HOME}/.zsh/completions/_docker"
        echo "  Docker completion written."
    else
        echo "  Docker not found — skipping Docker completion."
        echo "  Re-run this script once Docker is installed to generate it."
    fi
}

setup_nvm() {
    section "Dev Environment — Node.js (nvm)"

    NVM_DIR="${HOME}/.nvm"

    if [ -s "${NVM_DIR}/nvm.sh" ]; then
        echo "  nvm is already installed."
    else
        echo "  Installing nvm (Node Version Manager)..."
        echo "  The .zshrc loader is already in your dotfiles — skipping shell profile edits."
        # PROFILE=/dev/null stops nvm's installer from editing .zshrc itself,
        # since the loader lines are already maintained by dotfiles.
        PROFILE=/dev/null bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh)"
        echo "  nvm installed."
    fi

    # nvm.sh and several nvm subcommands reference internal variables that
    # aren't always set, which trips `set -u`. Relax it for this block only.
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
