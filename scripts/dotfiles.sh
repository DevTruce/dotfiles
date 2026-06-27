# ─────────────────────────────────────────
# Dotfiles
# ─────────────────────────────────────────

setup_dotfiles() {
    section "Dotfiles — Symlinking"

    local os_dir
    case "$OS" in
        macos) os_dir="MacOS" ;;
        *)     os_dir="Linux" ;;
    esac

    echo "  Symlinking dotfiles into home directory..."
    echo "  Note: any existing regular files at these paths will be replaced by symlinks."
    echo ""

    # -- OS-specific
    ln -sf "${DOTFILES_DIR}/${os_dir}/.zshrc"              "${HOME}/.zshrc"
    echo "  ~/.zshrc           → ${DOTFILES_DIR}/${os_dir}/.zshrc"

    # -- Common
    ln -sf "${DOTFILES_DIR}/Common/.gitconfig"             "${HOME}/.gitconfig"
    echo "  ~/.gitconfig       → ${DOTFILES_DIR}/Common/.gitconfig"

    ln -sf "${DOTFILES_DIR}/Common/.p10k.zsh"              "${HOME}/.p10k.zsh"
    echo "  ~/.p10k.zsh        → ${DOTFILES_DIR}/Common/.p10k.zsh"

    mkdir -p "${HOME}/.claude"
    ln -sf "${DOTFILES_DIR}/Common/claude/settings.json"   "${HOME}/.claude/settings.json"
    echo "  ~/.claude/settings.json → ${DOTFILES_DIR}/Common/claude/settings.json"

    echo ""
    echo "  All dotfiles symlinked."
    # gpg-agent.conf is generated dynamically by setup_gpg_agent_conf — not symlinked
}
