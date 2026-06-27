setup_zsh() {
    section "Shell — zsh"

    case "$OS" in
        macos)
            if brew list zsh >/dev/null 2>&1; then
                echo "  zsh is already installed via Homebrew."
            else
                echo "  Installing zsh via Homebrew..."
                brew install zsh
            fi

            ZSH_PATH="$(brew --prefix zsh)/bin/zsh"

            if ! grep -qxF "$ZSH_PATH" /etc/shells; then
                echo "  Registering ${ZSH_PATH} in /etc/shells..."
                echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
            fi
            ;;
        *)
            if command -v zsh >/dev/null 2>&1; then
                echo "  zsh is already installed."
            else
                echo "  Installing zsh..."
                sudo apt install zsh -y
            fi

            ZSH_PATH="$(command -v zsh)"
            ;;
    esac

    if [ "$SHELL" = "$ZSH_PATH" ]; then
        echo "  zsh is already the default shell."
    else
        echo "  Setting zsh as the default shell..."
        chsh -s "$ZSH_PATH"
        echo "  Default shell updated — open a new terminal for this to take effect."
    fi
}
