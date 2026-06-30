#!/usr/bin/env bash
set -euo pipefail

_on_exit() {
    local _rc=$?
    if [ "$_rc" -ne 0 ]; then
        echo ""
        fail "Setup aborted — resolve the error above and re-run."
        echo ""
    fi
}
trap '_on_exit' EXIT

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="${HOME}/.local/bin:${PATH}"

# ─────────────────────────────────────────
# Bootstrap
# ─────────────────────────────────────────

# -- Load all setup functions (alphabetical order: helpers.sh loads 4th after
#    dev-environment.sh, dotfiles.sh, finish.sh — those files must not execute
#    any top-level code that references helpers or color variables)
for f in "${DOTFILES_DIR}/scripts/"*.sh; do
    # shellcheck source=/dev/null
    . "$f"
done

# -- Detect OS
OS="$(detect_os)"

echo ""
printf "  ${BOLD_CYAN}┌──────────────────────────────────────────────────────┐${RESET}\n"
printf "  ${BOLD_CYAN}│${RESET}  ${BOLD_WHITE}%-52s${RESET}${BOLD_CYAN}│${RESET}\n" "Dev Environment Setup"
printf "  ${BOLD_CYAN}│${RESET}  ${DIM}%-52s${RESET}${BOLD_CYAN}│${RESET}\n" "OS: ${OS}"
printf "  ${BOLD_CYAN}└──────────────────────────────────────────────────────┘${RESET}\n"
echo ""

# -- Personal machine prompt
printf "  ${CYAN}?${RESET}  Is this a personal machine? ${DIM}(y/N)${RESET}: "
read -r _reply
case "$_reply" in
    [Yy]) PERSONAL_MACHINE="y" ;;
    *)    PERSONAL_MACHINE="n" ;;
esac
echo ""

# ─────────────────────────────────────────
# OS Orchestrators
# ─────────────────────────────────────────

setup_core() {
    setup_zsh
    setup_git
    setup_git_lfs
    setup_zsh_plugins
    setup_nvm
    setup_pnpm
    setup_tree
    setup_fzf
    setup_zoxide
    setup_ripgrep
    setup_bat
    setup_lazygit
    setup_gh
    setup_dotfiles
}

setup_personal() {
    setup_gpg_tools
    setup_gpg_agent_conf
    setup_ssh_key
    setup_gpg_key
    setup_claude
}

setup_macos() {
    step "Starting macOS setup..."
    setup_homebrew
    setup_core
    if [ "$PERSONAL_MACHINE" = "y" ]; then
        setup_personal
    fi
    finish
}

setup_linux() {
    step "Starting Linux setup..."
    setup_apt
    setup_core
    if [ "$PERSONAL_MACHINE" = "y" ]; then
        setup_personal
    fi
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
    warn "Unsupported OS: ${OS}"
    note "This installer only supports macOS, Ubuntu, and Debian."
    note "Please install dependencies manually."
    echo ""
    exit 1
fi
