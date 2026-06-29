# ─────────────────────────────────────────
# Dotfiles
# ─────────────────────────────────────────

setup_dotfiles() {
    section "Dotfiles — Symlinking"

    step "Symlinking dotfiles into home directory..."
    note "Existing regular files at these paths will be replaced by symlinks."
    echo ""

    # -- Common
    ln -sf "${DOTFILES_DIR}/Common/.zshrc"                 "${HOME}/.zshrc"
    link "~/.zshrc" "${DOTFILES_DIR}/Common/.zshrc"

    ln -sf "${DOTFILES_DIR}/Common/.gitconfig"             "${HOME}/.gitconfig"
    link "~/.gitconfig" "${DOTFILES_DIR}/Common/.gitconfig"

    ln -sf "${DOTFILES_DIR}/Common/.p10k.zsh"              "${HOME}/.p10k.zsh"
    link "~/.p10k.zsh" "${DOTFILES_DIR}/Common/.p10k.zsh"

    if [ "${PERSONAL_MACHINE:-n}" = "y" ]; then
        mkdir -p "${HOME}/.claude"
        ln -sf "${DOTFILES_DIR}/Common/claude/settings.json"   "${HOME}/.claude/settings.json"
        link "~/.claude/settings.json" "${DOTFILES_DIR}/Common/claude/settings.json"
    fi

    echo ""
    ok "All dotfiles symlinked."
    # gpg-agent.conf is generated dynamically by setup_gpg_agent_conf — not symlinked
}
