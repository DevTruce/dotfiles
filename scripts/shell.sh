# ─────────────────────────────────────────
# Shell
# ─────────────────────────────────────────

# -- zsh

setup_zsh() {
    section "Shell — zsh"

    local ZSH_PATH

    case "$OS" in
        macos)
            if brew list zsh >/dev/null 2>&1; then
                skip "zsh is already installed via Homebrew."
            else
                step "Installing zsh via Homebrew..."
                brew install zsh
                ok "zsh installed."
            fi

            ZSH_PATH="$(brew --prefix zsh)/bin/zsh"

            # register Homebrew zsh as a valid login shell
            if ! grep -qxF "$ZSH_PATH" /etc/shells; then
                step "Registering ${ZSH_PATH} in /etc/shells..."
                echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
                ok "zsh registered in /etc/shells."
            fi
            ;;
        *)
            if command -v zsh >/dev/null 2>&1; then
                skip "zsh is already installed."
            else
                step "Installing zsh..."
                sudo apt-get install zsh -y
                ok "zsh installed."
            fi

            ZSH_PATH="$(command -v zsh)"
            ;;
    esac

    if [ "$SHELL" = "$ZSH_PATH" ]; then
        skip "zsh is already the default shell."
    else
        step "Setting zsh as the default shell..."
        chsh -s "$ZSH_PATH"
        ok "Default shell updated — open a new terminal for this to take effect."
    fi
}
