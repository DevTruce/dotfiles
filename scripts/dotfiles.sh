# ─────────────────────────────────────────
# Dotfiles
# ─────────────────────────────────────────

setup_dotfiles() {
    section "Dotfiles — Symlinking"

    step "Symlinking dotfiles into home directory..."
    note "Existing regular files at these paths will be replaced by symlinks."
    echo ""

    ln -sf "${DOTFILES_DIR}/.zshrc"                 "${HOME}/.zshrc"
    link "~/.zshrc" "${DOTFILES_DIR}/.zshrc"

    ln -sf "${DOTFILES_DIR}/.gitconfig"             "${HOME}/.gitconfig"
    link "~/.gitconfig" "${DOTFILES_DIR}/.gitconfig"

    ln -sf "${DOTFILES_DIR}/.p10k.zsh"              "${HOME}/.p10k.zsh"
    link "~/.p10k.zsh" "${DOTFILES_DIR}/.p10k.zsh"

    if [ "${PERSONAL_MACHINE:-n}" = "y" ]; then
        mkdir -p "${HOME}/.claude"
        ln -sf "${DOTFILES_DIR}/claude/settings.json"   "${HOME}/.claude/settings.json"
        link "~/.claude/settings.json" "${DOTFILES_DIR}/claude/settings.json"
    fi

    echo ""
    ok "All dotfiles symlinked."
    # gpg-agent.conf is generated dynamically by setup_gpg_agent_conf — not symlinked
}
