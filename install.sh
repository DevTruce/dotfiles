#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─────────────────────────────────────────
# Bootstrap
# ─────────────────────────────────────────

# -- Load all setup functions
for f in "${DOTFILES_DIR}/scripts/"*.sh; do
    # shellcheck source=/dev/null
    . "$f"
done

# -- Detect OS
OS="$(detect_os)"

echo ""
echo "  ════════════════════════════════════════════════════"
echo "  dotfiles installer"
printf "  OS: %s\n" "${OS}"
echo "  ════════════════════════════════════════════════════"

# ─────────────────────────────────────────
# OS Orchestrators
# ─────────────────────────────────────────

setup_macos() {
    echo ""
    echo "  Starting macOS setup..."
    setup_homebrew
    setup_dotfiles
    setup_zsh
    setup_git
    setup_git_lfs
    setup_ssh_key
    setup_gpg_key
    setup_gpg_agent_conf
    setup_zsh_plugins
    setup_nvm
    setup_tree
    check_vscode_cli
    finish
}

setup_linux() {
    echo ""
    echo "  Starting Linux setup..."
    setup_apt
    setup_dotfiles
    setup_zsh
    setup_git
    setup_git_lfs
    setup_ssh_key
    setup_gpg_key
    setup_gpg_agent_conf
    setup_keychain
    setup_zsh_plugins
    setup_nvm
    setup_tree
    check_vscode_cli
    finish
}

# ─────────────────────────────────────────
# Dispatch
# ─────────────────────────────────────────

if [ "$OS" = "macos" ]; then
    setup_macos
elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    setup_linux
else
    echo ""
    echo "  Unsupported OS: ${OS}"
    echo "  This installer only supports macOS, Ubuntu, and Debian."
    echo "  Please install dependencies manually."
    echo ""
    exit 1
fi
