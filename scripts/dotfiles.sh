# ─────────────────────────────────────────
# Dotfiles
# ─────────────────────────────────────────

setup_dotfiles() {
    section "Dotfiles - Symlinking"

    _symlink() {
        local src="$1" dest="$2" label="$3"
        if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
            skip "$(printf '%-24s already linked' "$label")"
        else
            # back up any existing regular file so we don't silently destroy it
            if [ -e "$dest" ] && [ ! -L "$dest" ]; then
                warn "${label} already exists as a regular file - backing up to ${dest}.bak"
                mv "$dest" "${dest}.bak"
            fi
            ln -sf "$src" "$dest"
            link "$label" "$src"
        fi
    }

    _symlink "${DOTFILES_DIR}/.zshenv"             "${HOME}/.zshenv"             "~/.zshenv"
    _symlink "${DOTFILES_DIR}/.zshrc"              "${HOME}/.zshrc"              "~/.zshrc"
    _symlink "${DOTFILES_DIR}/.gitconfig"          "${HOME}/.gitconfig"          "~/.gitconfig"
    _symlink "${DOTFILES_DIR}/.p10k.zsh"           "${HOME}/.p10k.zsh"           "~/.p10k.zsh"

    if [ "${PERSONAL_MACHINE:-n}" = "y" ]; then
        mkdir -p "${HOME}/.claude"
        _symlink "${DOTFILES_DIR}/claude/settings.json" "${HOME}/.claude/settings.json" "~/.claude/settings.json"
    fi

    echo ""
    ok "Dotfiles check complete."
    # gpg-agent.conf is generated dynamically by setup_gpg_agent_conf - not symlinked
}
